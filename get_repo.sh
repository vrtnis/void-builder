#!/usr/bin/env bash
# shellcheck disable=SC2129

set -e

# Echo all environment variables used by this script
echo "----------- get_repo -----------"
echo "Environment variables:"
echo "CI_BUILD=${CI_BUILD}"
echo "GITHUB_REPOSITORY=${GITHUB_REPOSITORY}"
echo "RELEASE_VERSION=${RELEASE_VERSION}"
echo "VSCODE_LATEST=${VSCODE_LATEST}"
echo "VSCODE_QUALITY=${VSCODE_QUALITY}"
echo "GITHUB_ENV=${GITHUB_ENV}"

echo "SHOULD_DEPLOY=${SHOULD_DEPLOY}"
echo "SHOULD_BUILD=${SHOULD_BUILD}"
echo "-------------------------"

# git workaround
if [[ "${CI_BUILD}" != "no" ]]; then
  git config --global --add safe.directory "/__w/$( echo "${GITHUB_REPOSITORY}" | awk '{print tolower($0)}' )"
fi

echo "Get version from ${VSCODE_QUALITY}.json"
MS_COMMIT=$( jq -r '.commit' "${VSCODE_QUALITY}.json" )
MS_TAG=$( jq -r '.tag' "${VSCODE_QUALITY}.json" )

date=$( date +%Y%j )
RELEASE_VERSION="${MS_TAG}.${date: -5}"
echo "RELEASE_VERSION=\"${RELEASE_VERSION}\""

mkdir -p vscode
cd vscode || { echo "'vscode' dir not found"; exit 1; }

git init -q
git remote add origin https://github.com/voideditor/void.git


echo "MS_COMMIT=\"${MS_COMMIT}\""
echo "MS_TAG=\"${MS_TAG}\""

git fetch --depth 1 origin "${MS_COMMIT}"
git checkout FETCH_HEAD

cd ..

# for GH actions
if [[ "${GITHUB_ENV}" ]]; then
  echo "MS_TAG=${MS_TAG}" >> "${GITHUB_ENV}"
  echo "MS_COMMIT=${MS_COMMIT}" >> "${GITHUB_ENV}"
  echo "RELEASE_VERSION=${RELEASE_VERSION}" >> "${GITHUB_ENV}"
fi

echo "----------- get_repo exports -----------"
echo "MS_TAG ${MS_TAG}"
echo "MS_COMMIT ${MS_COMMIT}"
echo "RELEASE_VERSION ${RELEASE_VERSION}"
echo "----------------------"

export MS_TAG
export MS_COMMIT
export RELEASE_VERSION
