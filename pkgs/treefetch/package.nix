{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "treefetch";
  version = "unstable-2022-06-08";

  src = fetchFromGitHub {
    owner = "angelofallars";
    repo = "treefetch";
    rev = "02f65e11e1f23d5fa9e66335eb5ff4f2f6b01400";
    hash = "sha256-FDiulTit492KwV46A3qwjHQwzpjVJvIXTfTrMufXd5k=";
  };

  cargoHash = "sha256-cbJ3Xr9oxMTfEtjcqeFL8c76p8bMMf3lbcdGU3cGvRA=";

  meta = {
    description = "A plant-based system fetch tool made with Rust.";
    longDescription = "A comfy and fast system fetch tool made in Rust. Tested to be much faster than neofetch and pfetch.";
    homepage = "https://github.com/angelofallars/treefetch";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ getchoo ];
    mainProgram = "treefetch";
    platforms = lib.platforms.unix;
  };
}
