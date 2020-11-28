#!/usr/bin/env bash

# $1 = <BASE_GH_USERNAME>/<GH_REPO>"
#   Example: "purescript-contrib/purescript-now"

# See https://wizardzines.com/comics/bash-errors/
set -euo pipefail

BASE_GH_USERNAME=$(echo $1 | cut -d'/' -f1)
GH_REPO=$(echo $1 | cut -d'/' -f2)

# Your GitHub username
YOUR_GH_USERNAME=JordanMartinez

# PureScript-Contrib libraries use `main` as their default branch
CHECKED_OUT_BRANCH=main

# The current release candidate
PS_TAG=v0.14.0-rc3

# go up one level
cd ..

# Fork the repo using GitHub's CLI tool and `git clone` it.
gh repo fork $BASE_GH_USERNAME/$GH_REPO --clone=true --remote=true

# change into that just cloned repo
cd $GH_REPO

# Checkout a new branch based on the current `main` branch
# using the upstream repo in case we've done work on this repo before
# in our own fork
git checkout -b updateTo14 upstream/$CHECKED_OUT_BRANCH

# Overwrite `packages.dhall` with the `prepare-0.14` version
#   To understand the below syntax, see
#     https://linuxize.com/post/bash-heredoc/
cat <<"EOF" > packages.dhall
let upstream =
      https://raw.githubusercontent.com/JordanMartinez/package-sets/updateContribLibs/prepare-0.14-packages.dhall

in  upstream
EOF

# Either add a dependency on `purescript-psa` or update it to v0.8.0
# to ensure any compiler warnings count as errors when compiling the repo's code
#   To understand JQ's syntax, see its man page
#   To understand why we need to create a temporary file, see
#     https://stackoverflow.com/questions/36565295/jq-to-replace-text-directly-on-file-like-sed-i
jq 'setpath(["devDependencies", "purescript-psa"]; "v0.8.0")' package.json > package.json.tmp && mv package.json.tmp package.json

# TODO: figure out how to update CI to pull in the v0.14.0-rc3 PS release

# Add these files and commit them to our branch
git add packages.dhall package.json
git commit -m "Update packages.dhall to prepare-0.14 bootstrap"
git add package.json
git commit -m "Add or update dev dependency on psa to v0.8.0"

echo <<EOF
Remaining Steps:
1. Run './compileSpago.sh $GH_REPO'
2. Navigate into 'purescript-$GH_REPO' via 'pushd ../purescript-$GH_REPO' (use 'popd' to return to this folder)
3. Open the below URL to see whether repo has any pre-existing PRs and/or issues
     https://github.com/purescript-contrib/purescript-$GH_REPO
4. Do all changes needed (breaking, fix warnings, add kind signatures, etc.)
5. Run './createPRSpago.sh $GH_REPO'
EOF