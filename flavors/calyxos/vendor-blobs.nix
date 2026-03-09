# SPDX-FileCopyrightText: 2025 robotnix contributors
# SPDX-License-Identifier: MIT
#
# CalyxOS vendor blob pre-fetching integration
# This module fetches factory images before the build and makes them
# available to the CalyxOS build process.

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.calyxos;

  # Path to vendor metadata for current branch and device
  vendorMetadataPath = if config.device != null then ./. + "/${cfg.branch}/vendor_imgs/${config.device}.json" else null;
  vendorMetadataExists = if vendorMetadataPath != null then builtins.pathExists vendorMetadataPath else false;

  # Import vendor metadata if it exists
  vendorMetadata = if vendorMetadataExists
    then lib.importJSON vendorMetadataPath
    else null;

in
{
  options.calyxos = {
    vendorBlobs = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = vendorMetadataExists;
        description = ''
          Enable automatic vendor blob fetching using pre-generated metadata.
          Automatically enabled if vendor metadata exists for the device.
        '';
      };

      factoryImage = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Pre-fetched factory image path. Automatically set if vendor metadata exists.
        '';
      };
    };
  };

  config = lib.mkIf (cfg.vendorBlobs.enable && vendorMetadata != null) {
    # Pre-fetch the factory image using fetchurl
    calyxos.vendorBlobs.factoryImage = pkgs.fetchurl {
      url = vendorMetadata.url;
      sha256 = vendorMetadata.sha256;
      name = vendorMetadata.fileName;
    };

    # Add tools needed for vendor blob extraction
    envPackages = with pkgs; [
      # Already added in default.nix: curl
      unzip
      python3
      # Additional tools for vendor blob extraction
      file
      findutils
    ];

    # Warnings if metadata is missing
    warnings = lib.optionals (!vendorMetadataExists && config.device != null) [
      ("No vendor metadata found for ${config.device} on branch ${cfg.branch}. " +
       "Run ./extract-vendor-metadata.py to generate it. " +
       "See flavors/calyxos/README.md for details.")
    ];
  };
}
