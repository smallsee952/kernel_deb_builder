#!/usr/bin/env bash

# Extract kernel version from config file
VERSION=$(awk '/Kernel Configuration/ {print $3}' config)

# Add deb-src to sources.list
sed -i '/deb-src/s/^# //' /etc/apt/sources.list

# Install dependencies
apt update && apt full-upgrade -y
apt install -y wget xz-utils make gcc flex bison dpkg-dev bc rsync kmod cpio libssl-dev git lsb-release

# Change to workspace directory
cd "${GITHUB_WORKSPACE}" || exit

# Download kernel source
wget "http://www.kernel.org/pub/linux/kernel/v6.x/linux-${VERSION}.tar.xz" && tar -xf "linux-${VERSION}.tar.xz"
cd "linux-${VERSION}" || exit

# Copy config file
cp ../config .config

# Disable DEBUG_INFO to speed up build
make mrproper && scripts/config --disable DEBUG_INFO

# Apply patches (uncomment if needed)
# for patch in ../patch.d/*.sh; do source "$patch"; done

# Build deb packages
CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))
make deb-pkg -j"${CPU_CORES}"

# Move deb packages to artifact dir
cd ..
mkdir -p artifact
mv ./*.deb artifact/
rm -rfv *dbg*.deb
