{
  description = "ArtCraft Crafting Apps (PhotoCraft, VectorCraft, FilmCraft, LightCraft, PdfCraft, EffectCraft, DesignCraft) — one flake, one overlay";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      versions = builtins.fromJSON (builtins.readFile ./version.json);
      appNames = builtins.attrNames versions;

      overlay = final: _prev:
        nixpkgs.lib.genAttrs appNames (name:
          final.callPackage ./package.nix { inherit name; info = versions.${name}; })
        # Upstream renamed PrintCraft -> PdfCraft; keep the old attr working.
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
          # `nix build` / `nix profile install` with no name = every app.
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
