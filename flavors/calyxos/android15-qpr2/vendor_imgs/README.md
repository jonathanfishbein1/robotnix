# Vendor Image Metadata

This directory contains vendor image metadata extracted from Google's factory images page.

- **Branch**: android15-qpr2
- **Generated**: 2026-02-28 01:13:53 UTC
- **Source**: https://developers.google.com/android/images
- **Devices**: 4

## Usage

These JSON files are used by robotnix to pre-fetch factory images before building.
Each file contains the download URL and SHA256 checksum for the device's factory image.

## Updating

To update the metadata:
```bash
./extract-vendor-metadata.py \
  --devices panther shiba felix \
  --output-dir android15-qpr2/vendor_imgs \
  --branch android15-qpr2
```

Or for specific build IDs:
```bash
./extract-vendor-metadata.py \
  --devices panther \
  --build-ids AP3A.241105.008 \
  --output-dir android15-qpr2/vendor_imgs
```
