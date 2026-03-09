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
    mkIf
    mkDefault
    mkEnableOption
    ;

  versions = {
    release = "v0.3.7.250932"; # The GH release name and git tag
    GmsCore = {
      buildNumber = "250932014"; # The build number of the artefact in the release
      hash = "sha256-Lab6aUY013YkLS5onAzev9bbDdzeFSp8O8IWIasKpoI=";
    };
    FakeStore = {
      buildNumber = "84022614"; # The build number of the artefact in the release
      hash = "sha256-bNbPFG7L2pDNMTRpLzbbrq7F0uqVgONFPqWZIJ9nhFA=";
    };
  };

  verifyApk =
    apk:
    pkgs.robotnix.verifyApk {
      inherit apk;
      sha256 = "9bd06727e62796c0130eb6dab39b73157451582cbd138e86c468acc395d14165"; # O=NOGAPPS Project, C=DE
    };
in
{
  options = {
    microg.enable = mkEnableOption "MicroG";

    # TODO: Add support for spoofing device profiles. See: https://github.com/microg/GmsCore/releases/tag/v0.2.23.214816
  };

  config = mkIf config.microg.enable {

    resources."frameworks/base/packages/SettingsProvider".def_location_providers_allowed = mkIf (
      config.androidVersion == 9
    ) (mkDefault "gps,network");

    # Using cloud messaging, so enabling: https://source.android.com/devices/tech/power/platform_mgmt#integrate-doze
    resources."frameworks/base/core/res".config_enableAutoPowerModes = mkDefault true;

    # TODO: Preferably build this stuff ourself.
    # Used https://github.com/lineageos4microg/android_prebuilts_prebuiltapks as source for Android.mk options
    apps.prebuilt =
      let
        certificate = "microg";
      in
      {
        GmsCore = {
          apk = verifyApk (
            pkgs.fetchurl {
              url = "https://github.com/microg/GmsCore/releases/download/${versions.release}/com.google.android.gms-${versions.GmsCore.buildNumber}.apk";
              inherit (versions.GmsCore) hash;
            }
          );
          packageName = "com.google.android.gms";
          privileged = true;
          privappPermissions = [
            "FAKE_PACKAGE_SIGNATURE"
            "INSTALL_LOCATION_PROVIDER"
            "CHANGE_DEVICE_IDLE_TEMP_WHITELIST"
            "UPDATE_APP_OPS_STATS"
            "MANAGE_USB"

            # New with v0.2.28.231657
            "LOCATION_HARDWARE"
            "MODIFY_PHONE_STATE"
            "NETWORK_SCAN"
            "UPDATE_DEVICE_STATS"
            "WATCH_APPOPS"

            # New with v0.2.29.233013
            "RECEIVE_SMS"

            # New with v0.3.1.240913
            "START_ACTIVITIES_FROM_BACKGROUND"

            "INTERACT_ACROSS_USERS"
          ];
          defaultPermissions = [ "FAKE_PACKAGE_SIGNATURE" ];
          usesLibraries = [ "com.android.location.provider" ];
          usesOptionalLibraries = [
            "org.apache.http.legacy"
            "androidx.window.extensions"
            "androidx.window.sidecar"
          ];
          allowInPowerSave = true;
          inherit certificate;
        };

        GsfProxy = {
          apk = verifyApk (
            pkgs.fetchurl {
              url = "https://github.com/microg/android_packages_apps_GsfProxy/releases/download/v0.1.0/GsfProxy.apk";
              sha256 = "14ln6i1qg435x223x3vndd608mra19d58yqqhhf6mw018cbip2c6";
            }
          );
          certificate = "microg";
        };

        FakeStore = {
          apk = verifyApk (
            pkgs.fetchurl {
              url = "https://github.com/microg/GmsCore/releases/download/${versions.release}/com.android.vending-${versions.FakeStore.buildNumber}.apk";
              inherit (versions.FakeStore) hash;
            }
          );
          packageName = "com.android.vending";
          privileged = true;
          privappPermissions = [
            "FAKE_PACKAGE_SIGNATURE"
            "CHECK_LICENSE"
            "DELETE_PACKAGES"
            "INTERACT_ACROSS_USERS"
            "INSTALL_PACKAGES"
          ];
          defaultPermissions = [ "FAKE_PACKAGE_SIGNATURE" ];
          usesOptionalLibraries = [
            "androidx.window.extensions"
            "androidx.window.sidecar"
          ];
          inherit certificate;
        };
      };
  };
}
