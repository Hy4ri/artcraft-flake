{
  description = "ArtCraft Crafting Apps (PhotoCraft, VectorCraft, FilmCraft, LightCraft, PdfCraft, EffectCraft, DesignCraft, CadCraft, DeckCraft, GridCraft, SoundCraft, WordCraft, FigCraft, Craft Anything, TextureCraft, MaterialCraft, AniCraft) — one flake, one overlay";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Read the exact versions and hashes from version.json
      versions = builtins.fromJSON (builtins.readFile ./version.json);
      appNames = builtins.attrNames versions;

      overlay = final: _prev:
        let
          baseApps = nixpkgs.lib.genAttrs appNames (name:
            final.callPackage ./package.nix { inherit name; info = versions.${name}; }
          );
          ghidraHeadless = final.runCommand "ghidra-headless-compat" { } ''
            mkdir -p $out/bin
            ln -s ${final.ghidra}/lib/ghidra/support/analyzeHeadless $out/bin/analyzeHeadless
          '';
          craftAnythingFull = final.symlinkJoin {
            name = "craft-anything-full-${versions.craft-anything.version}";
            paths = [ baseApps.craft-anything ];
            nativeBuildInputs = [ final.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/craft-anything \
                --prefix PATH : ${final.lib.makeBinPath [ ghidraHeadless ]}
              wrapProgram $out/bin/craft-anything-cli \
                --prefix PATH : ${final.lib.makeBinPath [ ghidraHeadless ]}
            '';
            passthru = (baseApps.craft-anything.passthru or { }) // {
              unwrapped = baseApps.craft-anything;
            };
            meta = (baseApps.craft-anything.meta or { }) // {
              description = "${baseApps.craft-anything.meta.description or "Craft Anything"} (bundled with Ghidra for Deep recreation mode)";
            };
          };
        in
        baseApps // {
          # craft-anything bundled with Ghidra for Deep recreation mode
          craft-anything-full = craftAnythingFull;
          # Compatibility alias for the renamed PrintCraft app
          printcraft = baseApps.pdfcraft;
        };
    in
    {
      overlays.default = overlay;

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ overlay ]; };
          availApps = builtins.filter (n: builtins.hasAttr system versions.${n}.hashes) appNames;
          apps = nixpkgs.lib.genAttrs availApps (n: pkgs.${n});
        in
        apps // {
          inherit (pkgs) craft-anything-full;
          # Default package builds and links all ArtCraft applications together
          default = pkgs.symlinkJoin {
            name = "artcraft-apps";
            paths = builtins.attrValues apps;
          };
        });

      apps = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ overlay ]; };
          availApps = builtins.filter (n: builtins.hasAttr system versions.${n}.hashes) appNames;
          allAppNames = availApps ++ [ "craft-anything-full" ];
        in
        nixpkgs.lib.genAttrs allAppNames (n: {
          type = "app";
          program = "${self.packages.${system}.${n}}/bin/${if n == "craft-anything-full" then "craft-anything" else n}";
        }));
    };
}
