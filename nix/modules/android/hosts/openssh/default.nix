# OpenSSH server for robotnix, ported from the MagiskSSH module
# (https://gitlab.com/d4rcm4rc/MagiskSSH).
#
# Rather than shipping the Magisk module's prebuilt, dynamically-linked arm64
# binaries + a bundled libcrypto.so + an LD_LIBRARY_PATH wrapper, we build
# OpenSSH from source with Nix as a *fully static* aarch64 executable (musl
# libc, static OpenSSL + zlib). A static binary has no PT_INTERP and no shared
# library dependencies, so:
#
#   * it runs on Android directly, with no bundled libcrypto and no risk of
#     shadowing the system BoringSSL,
#   * there is no LD_LIBRARY_PATH wrapper to maintain, and
#   * none of the bionic/NDK header incompatibilities that plague a dynamic
#     Android build apply.
#
# The program tree is installed read-only under /system/opt/openssh; mutable
# runtime state (host keys, per-user authorized_keys, pid) lives under
# /data/ssh, exactly like the Magisk module. Host keys are generated on first
# boot by ssh_start, the init.rc equivalent of the module's opensshd.init.
#
# This file generates Android.mk at build time from the `prebuilts` list below,
# so all install layout (paths, classes, permissions) is co-located here. The
# staged dir is handed to robotnix via source.dirs, the same mechanism
# robotnix's own etc.nix uses.
#
# SELinux: GrapheneOS/AOSP runs in enforcing mode, so we ship a sepolicy domain
# for the daemon (sepolicy/sshd.te + sepolicy/file_contexts), installed by
# patching system/sepolicy below. This is the enforcing-mode equivalent of the
# unconstrained domain Magisk would run sshd in. The policy follows AOSP
# conventions; GrapheneOS hardens the base further, so the allow set may need
# tightening when validated on a real device build. The server listens on a high
# port (8022) so it never needs privileges to bind a port below 1024.
{
  ...
} @args:

