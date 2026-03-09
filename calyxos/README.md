# CalyxOS

This directory contains the Robotnix flavor module for [CalyxOS](https://calyxos.org/), a privacy-focused Android distribution.

## ⚠️ Current Status

**Functional (Testing Required)** - The CalyxOS flavor integration includes source fetching, build configuration, and vendor blob pre-fetching infrastructure. Builds may succeed for devices with generated vendor metadata.

### What Works
- ✅ Source manifest fetching (lockfiles)
- ✅ CalyxOS-specific build environment configuration
- ✅ `breakfast` command integration
- ✅ Default apps configuration (Seedvault, Updater)
- ✅ microG and APEX signing enabled
- ✅ **Vendor blob pre-fetching** - Factory images fetched before build
- ✅ **Metadata extraction tool** - Automated vendor metadata generation
- ✅ **Factory image integration** - Pre-fetched images available to build

### What Needs Testing
- ⚠️ **End-to-end build** - Full build process not yet verified
- ⚠️ **Vendor blob extraction** - CalyxOS device.sh script integration
- ⚠️ **Build ID accuracy** - Verify correct factory images for each branch

See the "Building" section above for usage instructions.

## About CalyxOS

CalyxOS is an Android mobile operating system that prioritizes privacy and security. It includes:
- microG for Google services compatibility
- Seedvault for encrypted backups
- Datura firewall
- Enhanced privacy features
- Regular security updates

## Supported Devices

CalyxOS supports a variety of devices including:
- Google Pixel phones (Pixel 5 through Pixel 9 series)
- Fairphone devices (FP4, FP5)
- Motorola phones (moto g series)

See [devices.json](./devices.json) for the complete list of device codenames.

## Configuration

### Basic Configuration

```nix
{
  flavor = "calyxos";
  device = "shiba";  # Pixel 8
  calyxos.branch = "android15-qpr2";  # CalyxOS branch to build
  calyxos.release = "6.10.20";  # Optional: specific release version
}
```

### Branch Options

Available branches (as of 2025):
- `android15-qpr2` (default) - Android 15 QPR2
- `android15` - Android 15
- `android14` - Android 14

## Building

### Prerequisites

Before building, you need to generate vendor image metadata for your device:

```bash
cd flavors/calyxos

# Extract metadata for your device(s)
./extract-vendor-metadata.py \
  --devices panther shiba felix \
  --output-dir android15-qpr2/vendor_imgs \
  --branch android15-qpr2
```

This creates JSON files with factory image URLs and checksums that robotnix will use to pre-fetch vendor blobs.

### Build Command

To build CalyxOS with Robotnix:

```bash
nix-build --arg configuration '{
  flavor = "calyxos";
  device = "panther";  # or shiba, felix, etc.
  calyxos.branch = "android15-qpr2";
}' -A img
```

The build will:
1. Pre-fetch the factory image using the metadata
2. Extract vendor blobs before the build
3. Build CalyxOS with the vendor files included

## Updating Lockfiles

To update the CalyxOS source lockfiles:

```bash
cd flavors/calyxos
./update.sh
```

This will fetch the latest source manifests from the CalyxOS GitLab repository and update the `repo.lock` files for each tracked branch.

## Source Repository

CalyxOS source code: https://gitlab.com/CalyxOS/platform_manifest

## Documentation

- [CalyxOS Build Documentation](https://calyxos.org/docs/development/build/)
- [CalyxOS Device Support](https://calyxos.org/install/)
- [CalyxOS Website](https://calyxos.org/)

## Notes

- CalyxOS includes microG by default for Google services compatibility
- Seedvault backup is included
- APEX signing is enabled
- **All Pixel devices require vendor blobs (proprietary files)**

## Contributing

### Completing Vendor Blob Support

The main missing piece is vendor blob pre-fetching infrastructure. CalyxOS uses a device script (`./calyx/scripts/pixel/device.sh`) that downloads factory images during the build, but this conflicts with Nix's sandboxed build model.

**What's needed:**

1. **Create vendor image metadata files** (similar to GrapheneOS)
   - For each CalyxOS release (e.g., `android15-qpr2/`)
   - Include device-specific metadata: factory image URLs, SHA256 checksums, build IDs
   - Format: JSON files listing the required factory images

2. **Implement vendor blob pre-fetching**
   - Use `pkgs.fetchurl` to download factory images before the build
   - Extract vendor blobs using appropriate tools (e.g., adevtool or CalyxOS scripts)
   - Make extracted blobs available in the build environment

3. **Update the build process**
   - Replace the current device script call with pre-fetched vendor blob integration
   - Ensure vendor makefiles are generated correctly

**Reference implementations:**
- See `flavors/grapheneos/default.nix` for adevtool integration example
- See `modules/adevtool/default.nix` for vendor blob infrastructure

### Current Implementation Details

The CalyxOS flavor currently:
- Uses `breakfast` command (like LineageOS) instead of `lunch`
- Calls `./calyx/scripts/pixel/device.sh` during build (fails due to network isolation)
- Includes `curl` in build environment (for future use)

**Files modified:**
- `default.nix` - Added CalyxOS to flavor imports
- `modules/base.nix` - Added CalyxOS to breakfast condition and device script call
- `flavors/calyxos/*` - New CalyxOS flavor module
