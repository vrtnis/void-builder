#!/usr/bin/env bash

set -ex

CALLER_DIR=$( pwd )

cd "$( dirname "${BASH_SOURCE[0]}" )"

if [[ "${VSCODE_ARCH}" == "x64" ]]; then
  GITHUB_RESPONSE=$( curl --silent --location "https://api.github.com/repos/AppImage/pkg2appimage/releases/latest" )
  APPIMAGE_URL=$( echo "${GITHUB_RESPONSE}" | jq --raw-output '.assets | map(select( .name | test("x86_64.AppImage(?!.zsync)"))) | map(.browser_download_url)[0]' )

  if [[ -z "${APPIMAGE_URL}" ]]; then
    echo "The url for pkg2appimage.AppImage hasn't been found"
    exit 1
  fi

  wget -c "${APPIMAGE_URL}" -O pkg2appimage.AppImage

  chmod +x ./pkg2appimage.AppImage

  ./pkg2appimage.AppImage --appimage-extract && mv ./squashfs-root ./pkg2appimage.AppDir

  # add update's url
  # Void - this line is important - ask GPT about it
  sed -i 's/generate_type2_appimage/generate_type2_appimage -u "gh-releases-zsync|voideditor|binaries|latest|*.AppImage.zsync"/' pkg2appimage.AppDir/AppRun

  # remove check so build in docker can succeed
  sed -i 's/grep docker/# grep docker/' pkg2appimage.AppDir/usr/share/pkg2appimage/functions.sh

  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i 's|@@NAME@@|Void-Insiders|g' recipe.yml
    sed -i 's|@@APPNAME@@|void-insiders|g' recipe.yml
    sed -i 's|@@ICON@@|void-insiders|g' recipe.yml
  else
    # Void branding instead of default codium
    sed -i 's|@@NAME@@|Void|g' recipe.yml
    sed -i 's|@@APPNAME@@|void|g' recipe.yml
    sed -i 's|@@ICON@@|void|g' recipe.yml
  fi

  # workaround that enforces x86 ARCH for pkg2appimage having /__w/vscodium/vscodium/build/linux/appimage/VSCodium/VSCodium.AppDir/usr/share/codium/resources/app/node_modules/rc/index.js is of architecture armhf
  export ARCH=x86_64
  bash -ex pkg2appimage.AppDir/AppRun recipe.yml

  rm -f pkg2appimage-*.AppImage
  rm -rf pkg2appimage.AppDir
  rm -rf Void* # Void had this commented out at one point
fi

cd "${CALLER_DIR}"
