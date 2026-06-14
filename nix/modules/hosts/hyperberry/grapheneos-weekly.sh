#!/usr/bin/env bash
KEYS=/data/keys/midnight
LOGS=./logs
mkdir $LOGS

gpg --import /run/agenix/jenkins-gpg-key || exit 1

SOURCE=./d1
git clone https://github.com/dcurgz/d1.git $SOURCE || exit 1

FLAKE=$SOURCE/nix
cd $FLAKE || exit 1

BUILD=$(nix eval .#robotnixConfigurations.midnight.config.buildDateTime)

make midnight 2>&1 | tee $LOGS/build_output_$(BUILD).log
make midnight-release 2>&1 | tee $LOGS/make_release_script_$(BUILD).log
./release.sh $KEYS 2>&1 | tee $LOGS/sign_output_$(BUILD).log
