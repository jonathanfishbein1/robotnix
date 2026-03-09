{ lib }:

lib.listToAttrs (
  builtins.map (c: lib.nameValuePair c.device c) [
    # { device="crosshatch"; }
    # { device="blueline";   }
    # { device="bonito";     }
    # { device="sargo";      }
  ]
)