let
  inherit (args.config) flake;

  # The Robotnix module that stages OpenSSH into the device image.
  opensshModule =
    {
      pkgs,
      lib,
      config,
      ...
    }:

    let
      prefix = "/system/opt/openssh";

      # Static aarch64 (musl) cross toolchain + static OpenSSL/zlib. musl is
      # free, so unlike the Android NDK path this needs no unfree licensing.
      muslStatic = pkgs.pkgsCross.aarch64-multiplatform-musl.pkgsStatic;

      opensshAndroid = muslStatic.stdenv.mkDerivation {
        pname = "openssh-android-static";
        inherit (muslStatic.openssh) version src;

        nativeBuildInputs = [
          pkgs.autoreconfHook
          pkgs.pkg-config
        ];
        buildInputs = [
          muslStatic.openssl
          muslStatic.zlib
        ];

        # Configure for the on-device prefix so the daemon's compiled-in paths
        # (sshd-session, sshd-auth, the privilege-separation dir) resolve at
        # runtime on Android. OpenSSH >= 9.8 re-execs sshd-session per
        # connection from $libexecdir, so this must be a real device path.
        configureFlags = [
          "--prefix=${prefix}"
          "--sysconfdir=${prefix}/etc"
          "--with-privsep-user=root"
          "--with-privsep-path=${prefix}/var/empty"
          "--with-pid-dir=/data/ssh"
          "--without-pam"
          "--disable-libedit"
          "--disable-security-key"
          "--disable-strip"
        ];

        # Force a fully static link.
        LDFLAGS = "-static";
        LIBS = "-lpthread";

        # Install only the binaries the server needs, straight from the build
        # dir. We avoid `make install` because it sets the setuid bit on
        # ssh-keysign (host-based auth, which we do not use) and the Nix sandbox
        # forbids setuid.
        installPhase = ''
          runHook preInstall
          base="$out${prefix}"
          mkdir -p "$base/sbin" "$base/bin" "$base/libexec"
          cp sshd "$base/sbin/"
          for b in ssh scp ssh-keygen ssh-keyscan; do
            cp "$b" "$base/bin/"
          done
          for b in sshd-session sshd-auth; do
            cp "$b" "$base/libexec/"
          done
          # These live outside the default strip paths ($out/bin, $out/sbin,
          # ...), so strip them here to drop debug info and shrink the image.
          find "$base/sbin" "$base/bin" "$base/libexec" -type f \
            -exec "$STRIP" --strip-unneeded {} +
          runHook postInstall
        '';

        dontDisableStatic = true;
      };

      # Per-user authorized_keys files: concatenate all specified key paths for
      # each user into a single file that gets baked into the read-only image.
      authorizedKeyFiles = lib.mapAttrs (
        user: keyPaths:
        pkgs.writeText "authorized_keys_${user}" (
          lib.concatStringsSep "\n" (map builtins.readFile keyPaths) + "\n"
        )
      ) config.sshd.authorizedKeys;

      # Install entries: each becomes one BUILD_PREBUILT block in Android.mk and
      # one entry in the phony package's LOCAL_REQUIRED_MODULES list.
      prebuilts =
        [
          { name = "sshd";        src = "tree/sbin/sshd";            class = "EXECUTABLES"; dir = "opt/openssh/sbin";    stem = "sshd"; }
          { name = "ssh";         src = "tree/bin/ssh";              class = "EXECUTABLES"; dir = "opt/openssh/bin";     stem = "ssh"; }
          { name = "scp";         src = "tree/bin/scp";              class = "EXECUTABLES"; dir = "opt/openssh/bin";     stem = "scp"; }
          { name = "ssh-keygen";  src = "tree/bin/ssh-keygen";       class = "EXECUTABLES"; dir = "opt/openssh/bin";     stem = "ssh-keygen"; }
          { name = "ssh-keyscan"; src = "tree/bin/ssh-keyscan";      class = "EXECUTABLES"; dir = "opt/openssh/bin";     stem = "ssh-keyscan"; }
          { name = "sshd-session";src = "tree/libexec/sshd-session"; class = "EXECUTABLES"; dir = "opt/openssh/libexec"; stem = "sshd-session"; }
          { name = "sshd-auth";   src = "tree/libexec/sshd-auth";    class = "EXECUTABLES"; dir = "opt/openssh/libexec"; stem = "sshd-auth"; }
          { name = "sshd_config"; src = "sshd_config";               class = "ETC";         dir = "opt/openssh/etc";     stem = "sshd_config"; }
          { name = "sshd_rc";     src = "sshd.rc";                   class = "ETC";         dir = "etc/init";            stem = "sshd.rc"; }
          { name = "ssh_start";   src = "ssh_start";                 class = "EXECUTABLES"; dir = "bin";                 stem = "ssh_start"; }
        ]
        ++ lib.mapAttrsToList (user: _: {
          name = "authorized_keys_${user}";
          src  = "authorized_keys.d/${user}";
          class = "ETC";
          dir  = "opt/openssh/etc/authorized_keys.d";
          stem = user;
        }) config.sshd.authorizedKeys;

      mkPrebuilt = p: ''
        include $(CLEAR_VARS)
        LOCAL_MODULE          := openssh_${p.name}
        LOCAL_MODULE_TAGS     := optional
        LOCAL_MODULE_CLASS    := ${p.class}
        LOCAL_MODULE_PATH     := $(TARGET_OUT)/${p.dir}
        LOCAL_MODULE_STEM     := ${p.stem}
        LOCAL_SRC_FILES       := ${p.src}
        LOCAL_CHECK_ELF_FILES := false
        LOCAL_STRIP_MODULE    := false
        include $(BUILD_PREBUILT)
      '';

      androidMk = pkgs.writeText "Android.mk" ''
        LOCAL_PATH := $(call my-dir)

        ${lib.concatMapStrings mkPrebuilt prebuilts}
        include $(CLEAR_VARS)
        LOCAL_MODULE           := openssh
        LOCAL_REQUIRED_MODULES := \
            ${lib.concatStringsSep " \\\n    " (map (p: "openssh_${p.name}") prebuilts)}
        include $(BUILD_PHONY_PACKAGE)
      '';

      # Stage the generated Android.mk together with the binary tree and the
      # config/init/launcher it references.
      sourceDir = pkgs.runCommand "robotnix-openssh" { } ''
        mkdir -p $out/tree
        cp -r ${opensshAndroid}${prefix}/. $out/tree/
        cp ${androidMk}      $out/Android.mk
        cp ${./sshd_config}  $out/sshd_config
        cp ${./sshd.rc}      $out/sshd.rc
        cp ${./ssh_start}    $out/ssh_start
        ${lib.optionalString (authorizedKeyFiles != { }) ''
          mkdir -p $out/authorized_keys.d
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (user: file: "cp ${file} $out/authorized_keys.d/${user}") authorizedKeyFiles
          )}
        ''}
      '';
    in
    {
      options.sshd.authorizedKeys = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.path);
        default = { };
        description = ''
          Per-user authorized-key files to bake into the read-only system image.
          Keys are installed as /system/opt/openssh/etc/authorized_keys.d/<user>,
          which sshd_config lists as the first AuthorizedKeysFile path.
        '';
        example = lib.literalExpression ''{ root = [ ./id_ed25519.pub ]; }'';
      };

      config = {
        source.dirs."robotnix/openssh".src = sourceDir;
        # The Android.mk's phony meta-package pulls in every prebuilt it declares.
        system.additionalProductPackages = [ "openssh" ];

        # Install the SELinux policy by dropping our domain into the platform
        # private policy and labelling the binaries + /data/ssh. The sepolicy
        # build globs private/*.te, so the new domain is compiled in.
        source.dirs."system/sepolicy".postPatch = ''
          cp ${./sepolicy/sshd.te} private/sshd.te
          cat ${./sepolicy/file_contexts} >> private/file_contexts
          # Label port 8022 so sshd_port_t name_bind is satisfied.
          echo 'portcon tcp 8022 u:object_r:sshd_port_t:s0' >> private/port_contexts
        '';
      };
    };
in
{
  flake.modules.android.openssh = flake.lib.android.mkAspect [ ] opensshModule;
}
