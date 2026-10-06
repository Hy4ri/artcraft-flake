{ lib, stdenv, fetchurl, autoPatchelfHook, alsa-lib
, dbus, libGL, libxkbcommon, libx11, libxcb, libxcursor, libxi, vulkan-loader, wayland
, name
, info
}:

# One generic derivation for every Crafting App.
# Upstream ships a relocatable tar.gz (bin/, share/applications, icons,
# metainfo) per arch — the cleanest Linux format, no FUSE/dpkg needed.
# version.json holds { <app>: { version, hashes.<system> } } and is kept
# current by update-version.sh.

let
  system = stdenv.hostPlatform.system;
  arch = { x86_64-linux = "x86_64"; aarch64-linux = "aarch64"; }.${system};

  runtimeLibs = [ alsa-lib dbus libGL libxkbcommon libx11 libxcb libxcursor libxi vulkan-loader wayland ];
in
stdenv.mkDerivation {
  pname = name;
  inherit (info) version;

  src = fetchurl {
    url = "https://github.com/storytold/${name}/releases/download/v${info.version}/${name}-${info.version}-linux-${arch}.tar.gz";
    hash = info.hashes.${system};
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib alsa-lib ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r bin share $out/
    runHook postInstall
  '';

  # dlopen()ed at runtime: autoPatchelfHook adds these to every ELF's rpath.
  runtimeDependencies = runtimeLibs;

  meta = {
    description = "ArtCraft ${name}: open-source native creative app written in Rust";
    homepage = "https://getartcraft.com/apps/${name}";
    license = with lib.licenses; [ asl20 mit ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = name;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
