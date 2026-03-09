{ config, ... }:
{
  # device codename - crosshatch for Pixel 3 XL in this case.
  # Supported devices are listed in flavors/calyxos/devices.json
  device = "crosshatch";

  calyxos.branch = "android16";

  apps.fdroid.enable = true;

  # Enables ccache for the build process. Remember to add /var/cache/ccache as
  # an additional sandbox path to your Nix config.
  ccache.enable = true;
}
