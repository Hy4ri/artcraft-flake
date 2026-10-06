# artcraft-flake

One flake for all seven [ArtCraft Crafting Apps](https://getartcraft.com/apps) (open-source, native Rust):
`photocraft` `vectorcraft` `filmcraft` `lightcraft` `printcraft` `effectcraft` `designcraft`.

Each is packaged from upstream's relocatable `linux-<arch>.tar.gz` release (smaller and cleaner than
AppImage/deb/rpm, no FUSE or dpkg needed) and patched with `autoPatchelfHook`. Every package ships the GUI
(`<name>`), the CLI (`<name>-cli`), the .desktop file, icons and metainfo. Systems: x86_64-linux, aarch64-linux.

## Use

    nix run github:Hy4ri/artcraft-flake#photocraft
    nix profile install github:Hy4ri/artcraft-flake#lightcraft
    nix build github:Hy4ri/artcraft-flake            # default = all seven

Overlay (NixOS / home-manager):

    inputs.artcraft.url = "github:Hy4ri/artcraft-flake";
    nixpkgs.overlays = [ inputs.artcraft.overlays.default ];
    environment.systemPackages = with pkgs; [ photocraft filmcraft ];   # each app by its own name

## Updates

`version.json` maps `app -> { version, hashes.<system> }`. `scripts/check-update.sh` compares every app with its
latest GitHub release; `update-version.sh` re-syncs all apps from each release's `SHA256SUMS.txt`
(no archive downloads). The daily workflow builds before pushing and opens a deduped issue on failure.
Adding an app = add its key to `version.json` and run `./update-version.sh`.
