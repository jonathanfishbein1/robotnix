#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2025 robotnix contributors
# SPDX-License-Identifier: MIT
#
# Extract vendor image metadata from Google's factory images page
# Generates JSON files for robotnix to use with fetchurl

import argparse
import json
import os
import sys
import urllib.request
from bs4 import BeautifulSoup

IMAGE_URL = "https://developers.google.com/android/images"
OTA_URL = "https://developers.google.com/android/ota"
COOKIE = {"Cookie": "devsite_wall_acks=nexus-image-tos,nexus-ota-tos"}


def extract_device_metadata(soup, device, build_id=None):
    """
    Extract factory image metadata for a specific device.
    If build_id is None, gets the latest build for the device.
    """
    # Find all rows for this device
    device_rows = soup.find_all("tr", id=lambda x: x and x.startswith(device))

    if not device_rows:
        print(f"WARNING: No factory images found for device: {device}", file=sys.stderr)
        return None

    # If build_id specified, find that specific build, otherwise use first (latest)
    target_row = None
    if build_id:
        for row in device_rows:
            if build_id.lower() in row.get("id", "").lower():
                target_row = row
                break
    else:
        target_row = device_rows[0]

    if not target_row:
        print(
            f"WARNING: Build {build_id} not found for device {device}", file=sys.stderr
        )
        return None

    # Extract data from table cells
    cells = target_row.find_all("td")
    if len(cells) < 4:
        print(f"ERROR: Invalid table structure for {device}", file=sys.stderr)
        return None

    # Cell 0: Version info (text only)
    # Cell 1: Flash/Download link
    # Cell 2: Factory image link
    # Cell 3: SHA-256 checksum

    image_link = cells[2].find("a")
    checksum_text = cells[3].get_text(strip=True)

    if not image_link or not image_link.get("href"):
        print(f"ERROR: No factory image link found for {device}", file=sys.stderr)
        return None

    image_url = image_link["href"]
    image_sha256 = checksum_text

    # Extract filename from URL
    filename = image_url.split("/")[-1].split("?")[0]

    # Extract build ID from the row ID or filename
    row_id = target_row.get("id", "")
    extracted_build_id = row_id.replace(device, "").upper() if row_id else "unknown"

    metadata = {
        "fileName": filename,
        "url": image_url,
        "sha256": image_sha256,
        "build_id": extracted_build_id,
    }

    return metadata


def main():
    parser = argparse.ArgumentParser(
        description="Extract vendor image metadata from Google factory images page"
    )
    parser.add_argument(
        "--devices",
        nargs="+",
        required=True,
        help="Device codenames (e.g., panther shiba)",
    )
    parser.add_argument(
        "--build-ids",
        nargs="+",
        help="Specific build IDs (optional, uses latest if not specified)",
    )
    parser.add_argument(
        "--output-dir", required=True, help="Output directory for JSON files"
    )
    parser.add_argument(
        "--branch",
        default="android15-qpr2",
        help="CalyxOS branch name (for documentation)",
    )

    args = parser.parse_args()

    # Validate arguments
    if args.build_ids and len(args.build_ids) != len(args.devices):
        print(
            "ERROR: If build-ids is specified, must match number of devices",
            file=sys.stderr,
        )
        sys.exit(1)

    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)

    # Fetch factory images page
    print(f"Fetching factory images from {IMAGE_URL}...")
    try:
        request = urllib.request.Request(IMAGE_URL, headers=COOKIE)
        html = urllib.request.urlopen(request).read()
        soup = BeautifulSoup(html, "html.parser")
    except Exception as e:
        print(f"ERROR: Failed to fetch factory images page: {e}", file=sys.stderr)
        sys.exit(1)

    # Process each device
    success_count = 0
    fail_count = 0

    for i, device in enumerate(args.devices):
        build_id = args.build_ids[i] if args.build_ids else None

        print(
            f"\nProcessing {device}"
            + (f" (build {build_id})" if build_id else " (latest)")
            + "..."
        )

        metadata = extract_device_metadata(soup, device, build_id)

        if metadata:
            output_file = os.path.join(args.output_dir, f"{device}.json")
            with open(output_file, "w") as f:
                json.dump(metadata, f, indent=2)

            print(f"  ✓ Generated {device}.json")
            print(f"    Build: {metadata['build_id']}")
            print(f"    URL: {metadata['url']}")
            print(f"    SHA256: {metadata['sha256'][:16]}...")
            success_count += 1
        else:
            print(f"  ✗ Failed to extract metadata for {device}")
            fail_count += 1

    # Create README
    readme_path = os.path.join(args.output_dir, "README.md")
    with open(readme_path, "w") as f:
        f.write(f"""# Vendor Image Metadata

This directory contains vendor image metadata extracted from Google's factory images page.

- **Branch**: {args.branch}
- **Generated**: {os.popen('date -u +"%Y-%m-%d %H:%M:%S UTC"').read().strip()}
- **Source**: {IMAGE_URL}
- **Devices**: {success_count}

## Usage

These JSON files are used by robotnix to pre-fetch factory images before building.
Each file contains the download URL and SHA256 checksum for the device's factory image.

## Updating

To update the metadata:
```bash
./extract-vendor-metadata.py \\
  --devices panther shiba felix \\
  --output-dir {args.branch}/vendor_imgs \\
  --branch {args.branch}
```

Or for specific build IDs:
```bash
./extract-vendor-metadata.py \\
  --devices panther \\
  --build-ids AP3A.241105.008 \\
  --output-dir {args.branch}/vendor_imgs
```
""")

    print(f"\n{'=' * 60}")
    print("Extraction complete!")
    print(f"  Success: {success_count}")
    print(f"  Failed: {fail_count}")
    print(f"  Output: {args.output_dir}")
    print(f"{'=' * 60}\n")


if __name__ == "__main__":
    main()
