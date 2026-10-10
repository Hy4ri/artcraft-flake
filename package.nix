{ lib, stdenv, fetchurl, autoPatchelfHook, alsa-lib
, dbus, libGL, libxkbcommon, libx11, libxcb, libxcursor, libxi, vulkan-loader, wayland
, name
, info
}:

# Generic derivation for building ArtCraft applications.
# Fetches pre-compiled Linux binaries from GitHub releases to avoid long Rust compilation times,
# and uses autoPatchelfHook to ensure they run correctly on NixOS.

let
  system = stdenv.hostPlatform.system;
  arch = { x86_64-linux = "x86_64"; aarch64-linux = "aarch64"; }.${system};

  # Dependencies needed at runtime by the pre-compiled binaries
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

  # C/C++ and Alsa libs required for linking
  buildInputs = [ stdenv.cc.cc.lib alsa-lib ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    # The upstream tarball contains bin/ and share/ with the application files
    cp -r bin share $out/

    runHook postInstall
  '';

  # dlopen()ed at runtime: autoPatchelfHook adds these to every ELF's rpath
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
