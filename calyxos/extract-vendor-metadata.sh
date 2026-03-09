#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2025 robotnix contributors
# SPDX-License-Identifier: MIT
#
# Extract vendor image metadata from CalyxOS scripts repository
# This script parses the CalyxOS pixel device scripts to generate
# vendor image metadata JSON files for use with robotnix.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANCH="${1:-android15-qpr2}"
OUTPUT_DIR="${SCRIPT_DIR}/${BRANCH}/vendor_imgs"

# Temporary directory for cloning CalyxOS scripts
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Extracting vendor metadata for CalyxOS branch: ${BRANCH}"
echo "Output directory: ${OUTPUT_DIR}"

# Clone the CalyxOS scripts repository
echo "Cloning CalyxOS scripts repository..."
git clone --depth 1 --branch "${BRANCH}" \
  https://gitlab.com/CalyxOS/scripts.git \
  "${WORK_DIR}/scripts" 2>&1 | grep -v "Cloning into" || true

VARS_DIR="${WORK_DIR}/scripts/pixel/vars"

if [ ! -d "${VARS_DIR}" ]; then
  echo "ERROR: vars directory not found at ${VARS_DIR}"
  echo "Available directories in scripts/pixel:"
  ls -la "${WORK_DIR}/scripts/pixel/" || echo "  (pixel directory not found)"
  exit 1
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# List available device vars files
echo ""
echo "Found device configuration files:"
for f in "${VARS_DIR}"/*; do
  [[ "$(basename "$f")" == "pixels" ]] && continue
  basename "$f"
done || echo "  (no device files found)"
echo ""

# Function to extract and convert metadata for a device
extract_device_metadata() {
  local device="$1"
  local vars_file="${VARS_DIR}/${device}"
  local output_file="${OUTPUT_DIR}/${device}.json"

  if [ ! -f "${vars_file}" ]; then
    echo "WARNING: No vars file for device: ${device}"
    return 1
  fi

  echo "Processing ${device}..."

  # Source the vars file to get variables
  # We need to be careful here - only extract specific safe variables
  (
    # Reset variables to avoid contamination
    unset image_url image_sha256 build_id ota_url ota_sha256 needs_ota

    # Source the device vars
    # shellcheck source=/dev/null
    source "${vars_file}"

    # Validate required variables
    if [ -z "${image_url:-}" ] || [ -z "${image_sha256:-}" ]; then
      echo "  ERROR: Missing required variables (image_url or image_sha256)"
      return 1
    fi

    # Extract filename from URL
    filename=$(basename "${image_url}")

    # Generate JSON
    cat >"${output_file}" <<EOF
{
  "fileName": "${filename}",
  "url": "${image_url}",
  "sha256": "${image_sha256}",
  "build_id": "${build_id:-unknown}"
EOF

    # Add OTA information if available
    if [ "${needs_ota:-false}" = "true" ] && [ -n "${ota_url:-}" ]; then
      cat >>"${output_file}" <<EOF
,
  "ota": {
    "fileName": "$(basename "${ota_url}")",
    "url": "${ota_url}",
    "sha256": "${ota_sha256:-}"
  }
EOF
    fi

    # Close JSON
    echo "}" >>"${output_file}"

    echo "  ✓ Generated ${device}.json"
    echo "    URL: ${image_url}"
    echo "    SHA256: ${image_sha256:0:16}..."
  )
}

# Extract metadata for all devices
# Read supported devices from devices.json if it exists
if [ -f "${SCRIPT_DIR}/devices.json" ]; then
  echo "Using devices from devices.json..."
  devices=$(jq -r '.[]' "${SCRIPT_DIR}/devices.json")
else
  # Fall back to all vars files
  echo "Scanning all device vars files..."
  devices=$(find "${VARS_DIR}" -maxdepth 1 -type f ! -name "pixels" -printf '%f\n')
fi

success_count=0
fail_count=0

for device in $devices; do
  if extract_device_metadata "${device}"; then
    ((success_count++))
  else
    ((fail_count++))
  fi
done

echo ""
echo "Extraction complete!"
echo "  Success: ${success_count}"
echo "  Failed: ${fail_count}"
echo ""
echo "Metadata files created in: ${OUTPUT_DIR}"

# Create a summary file
cat >"${OUTPUT_DIR}/README.md" <<EOF
# Vendor Image Metadata

This directory contains vendor image metadata extracted from the CalyxOS scripts repository.

- **Branch**: ${BRANCH}
- **Generated**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
- **Devices**: ${success_count}

## Usage

These JSON files are used by robotnix to pre-fetch factory images before building.
Each file contains the download URL and SHA256 checksum for the device's factory image.

## Updating

To update the metadata, run:
\`\`\`bash
./extract-vendor-metadata.sh ${BRANCH}
\`\`\`
EOF

echo "Summary written to: ${OUTPUT_DIR}/README.md"
