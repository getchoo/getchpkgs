{
  lib,
  fastfetch,
  fetchFromGitHub,
  installShellFiles,
  macchina,
  makeBinaryWrapper,
  neowofetch,
  rustPlatform,
  unstableGitUpdater,
  withAutocomplete ? true,
  withColor ? true,
  withFastfetch ? true,
  withMacchina ? true,
}:

let
  binPath =
    [
      neowofetch
    ]
    ++ lib.optional withFastfetch fastfetch
    ++ lib.optional withMacchina macchina;
in
rustPlatform.buildRustPackage rec {
  pname = "hyfetch";
  version = "1.99.0-unstable-2024-10-29";

  src = fetchFromGitHub {
    owner = "hykilpikonna";
    repo = "hyfetch";
    rev = "e630b7837fd4d09fadf377413e1ffa44fa80f9b6";
    hash = "sha256-WPJzLm27Ourt5KddMCwt7TuuFTz4TIIm5yd5E8NiQmI=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-qalxKvNwLcQCXBA52vbb8SUmC2RpFZyJ1NbM2DPHaeI=";

  outputs = [
    "out"
    "man"
  ];

  strictDeps = true;

  nativeBuildInputs = [
    installShellFiles
    makeBinaryWrapper
  ];

  cargoBuildNoDefaultFeatures = true;
  cargoBuildFeatures =
    lib.optional withAutocomplete "autocomplete"
    ++ lib.optional withColor "color"
    ++ lib.optional withMacchina "macchina";

  cargoBuildFlags = [
    "--package"
    "hyfetch"
  ];
  cargoTestFlags = cargoBuildFlags;

  postInstall = ''
    installManPage docs/hyfetch.1
  '';

  postFixup = ''
    wrapProgram "$out"/bin/hyfetch \
      --prefix PATH : ${lib.makeBinPath binPath}
  '';

  passthru = {
    updateScript = unstableGitUpdater { };
  };

  meta = {
    description = "neofetch with pride flags <3";
    longDescription = ''
      HyFetch is a command-line system information tool fork of neofetch.
      HyFetch displays information about your system next to your OS logo
      in ASCII representation. The ASCII representation is then colored in
      the pattern of the pride flag of your choice. The main purpose of
      HyFetch is to be used in screenshots to show other users what
      operating system or distribution you are running, what theme or
      icon set you are using, etc.
    '';
    homepage = "https://github.com/hykilpikonna/HyFetch";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ getchoo ];
    mainProgram = "hyfetch";
  };
}
