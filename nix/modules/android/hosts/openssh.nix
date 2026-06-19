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
# This module mirrors robotnix's own modules/etc.nix mechanism: it stages the
# files into a source dir with a generated Android.mk of BUILD_PREBUILT modules
# and registers them in `system.additionalProductPackages`.
#
# NOTE on SELinux: GrapheneOS/AOSP runs in enforcing mode. The init service
# must run in a domain that is permitted to start sshd, bind its port, exec a
# shell and read /data/ssh. A complete sepolicy for that is out of scope here
# and must be supplied via BOARD_SEPOLICY_DIRS; until then the service will be
# denied under enforcing policy (Magisk sidesteps this with its own
# unconstrained domain). The server otherwise listens on a high port (8022) so
# it never needs privileges to bind a port below 1024.
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
      ...
    }:

    let
      inherit (lib) concatMapStringsSep;

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
          mkdir -p "$base/sbin" "$base/bin" "$base/libexec" "$base/etc" "$base/var/empty"
          cp sshd "$base/sbin/"
          for b in ssh scp sftp ssh-keygen ssh-keyscan ssh-add ssh-agent; do
            cp "$b" "$base/bin/"
          done
          for b in sftp-server sshd-session sshd-auth; do
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

      # Each entry becomes one BUILD_PREBUILT module in the generated
      # Android.mk. `dest` is relative to $(TARGET_OUT) (i.e. /system).
      prebuilts =
        let
          bin = name: subdir: {
            moduleName = "openssh_${name}";
            src = "${opensshAndroid}${prefix}/${subdir}/${name}";
            dest = "opt/openssh/${subdir}/${name}";
            class = "EXECUTABLES";
          };
        in
        [
          (bin "sshd" "sbin")
          (bin "ssh" "bin")
          (bin "scp" "bin")
          (bin "sftp" "bin")
          (bin "ssh-keygen" "bin")
          (bin "ssh-keyscan" "bin")
          (bin "sftp-server" "libexec")
          (bin "sshd-session" "libexec")
          (bin "sshd-auth" "libexec")
          {
            moduleName = "openssh_ssh_start";
            src = ./openssh/ssh_start;
            dest = "bin/ssh_start";
            class = "EXECUTABLES";
          }
          {
            moduleName = "openssh_sshd_config";
            src = ./openssh/sshd_config;
            dest = "opt/openssh/etc/sshd_config";
            class = "ETC";
          }
          {
            moduleName = "openssh_sshd_rc";
            src = ./openssh/sshd.rc;
            dest = "etc/init/sshd.rc";
            class = "ETC";
          }
        ];

      androidmk = pkgs.writeText "Android.mk" (
        ''
          LOCAL_PATH := $(call my-dir)

        ''
        + concatMapStringsSep "\n" (p: ''
          include $(CLEAR_VARS)
          LOCAL_MODULE := ${p.moduleName}
          LOCAL_MODULE_TAGS := optional
          LOCAL_MODULE_CLASS := ${p.class}
          LOCAL_MODULE_PATH := $(TARGET_OUT)/${builtins.dirOf p.dest}
          LOCAL_MODULE_STEM := ${builtins.baseNameOf p.dest}
          LOCAL_SRC_FILES := ${p.moduleName}
          LOCAL_CHECK_ELF_FILES := false
          LOCAL_STRIP_MODULE := false
          include $(BUILD_PREBUILT)
        '') prebuilts
      );

      sourceDir = pkgs.runCommand "robotnix-openssh" { } (
        ''
          mkdir -p $out
          cp ${androidmk} $out/Android.mk
        ''
        + concatMapStringsSep "\n" (p: ''
          cp ${p.src} $out/${p.moduleName}
        '') prebuilts
      );
    in
    {
      source.dirs."robotnix/openssh".src = sourceDir;
      system.additionalProductPackages = map (p: p.moduleName) prebuilts;
    };
in
{
  flake.modules.android.openssh = flake.lib.android.mkAspect [ ] opensshModule;
}
