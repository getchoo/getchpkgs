{self, ...}: {
  flake = {
    templates = let
      # string -> string -> {}
      mkTemplate = name: description: {
        path = "${self}/templates/${name}";
        inherit description;
      };
    in {
      basic = mkTemplate "basic" "minimal boilerplate for my flakes";
      full = mkTemplate "full" "big template for complex flakes (using flake-parts)";
    };
  };
}
