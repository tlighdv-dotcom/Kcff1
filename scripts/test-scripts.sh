#!/usr/bin/env bash
set -euo pipefail
for f in scripts/*.sh; do
  bash -n "$f"
done
