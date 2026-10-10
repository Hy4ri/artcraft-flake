{
  description = "ArtCraft Crafting Apps (PhotoCraft, VectorCraft, FilmCraft, LightCraft, PdfCraft, EffectCraft, DesignCraft, CadCraft, DeckCraft, GridCraft, SoundCraft, WordCraft) — one flake, one overlay";

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
        nixpkgs.lib.genAttrs appNames (name:
          final.callPackage ./package.nix { inherit name; info = versions.${name}; }
        )
        # Compatibility alias for the renamed PrintCraft app
        // { printcraft = final.pdfcraft; };
    in
    {
      overlays.default = overlay;

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ overlay ]; };
          apps = nixpkgs.lib.genAttrs appNames (n: pkgs.${n});
        in
        apps // {
          # Default package builds and links all ArtCraft applications together
          default = pkgs.symlinkJoin {
            name = "artcraft-apps";
            paths = builtins.attrValues apps;
          };
        });

      apps = forAllSystems (system:
        nixpkgs.lib.genAttrs appNames (n: {
          type = "app";
          program = "${self.packages.${system}.${n}}/bin/${n}";
        }));
    };
}
