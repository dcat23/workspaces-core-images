#!/bin/bash
set -euxo pipefail

if [[ -x /usr/bin/kasm-profile-sync-2 ]]; then
    /usr/bin/kasm-profile-sync-2 --help
else
    echo "skipping /usr/bin/kasm-profile-sync-2 test as it is not installed"
fi
