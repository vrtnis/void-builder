#!/bin/sh

# Check if upstream remote exists
if ! git remote | grep -q 'upstream'; then
    git remote add upstream https://github.com/VSCodium/vscodium
    git remote set-url --push upstream DISABLE
    echo "Upstream remote added!"
else
    echo "Upstream remote already exists."
fi