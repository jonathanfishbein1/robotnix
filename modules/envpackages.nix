# SPDX-FileCopyrightText: 2020 Daniel Fullmer and robotnix contributors
# SPDX-License-Identifier: MIT

{ pkgs, ... }:

{
  # Check build/soong/ui/build/paths/config.go for a list of things that are needed
  envPackages = with pkgs; [
    bc
    git
    gnumake
    jre8_headless
    lsof
    m4
    ncurses5
    libxcrypt-legacy
    openssl # Used in avbtool
    psmisc # for "fuser", "pstree"
    rsync
    unzip
    zip
    util-linux # for `chrt`

    # Things not in build/soong/ui/build/paths/config.go
    nettools # Needed for "hostname" in build/soong/ui/build/sandbox_linux.go
    procps # Needed for "ps" in build/envsetup.sh

    freetype # Needed by jdk9 prebuilt
    fontconfig
    python3
  ];
}
