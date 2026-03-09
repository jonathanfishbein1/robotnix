# To run: nix build .#checks.x86_64-linux.eval
{ pkgs }:
let
  lib = pkgs.lib;
  robotnixSystem = configuration: import ../default.nix { inherit configuration pkgs; };
in

lib.runTests {
  testSourceMountPoints = {
    expr =
      let
        dirs = [
          "a"
          "a/b"
          "a/c"
          "b/d"
          "b/e"
        ];
      in
      lib.filterAttrs (n: v: lib.elem n dirs) (
        (lib.mapAttrs (name: dir: dir.postPatch))
          (robotnixSystem {
            source.dirs = lib.genAttrs dirs (dir: { });
          }).config.source.dirs
      );
    expected = {
      "a" = ''
        mkdir -p b
        mkdir -p c
      '';
      "a/b" = "";
      "a/c" = "";
      "b/d" = "";
      "b/e" = "";
    };
  };
}
