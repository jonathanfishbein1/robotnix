# SPDX-FileCopyrightText: 2020 Daniel Fullmer and robotnix contributors
# SPDX-License-Identifier: MIT

{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    types
    ;

  cfg = config.apps.seedvault;
in
{
  options = {
    apps.seedvault = {
      enable = mkEnableOption "Seedvault (backup)";

      includedInFlavor = mkOption {
        default = false;
        type = types.bool;
        internal = true;
      };
    };
  };

  config = mkIf (cfg.enable && (!cfg.includedInFlavor)) {
    # In order to switch to using this if it's not set on the first boot, run these:
    # $ bmgr list transports
    # $ bmgr transport com.stevesoltys.seedvault.transport.ConfigurableBackupTransport

    # Set as default
    resources."frameworks/base/packages/SettingsProvider".def_backup_enabled = true;
    resources."frameworks/base/packages/SettingsProvider".def_backup_transport =
      "com.stevesoltys.seedvault.transport.ConfigurableBackupTransport";
  };
}
