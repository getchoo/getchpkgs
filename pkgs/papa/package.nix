{
  lib,
  fetchFromGitHub,
  installShellFiles,
  nix-update-script,
  openssl,
  papa,
  pkg-config,
  rustPlatform,
  testers,
}:

rustPlatform.buildRustPackage rec {
  pname = "papa";
  version = "4.1.0-rc.4";

  src = fetchFromGitHub {
    owner = "AnActualEmerald";
    repo = "papa";
    rev = "refs/tags/v${version}";
    hash = "sha256-XAYenoWLKeNzNozFRPz84WDeU0/y2hd/wgr3UeZLFS0=";
  };

  postUnpack = ''
    rmdir source/thermite
    ln -sf ${passthru.libthermite} source/thermite
  '';

  cargoHash = "sha256-2Hmy0nkdUhwBJstMkff3t7oEHyAbkud9JxY3SXb3c9c=";

  nativeBuildInputs = [
    pkg-config
    installShellFiles
  ];

  buildInputs = [ openssl ];

  postInstall = ''
    installShellCompletion --cmd papa \
      --bash <($out/bin/papa complete bash) \
      --fish <($out/bin/papa complete fish) \
      --zsh <($out/bin/papa complete zsh)
  '';

  passthru = {
    libthermite = fetchFromGitHub {
      owner = "AnActualEmerald";
      repo = "thermite";
      rev = "8e6fc6af20e9bd2af4313fee65dfed05cfa1bbd5";
      hash = "sha256-7zkXW2G7cwyobYJO22o1QoJRs2O6sD7/S9frZ/+DNIQ=";
    };

    tests.version = testers.testVersion { package = papa; };

    updateScript = nix-update-script { };
  };

  meta = {
    description = "Mod manager for Northstar clients and servers";
    homepage = "https://github.com/AnActualEmerald/papa";
    changelog = "https://github.com/AnActualEmerald/papa/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ getchoo ];
    mainProgram = "papa";
    platforms = lib.platforms.unix;
  };
}
