#!/usr/bin/env bash
set -euo pipefail

# Cached HTML and open tabs can still reference hashed assets from earlier builds.
rsync -a --checksum --delete --exclude=.git --filter='P /assets/***' "${1%/}/" "${2%/}/"
