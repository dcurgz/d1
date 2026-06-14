#!/usr/bin/env bash
KEYS=/data/keys/midnight

gpg --import /run/agenix/jenkins-gpg-key || exit 1

WORKSPACE=$(pwd)

mkdir -p "$WORKSPACE/releases"

LOGS=$WORKSPACE/logs
mkdir -p $LOGS

SOURCE=$WORKSPACE/d1
rm -rf $SOURCE
git clone https://github.com/dcurgz/d1.git $SOURCE || exit 1

ls $SOURCE
cd $SOURCE
git-crypt unlock || exit 1

FLAKE=$SOURCE/nix
cd $FLAKE || exit 1

BUILD=$(nix eval .#robotnixConfigurations.midnight.config.buildDateTime)

OUT="$WORKSPACE/releases/$BUILD"
if [ -d $OUT ]; then
    echo "This version has already been built, exiting..."
    exit 0
fi

nix build .#robotnixConfigurations.midnight.img | tee "$LOGS/build_output_$BUILD.log"
BUILD_PID=$!
nix build .#robotnixConfigurations.midnight.releaseScript | tee "$LOGS/make_release_script_$BUILD.log"
BUILD_PID=$!

mkdir "$OUT"
cd "$OUT"
./release.sh $KEYS 2>&1 | tee "$LOGS/sign_output_$BUILD.log"
BUILD_PID=$!

trap "kill -- -$BUILD_PID" SIGINT SIGTERM

LINK="$WORKSPACE/releases/latest"
rm -f "$LINK"
ln -s "$OUT" "$LINK"
