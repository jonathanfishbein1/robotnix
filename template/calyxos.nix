{ config, ... }:
{
  # device codename - crosshatch for Pixel 3 XL in this case.
  # Supported devices are listed in flavors/calyxos/devices.json
  device = "crosshatch";

  # CalyxOS branch.
  # Supported branches: android14, android15, android15-qpr1, android15-qpr2, android16
  calyxos.branch = "android15-qpr2";

  apps.fdroid.enable = true;

  # Enables ccache for the build process. Remember to add /var/cache/ccache as
  # an additional sandbox path to your Nix config.
  ccache.enable = true;
}
