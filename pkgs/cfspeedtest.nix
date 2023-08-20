{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "cfspeedtest";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "code-inflation";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-FgxSx0atSx3FccgjiO8OZ4j4IjkTpToGSViZyS3s8Cw=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  meta = with lib; {
    homepage = "https://github.com/code-inflation/cfspeedtest";
    description = "Unofficial CLI for speed.cloudflare.com";
    license = licenses.mit;
    maintainers = with maintainers; [getchoo];
  };
}
