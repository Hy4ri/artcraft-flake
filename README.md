# ArtCraft Flake

[![Build Status](https://img.shields.io/github/actions/workflow/status/Hy4ri/artcraft-flake/ci.yml?branch=main&label=build)](https://github.com/Hy4ri/artcraft-flake/actions/workflows/ci.yml)
[![Update Status](https://img.shields.io/github/actions/workflow/status/Hy4ri/artcraft-flake/update.yml?branch=main&label=auto-update)](https://github.com/Hy4ri/artcraft-flake/actions/workflows/update.yml)

Run and install all [ArtCraft Crafting Apps](https://getartcraft.com/apps) on NixOS, Home Manager, or any Linux system with Nix.

The Crafting Apps are free, open-source creative apps written in Rust. They are made to feel familiar if you come from Adobe, Microsoft, or similar tools.

The flake is updated automatically every day.

## Packages

| Package | What it is | Similar to |
|---|---|---|
| `photocraft` | Image editor | Photoshop |
| `vectorcraft` | Vector illustration | Illustrator |
| `filmcraft` | Video editor | Premiere Pro |
| `lightcraft` | Photo library and raw developer | Lightroom |
| `pdfcraft` | PDF workbench | Acrobat |
| `effectcraft` | Motion graphics and VFX | After Effects |
| `designcraft` | Page layout and publishing | InDesign |
| `figcraft` | Interface design | Figma |
| `texturecraft` | 3D texture painting | Substance Painter |
| `wordcraft` | Word processor | Word |
| `soundcraft` | Audio workstation | Pro Tools |
| `deckcraft` | Presentations | PowerPoint |
| `cadcraft` | CAD and drafting | AutoCAD |
| `solidcraft` | Parametric 3D CAD | Fusion 360 |
| `fieldcraft` | FEA, CFD, and heat transfer | |
| `gridcraft` | Spreadsheets | Excel |
| `craft-anything` | Explore how software works and build your own version | |
| `craft-anything-full` | `craft-anything` with Ghidra bundled for Deep recreation mode | |
| `default` | **All apps above** in one package | |

Each package gives you:

- the app: command `<name>`, for example `photocraft`
- its command-line tool: `<name>-cli`, for example `photocraft-cli`
- a desktop entry and icons, so the app shows in your app menu

Platforms: Linux `x86_64` and `aarch64`.

## Try it without installing

You need Nix with [flakes enabled](https://wiki.nixos.org/wiki/Flakes).

```bash
nix run github:Hy4ri/artcraft-flake#photocraft
nix run github:Hy4ri/artcraft-flake#filmcraft
```

Replace `photocraft` with any package name from the table.

## Install

There are **two ways** to install. **Pick one.** They give the same result.

| Option | Use it when |
|---|---|
| **A. Overlay** | You want to write `pkgs.photocraft`, like any other nixpkgs package. |
| **B. Direct package** | You do not want to use overlays. |

Not on NixOS? Use `nix profile install github:Hy4ri/artcraft-flake#photocraft`.

### Step 1: Add the flake input (needed for both options)

In your system `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    artcraft.url = "github:Hy4ri/artcraft-flake";
  };

  outputs = { nixpkgs, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; }; # lets your modules use `inputs`
      modules = [ ./configuration.nix ];
    };
  };
}
```

> Already have a flake? Add only the `artcraft.url` line, and make sure `inputs` reaches your modules (`specialArgs` for NixOS, `extraSpecialArgs` for Home Manager).

### Step 2, Option A: Overlay

In `configuration.nix`:

```nix
{ inputs, pkgs, ... }:
{
  nixpkgs.overlays = [ inputs.artcraft.overlays.default ];

  environment.systemPackages = with pkgs; [
    photocraft
    filmcraft
    # ...any app from the table
  ];
}
```

For Home Manager, keep the overlay line and use `home.packages` instead.

### Step 2, Option B: Direct package

In `configuration.nix`:

```nix
{ inputs, pkgs, ... }:
let
  artcraft = inputs.artcraft.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  environment.systemPackages = [
    artcraft.photocraft
    artcraft.filmcraft
    # or every app at once:
    # artcraft.default
  ];
}
```

For Home Manager, put the same packages in `home.packages`.

### Step 3: Rebuild

```bash
sudo nixos-rebuild switch --flake .#myhost
```

## How it is built

Each app is built from upstream's `linux-<arch>.tar.gz` release. This is smaller and cleaner than the AppImage, `.deb`, or `.rpm`, and it needs no FUSE or dpkg. The binaries are patched for NixOS with `autoPatchelfHook`.

> `printcraft` was renamed to `pdfcraft`. The overlay still gives `pkgs.printcraft` as an alias, so old configs keep working.

## Updates

A GitHub Action checks every app for a new release every day. It tests the build before it commits, and it opens an issue if something fails. To get new versions, update your lock file:

```bash
nix flake update artcraft
```

### For maintainers

- `version.json` maps each app to its version and hashes for each system.
- `scripts/check-update.sh` compares every app with its latest GitHub release.
- `update-version.sh` updates all apps from each release's `SHA256SUMS.txt` (it does not download the archives).
- To add an app: add its key to `version.json` and run `./update-version.sh`.

## License

The ArtCraft apps are open source (Apache-2.0 and MIT). Refer to the [ArtCraft website](https://getartcraft.com/apps) for details.

## Support

If this flake helps you, you can support my work on [GitHub Sponsors](https://github.com/sponsors/hy4ri) or [Ko-fi](https://ko-fi.com/m_5_7). A star on the repo also helps.
