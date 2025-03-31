{
  lib,
  fetchFromGitHub,
  glib,
  openssl,
  ostree,
  pkg-config,
  postgresql,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "flat-manager";
  version = "0.4.3.3";

  src = fetchFromGitHub {
    owner = "flatpak";
    repo = "flat-manager";
    rev = "refs/tags/${version}";
    hash = "sha256-MGsxXY7PXUOTha+8lwr9HYdM4dDMA4wpqhbMleZPtX4=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-rq4VUisy6RSXTUBI1jfnCQIfASNnVV9xzy7NNzEjfuQ=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    glib
    openssl
    ostree
    postgresql
  ];

  meta = {
    description = "Manager for flatpak repositories";
    longDescription = ''
      flat-manager serves and maintains a Flatpak repository. You point it at an ostree
      repository and it will allow Flatpak clients to install apps from the repository over HTTP.
      Additionally, it has an HTTP API that lets you upload new builds and manage the repository.
    '';
    homepage = "https://github.com/flatpak/flat-manager";
    changelog = "https://github.com/flatpak/flat-manager/releases/tag/${version}";
    maintainers = with lib.maintainers; [ getchoo ];
    mainProgram = "flat-manager";
    platforms = lib.platforms.linux;
  };
}
