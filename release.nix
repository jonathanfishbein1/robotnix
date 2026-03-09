# SPDX-FileCopyrightText: 2021 Daniel Fullmer and robotnix contributors
# SPDX-License-Identifier: MIT

{
  pkgs ? (import ./pkgs { }),
}:

let
  lib = pkgs.lib;
  robotnix = configuration: import ./default.nix { inherit configuration pkgs; };
  configs = import ./configs.nix { inherit lib; };
  builtConfigs = lib.mapAttrs (name: c: robotnix c) configs;
  defaultBuild = robotnix {
    device = "crosshatch";
  };

in
{
  inherit (pkgs) diffoscope;

  imgs = lib.recurseIntoAttrs (lib.mapAttrs (name: c: c.img) builtConfigs);

  # For testing instantiation
  calyxos-crosshatch = lib.recurseIntoAttrs {
    inherit (defaultBuild)
      ota
      img
      factoryImg
      bootImg
      otaDir
      releaseScript
      ;
  };
}
