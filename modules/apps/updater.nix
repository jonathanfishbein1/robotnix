# SPDX-FileCopyrightText: 2020 Daniel Fullmer and robotnix contributors
# SPDX-License-Identifier: MIT

{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    mkMerge
    types
    ;

  cfg = config.apps.updater;

  src = pkgs.fetchFromGitHub {
    owner = "GrapheneOS";
    repo = "platform_packages_apps_Updater";
    rev = "c5343bb56bd22ec430fa9f706e9d3e75a5a50fd3"; # 2021-11-11
    sha256 = "0sc0vpvp2yq71zr3bdnvkcds544127ijkqnq6dbr73ii4c270ff4";
  };

  relpath = (if cfg.includedInFlavor then "packages" else "robotnix") + "/apps/Updater";
in
{
  options = {
    apps.updater = {
      enable = mkEnableOption "OTA Updater";

      url = mkOption {
        type = types.str;
        description = "URL for OTA updates";
        apply = x: if lib.hasSuffix "/" x then x else x + "/";
      };

      includedInFlavor = mkOption {
        default = false;
        type = types.bool;
        internal = true;
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      system.additionalProductPackages = [ "Updater" ];

      resources.${relpath} = {
        inherit (cfg) url;
        channel_default = config.channel;
      };

      source.dirs = mkIf (!cfg.includedInFlavor) {
        ${relpath}.src = src;
        "robotnix/updater-sepolicy".src = ./updater-sepolicy;
        "build/make".postPatch = ''
          sed -i '/product-graph dump-products/a #add selinux policies last\n$(eval include robotnix/updater-sepolicy/sepolicy.mk)' "core/config.mk"
        '';
      };
    })

    # Remove package if it's disabled by configuration
    (mkIf (!cfg.enable && cfg.includedInFlavor) {
      source.dirs.${relpath}.enable = false;
    })
  ];
}
