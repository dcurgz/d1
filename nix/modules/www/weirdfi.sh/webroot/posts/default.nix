{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
in

{
  flake.modules.nixos."weirdfi.sh-posts" = flake.lib.nixos.mkAspect (with flake.tags; [ flake-default ])
    ({
      lib,
      config,
      pkgs,
      ...
    }:

    let
      inherit (pkgs.by.lib) replaceOptionalVars;
      cfg = config.by.www."weirdfi.sh";
      inherit (cfg) templates;
      lib' = cfg.lib;
      posts =
        let
          posts = lib.pipe cfg.pages [
            # only show posts
            (builtins.filter (post: pkgs.by.lib.strings.startsWith "/posts/" post.slug))
            # don't show the index page
            (builtins.filter (post: post.slug != "/posts/"))
            # sort by date
            (builtins.sort (a: b: a.date < b.date))
            # render as mdoc list
            (builtins.map (post:
              ''
                .It
                .Lk ${post.slug} ${post.title}
                (${post.date})
              ''))
            # 
            (lib.strings.join "\n")
          ];
        in ''
        .Bl
        ${posts}
        .El
      '';
    in
    {
      config.by.www."weirdfi.sh".pages = [
        {
          title = "List Index";
          description = "list of posts.";
          date = "2026-07-01";
          slug = "/posts/";
          permalink = null;
          src = lib.pipe ./default.7 [
            (path: replaceOptionalVars path templates)
            (path: replaceOptionalVars path { inherit posts; })
            (path: lib'.renderMdoc "index.html" path)
          ];
        }
      ];
    });
}
