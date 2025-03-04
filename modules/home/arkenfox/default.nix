{
  config,
  lib,
  pkgs,
  ...
}:

let
  # ===
  ## Pollyfill from mkFirefoxModule
  ## https://github.com/nix-community/home-manager/blob/70fbbf05a5594b0a72124ab211bff1d502c89e3f/modules/programs/firefox/mkFirefoxModule.nix
  # ===

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  cfg = config.programs.firefox;

  profilesPath = if isDarwin then "${cfg.configPath}/Profiles" else cfg.configPath;

  # ===
  ## Actual module
  # ===

  arkenfoxVersions = lib.mapAttrs (
    tag: hash:
    pkgs.fetchFromGitHub {
      owner = "arkenfox";
      repo = "user.js";
      inherit tag hash;
    }
  ) (lib.importJSON ./arkenfox-hashes.json);

  arkenfoxProfiles = lib.filterAttrs (lib.const (profile: profile.arkenfox.enable)) cfg.profiles;

  arkenfoxSubmodule =
    { config, ... }:
    {
      options = {
        arkenfox = {
          enable = lib.mkEnableOption "arkenfox";

          version = lib.mkOption {
            type = lib.types.str;
            default = lib.versions.majorMinor pkgs.firefox.version;
            defaultText = lib.literalExpression "lib.versions.majorMinor pkgs.firefox.version";
            description = ''
              Version of Arkenfox to apply.

              This should match a tag in https://github.com/arkenfox/user.js.
            '';
          };

          source = lib.mkOption {
            type = lib.types.path;
            internal = true;
          };
        };
      };

      config = {
        arkenfox.source = lib.mkDefault arkenfoxVersions.${config.arkenfox.version};
      };
    };
in

{
  options.programs.firefox.profiles = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule arkenfoxSubmodule);
  };

  config = {
    home = {
      # TODO: Find a better way to do this
      activation.arkenfoxPrefsCleaner = lib.mkIf (arkenfoxProfiles != [ ]) (
        lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] (
          lib.concatLines (
            lib.mapAttrsToList (lib.const (
              profile:

              let
                prefsCleanerPath = "${config.home.homeDirectory}/${profilesPath}/${profile.path}/prefsCleaner.sh";
              in

              "run --quiet cp ${
                profile.arkenfox.source + "/prefsCleaner.sh"
              } ${prefsCleanerPath} && run --quiet ${prefsCleanerPath}"
            )) arkenfoxProfiles
          )
        )
      );

      file = lib.mkMerge (
        lib.mapAttrsToList (lib.const (
          profile:

          let
            shouldCreateUserJs =
              profile.preConfig != ""
              || profile.settings != { }
              || profile.extraConfig != ""
              || profile.bookmarks != [ ]
              || profile.arkenfox.enable;

            userJsPath = "${profilesPath}/${profile.path}/user.js";

            homeManagerUserJs =
              pkgs.writeText "home-manager-firefox-profile-${profile.name}-home-manager-userjs"
                (toString config.home.file.${userJsPath}.text);
          in

          {
            ${userJsPath} = lib.mkIf shouldCreateUserJs {
              source = pkgs.runCommand "home-manager-firefox-profile-${profile.name}-userjs" { } ''
                echo "// Generated by getchoo's Arkenfox module" > $out
                echo >> $out
                cat ${profile.arkenfox.source + "/user.js"} >> $out
                echo >> $out
                cat ${homeManagerUserJs} >> $out
              '';
            };
          }
        )) cfg.profiles
      );
    };
  };
}
