# SPDX-FileCopyrightText: 2020 Daniel Fullmer and robotnix contributors
# SPDX-License-Identifier: MIT

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./vendor-blobs.nix
  ];

  options.calyxos = {
    branch = lib.mkOption {
      type = with lib.types; str;
      default = "android15-qpr2";
      description = ''
        The CalyxOS branch to build from.
      '';
      example = "android15-qpr2";
    };

    release = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = ''
        The CalyxOS release version/tag to build.
      '';
      example = "6.10.20";
    };
  };

  config =
    let
      inherit (lib)
        optional
        optionalString
        optionalAttrs
        elem
        mkIf
        mkMerge
        mkDefault
        mkForce
        ;

      # Map Android branch to platform version
      branchToAndroidVersion = {
        "android16" = 16;
        "android15-qpr3" = 15;
        "android15-qpr2" = 15;
        "android15-qpr1" = 15;
        "android15" = 15;
        "android14-qpr3" = 14;
        "android14-qpr2" = 14;
        "android14" = 14;
      };

      supportedDevices = lib.importJSON ./devices.json;
    in
    mkIf (config.flavor == "calyxos") (mkMerge [
      {
        release = "cur";
        productNamePrefix = "";
        buildNumber = mkDefault (
          if config.calyxos.release != null then config.calyxos.release else config.calyxos.branch
        );

        androidVersion = mkDefault (branchToAndroidVersion.${config.calyxos.branch} or 15);

        # Match CalyxOS build environment
        envVars = {
          BUILD_USERNAME = "calyxos";
          BUILD_HOSTNAME = "calyxos";
        };

        source.manifest = {
          enable = true;
          lockfile = mkDefault (./. + "/${config.calyxos.branch}/repo.lock");
        };

        warnings =
          (optional (
            (config.device != null) && !(elem config.device supportedDevices)
          ) "${config.device} is not a supported device for CalyxOS")
          ++ (optional (
            !(elem config.androidVersion [
              14
              15
              16
            ])
          ) "Unsupported androidVersion (not in [14, 15, 16]) for CalyxOS");
      }
      {
        # CalyxOS includes these apps by default
        apps.seedvault.includedInFlavor = mkDefault true;
        apps.updater.includedInFlavor = mkDefault true;

        # CalyxOS includes microG
        microg.enable = mkDefault true;

        # CalyxOS uses APEX
        signing.apex.enable = mkDefault true;

        # Add tools needed by CalyxOS vendor blob extraction
        envPackages = with pkgs; [
          curl
          # Tools for vendor blob extraction (adevtool-style)
          e2fsprogs # for debugfs to extract ext4 images
          python3
          unzip
        ];
      }
    ]);
}
