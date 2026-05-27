{
  inputs,
  ...
} @args:
let
  inherit (args.config) flake;
in

{
  flake.modules.nixos."dcurgz.me-lib" = flake.lib.nixos.mkAspect (with flake.tags; [ flake-default ])
    ({
      lib,
      config,
      pkgs,
      ...
    }:

    let
      inherit (pkgs.by.lib) replaceOptionalVars;
      inherit (inputs) nix-time;

      # so i don't have to manually manage reference indices
      renderReferences = ''
        perl -0777 -pe 's{__REF\{([a-zA-Z_]+)\s+([^\}]+)\}} {
          "<a id=\"b" . (++''$i) . "\" href=\"#''$1\">''$2</a><sup>''$i</sup>"
        }gse' \
     '';

      # mandoc escapes HTML in its '-T html' output mode. This reverses it.
      unescapeHtml = ''
        perl -0777 -pe 's{__HTML(.*?)__ENDHTML}{
          my $s=$1;
          $s=~s/&amp;/&/g;
          $s=~s/&gt;/>/g;
          $s=~s/&lt;/</g;
          $s=~s/&quot;/"/g;
          $s
        }gse' \
      '';

      # syntax sugar for preformatted inline blocks
      renderInlineBlock = ''
        perl -0777 -pe 's{`([^`]+)`}{<code class="inline">$1</code>}g' \
      '';
    in
    {
      by.www."dcurgz.me".lib = {
        renderMdoc = name: path: (lib.pipe path [
          ### (1.) render mdoc(7) to html.
          (path: pkgs.stdenv.mkDerivation (
            {
              inherit name;
              nativeBuildInputs = with pkgs; [
                by.mandoc-fork
                perl
                chroma
                gcc
                (haskellPackages.ghcWithPackages.override { } (
                  p: with p; [ ghc-stdin ]
                ))
              ];
              src = path;
              dontUnpack = true;
              # Render a .7 mdoc source file into HTML, then unescape __HTML blocks.
              buildPhase = ''
                cat $src \
                  | mandoc -T html -O style=/style.css \
                  | ${unescapeHtml} \
                  | ${renderInlineBlock} \
                  | ${renderReferences} \
                  > ${name} 
              '';
              # Copy into the out directory.
              installPhase = ''
                cp ./${name} "$out"
              '';
            }))
          ### (2.) replace common variables in the output HTML.
          (path: replaceOptionalVars path {
            nix-gitrev =
              toString (
                inputs.self.shortRev
                  or inputs.self.dirtyShortRev
                  or inputs.self.lastModified
                  or "unknown");
            nix-rfc822 = nix-time.lib.RFC-822 "GMT" inputs.self.lastModified;
            nix-date =
              with nix-time.lib.splitSecondsSinceEpoch {} inputs.self.lastModified;
              let
                month = toString B;
                day   = toString d;
                year  = toString Y;
              in
                "${month} ${day}, ${year}";
            color-scheme = builtins.readFile ./resources/color-scheme.html;
          })
        ]);
    
        renderCode = { name, lang, path }: builtins.readFile (pkgs.runCommand name
          {
            nativeBuildInputs = with pkgs; [ chroma ];
          }
          ''
            cat "${path}" \
              | chroma -l "${lang}" --html --html-only --html-lines --html-prevent-surrounding-pre \
              > $out
          '');
        };
      });
}
