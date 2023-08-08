{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  rustPlatform,
  buildGoModule,
  makeDesktopItem,
  CoreServices,
  Security,
  WebKit,
  pnpm,
  esbuild,
  dbus,
  freetype,
  gtk3,
  jq,
  libappindicator-gtk3,
  librsvg,
  libsoup,
  moreutils,
  openssl,
  pkg-config,
  webkitgtk,
  wrapGAppsHook,
}:
rustPlatform.buildRustPackage rec {
  pname = "theseus";
  version = "unstable-2023-08-05";

  src = fetchFromGitHub {
    owner = "modrinth";
    repo = "theseus";
    rev = "47e28d24c81a00477afd91da8e1cdf3a79720385";
    sha256 = "sha256-nC3tPizddjRtGFqEovWvomDakIt/1tdQOPtnM0+8nn8=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "tauri-plugin-single-instance-0.0.0" = "sha256-G4h2OXKPpZMmradutdUWxGG5axL9XMz2ACAe8AQ40eg=";
    };
  };

  pnpm-deps = stdenvNoCC.mkDerivation {
    pname = "${pname}-pnpm-deps";
    inherit src version;

    nativeBuildInputs = [
      jq
      moreutils
      pnpm
    ];

    # https://github.com/NixOS/nixpkgs/blob/763e59ffedb5c25774387bf99bc725df5df82d10/pkgs/applications/misc/pot/default.nix#L56
    installPhase = ''
      export HOME=$(mktemp -d)

      cd theseus_gui
      pnpm config set store-dir $out
      pnpm install --frozen-lockfile --no-optional --ignore-script

      rm -rf $out/v3/tmp
      for f in $(find $out -name "*.json"); do
        sed -i -E -e 's/"checkedAt":[0-9]+,//g' $f
        jq --sort-keys . $f | sponge $f
      done
    '';

    dontFixup = true;
    outputHashMode = "recursive";
    outputHash = "sha256-jFA8FTl1pi4pyuOzyg9kzzDTGjqtWiuI8hR6HkhrslU=";
  };

  buildInputs =
    [openssl]
    ++ lib.optionals stdenv.isLinux [
      dbus
      freetype
      gtk3
      libappindicator-gtk3
      librsvg
      libsoup
      webkitgtk
    ]
    ++ lib.optionals stdenv.isDarwin [CoreServices Security WebKit];

  nativeBuildInputs = [
    pkg-config
    pnpm
    wrapGAppsHook
  ];

  ESBUILD_BINARY_PATH = "${lib.getExe (esbuild.override {
    buildGoModule = args:
      buildGoModule (args
        // rec {
          version = "0.17.19";
          src = fetchFromGitHub {
            owner = "evanw";
            repo = "esbuild";
            rev = "v${version}";
            hash = "sha256-PLC7OJLSOiDq4OjvrdfCawZPfbfuZix4Waopzrj8qsU=";
          };
          vendorHash = "sha256-+BfxCyg0KkDQpHt/wycy/8CTG6YBA/VJvJFhhzUnSiQ=";
        });
  })}";

  preBuild = ''
    export HOME=$(mktemp -d)
    export STORE_PATH=$(mktemp -d)
    pushd theseus_gui

    cp -r ${pnpm-deps}/* "$STORE_PATH"
    chmod -R +w "$STORE_PATH"

    pnpm config set store-dir "$STORE_PATH"
    pnpm install --offline --frozen-lockfile --no-optional --ignore-script
    pnpm build

    popd
  '';

  desktopItem = makeDesktopItem {
    name = "com.modrinth.theseus";
    exec = "theseus_gui";
    icon = "com.modrinth.theseus";
    desktopName = "Modrinth App";
    genericName = meta.description;
  };

  postInstall = ''
    mkdir -p $out/share/icons/hicolor/256x256/apps
    mkdir -p $out/share/applications
    cp theseus_gui/src-tauri/icons/Square284x284Logo.png $out/share/icons/hicolor/256x256/apps/com.modrinth.theseus.png
    cp ${desktopItem}/share/applications/*.desktop $out/share/applications
  '';

  meta = with lib; {
    description = "Modrinth's future game launcher";
    longDescription = ''
      Modrinth's future game launcher which can be used as a CLI, GUI, and a library for creating and playing Modrinth projects.
    '';
    homepage = "https://modrinth.com";
    license = licenses.gpl3Plus;
    maintainers = [maintainers.getchoo];
    platforms = with platforms; linux ++ darwin;
  };
}
