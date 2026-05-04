#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

if [[ "${DISTRO}" == "alpine" ]]; then
    apk add --no-cache \
        runuser \
        xhost
elif [ "${DISTRO}" == "opensuse" ]; then
    if grep -q "15\." /etc/os-release; then
        zypper ar -cfp 90 'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_$releasever/' packman
        zypper -n --gpg-auto-import-keys dup --from packman --allow-vendor-change
    fi
    zypper install -ny xhost
fi

COMMIT_ID="7c153608953b4c04ba84c7cd396ba7c991c9d48c"
BRANCH="feature_KASM-8210_bump_dep_versions_for_1_19_0"
COMMIT_ID_SHORT=$(echo "${COMMIT_ID}" | cut -c1-6)

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')

mkdir -p $STARTUPDIR/recorder
wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_recorder_service/${COMMIT_ID}/kasm_recorder_service_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz | tar -xvz -C $STARTUPDIR/recorder/
echo "${BRANCH}:${COMMIT_ID}" > $STARTUPDIR/recorder/kasm_recorder_service.version
