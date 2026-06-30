#!/usr/bin/env bash
MAX_CORES=20

set -x
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
fi

nix build .#robotnixConfigurations.midnight.releaseScript \
    --out-link release.sh \
    --max-jobs 4 \
    --cores $MAX_CORES \
    || exit 1
BUILD_PID=$!

mkdir "$OUT"
cp -rv $FLAKE/release.sh $OUT || exit 1
cd "$OUT" || exit 1

./release.sh $KEYS || exit 1
BUILD_PID=$!

trap "kill -- -$BUILD_PID" SIGINT SIGTERM

cd "$WORKSPACE/releases"
ln -nsf $OUT release
mv -T release latest
