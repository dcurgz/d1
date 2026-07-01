{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
in

{
  flake.modules.nixos."weirdfi.sh-templates" = flake.lib.nixos.mkAspect (with flake.tags; [ flake-default ])
    ({
      lib,
      config,
      pkgs,
      ...
    }:

    let
      cfg = config.by.www."weirdfi.sh";
      lib' = cfg.lib;
    in
    {
      config.by.www."weirdfi.sh".templates = {
        back = ''
          .Lk / "↩ take me home"
        '';
        back-posts = ''
          .Lk /posts "↩ back to posts"
        '';
        build-time = ''
          .Pp
          The source code for this website is available:
          .Lk https://github.com/dcurgz/d1/blob/master/nix/modules/www/weirdfi.sh/default.nix link .
          This page was last built declaratively on `@nix-rfc822@`.
        '';
        thoughts = ''
          .Pp
          My thoughts are my own and do not represent any current or former
          employer, obviously.
        '';
        contact =
          let
            contact-script = ''
              #!/usr/bin/env bash
              echo "E: zr@phem.fu" | tr "[n-za-m]" "[a-z]"
            '';
            contact-script' = lib'.renderCode {
              name = "contact-script-rendered";
              lang = "bash";
              path = pkgs.writeText "contact-script" contact-script;
            };
          in ''
            .Bd -literal
            __HTML${contact-script'}__ENDHTML
            .Ed
          '';
        header = ''
          .Dd @color-scheme@
          .Dt WEIRDFI.SH 7
          .Os @nix-gitrev@
        '';
        #recent-posts =
        #  let
        #    posts = lib.pipe cfg.pages [
        #      # only show posts
        #      (builtins.filter (post: pkgs.by.lib.strings.startsWith "/posts/" post.slug))
        #      # sort by date
        #      (builtins.sort (a: b: a < b))
        #      # take the last 10 posts (assume chronological order)
        #      (lib.lists.takeEnd 10)
        #      # render as mdoc list
        #      (builtins.map (post:
        #        let
        #          tags = lib.pipe post.tags [
        #            (builtins.map (tag: "__HTML<span>${tag}</span>__ENDHTML"))
        #            (lib.strings.join " ")
        #          ];
        #        in
        #        ''
        #          .It
        #          .Lk ${post.slug} ${post.title}
        #          (${post.date})
        #          .Pp
        #          ${post.description}
        #          .Pp -decorate tags
        #          ${tags}
        #        ''))
        #      # 
        #      (lib.strings.join "\n")
        #    ];
        #  in ''
        #  .Bl
        #  ${posts}
        #  .El
        #'';
      };
    });
}
