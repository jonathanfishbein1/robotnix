{
  description = "A basic example robotnix configuration";

  inputs.robotnix.url = "github:nix-community/robotnix";

  outputs =
    { self, robotnix }:
    {
      # Declare your robotnix configurations. You can build the images and OTA
      # zips via the `img` and `ota` attrs, for instance `nix build .#robotnixConfigurations.myCalyxOS.ota`.
      robotnixConfigurations."myCalyxOS" = robotnix.lib.robotnixSystem ./calyxos.nix;

      # This provides a convenient output which allows you to build the image by
      # simply running "nix build" on this flake.
      packages.x86_64-linux.default = self.robotnixConfigurations."myCalyxOS".img;
    };
}
