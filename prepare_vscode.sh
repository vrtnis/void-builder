#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

# include common functions
. ./utils.sh

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  cp -rp src/insider/* vscode/
else
  cp -rp src/stable/* vscode/
fi

cp -f LICENSE vscode/LICENSE.txt

cd vscode || { echo "'vscode' dir not found"; exit 1; }

../update_settings.sh

# apply patches
{ set +x; } 2>/dev/null

for file in ../patches/*.patch; do
  if [[ -f "${file}" ]]; then
    echo applying patch: "${file}";
    # grep '^+++' "${file}"  | sed -e 's#+++ [ab]/#./vscode/#' | while read line; do shasum -a 256 "${line}"; done
    if ! git apply --ignore-whitespace "${file}"; then
      echo failed to apply patch "${file}" >&2
      exit 1
    fi
  fi
done

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  for file in ../patches/insider/*.patch; do
    if [[ -f "${file}" ]]; then
      echo applying patch: "${file}";
      if ! git apply --ignore-whitespace "${file}"; then
        echo failed to apply patch "${file}" >&2
        exit 1
      fi
    fi
  done
fi

for file in ../patches/user/*.patch; do
  if [[ -f "${file}" ]]; then
    echo applying user patch: "${file}";
    if ! git apply --ignore-whitespace "${file}"; then
      echo failed to apply patch "${file}" >&2
      exit 1
    fi
  fi
done

if [[ -d "../patches/${OS_NAME}/" ]]; then
  for file in "../patches/${OS_NAME}/"*.patch; do
    if [[ -f "${file}" ]]; then
      echo applying patch: "${file}";
      if ! git apply --ignore-whitespace "${file}"; then
        echo failed to apply patch "${file}" >&2
        exit 1
      fi
    fi
  done
fi

set -x

export ELECTRON_SKIP_BINARY_DOWNLOAD=1
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

if [[ "${OS_NAME}" == "linux" ]]; then
  export VSCODE_SKIP_NODE_VERSION_CHECK=1

   if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
elif [[ "${OS_NAME}" == "windows" ]]; then
  if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
fi

for i in {1..5}; do # try 5 times
  npm ci && break
  if [[ $i == 3 ]]; then
    echo "Npm install failed too many times" >&2
    exit 1
  fi
  echo "Npm install failed $i, trying again..."

  sleep $(( 15 * (i + 1)))
done

setpath() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --arg 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath_json() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --argjson 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

# product.json
cp product.json{,.bak}

setpath "product" "checksumFailMoreInfoUrl" "https://go.microsoft.com/fwlink/?LinkId=828886"
setpath "product" "documentationUrl" "https://docs.aide.dev"
setpath_json "product" "extensionsGallery" '{"serviceUrl": "https://open-vsx.org/vscode/gallery", "itemUrl": "https://open-vsx.org/vscode/item"}'
setpath "product" "introductoryVideosUrl" "https://go.microsoft.com/fwlink/?linkid=832146"
setpath "product" "keyboardShortcutsUrlLinux" "https://go.microsoft.com/fwlink/?linkid=832144"
setpath "product" "keyboardShortcutsUrlMac" "https://go.microsoft.com/fwlink/?linkid=832143"
setpath "product" "keyboardShortcutsUrlWin" "https://go.microsoft.com/fwlink/?linkid=832145"
setpath "product" "licenseUrl" "https://github.com/codestoryai/aide/blob/cs-main/LICENSE.md"
setpath_json "product" "linkProtectionTrustedDomains" '["https://open-vsx.org"]'
setpath "product" "releaseNotesUrl" "https://go.microsoft.com/fwlink/?LinkID=533483#vscode"
setpath "product" "reportIssueUrl" "https://github.com/codestoryai/aide/issues/new"
setpath "product" "requestFeatureUrl" "https://github.com/codestoryai/aide/issues/new"
setpath "product" "tipsAndTricksUrl" "https://go.microsoft.com/fwlink/?linkid=852118"
setpath "product" "twitterUrl" "https://x.com/aide_dev"

if [[ "${DISABLE_UPDATE}" != "yes" ]]; then
  setpath "product" "updateUrl" "https://raw.githubusercontent.com/codestoryai/versions/refs/heads/main"
  setpath "product" "downloadUrl" "https://github.com/codestoryai/binaries/releases"
fi

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "product" "nameShort" "Aide - Insiders"
  setpath "product" "nameLong" "Aide - Insiders"
  setpath "product" "applicationName" "aide-insiders"
  setpath "product" "dataFolderName" ".aide-insiders"
  setpath "product" "linuxIconName" "aide-insiders"
  setpath "product" "quality" "insider"
  setpath "product" "urlProtocol" "aide-insiders"
  setpath "product" "serverApplicationName" "aide-server-insiders"
  setpath "product" "serverDataFolderName" ".aide-server-insiders"
  setpath "product" "darwinBundleIdentifier" "ai.codestory.AideInsiders"
  setpath "product" "win32AppUserModelId" "Aide.AideInsiders"
  setpath "product" "win32DirName" "Aide Insiders"
  setpath "product" "win32MutexName" "aideinsiders"
  setpath "product" "win32NameVersion" "Aide Insiders"
  setpath "product" "win32RegValueName" "AideInsiders"
  setpath "product" "win32ShellNameShort" "Aide Insiders"
  setpath "product" "win32AppId" "{{5893CE20-77AA-4856-A655-ECE65CBCF1C7}"
  setpath "product" "win32x64AppId" "{{7A261980-5847-44B6-B554-31DF0F5CDFC9}"
  setpath "product" "win32arm64AppId" "{{EE4FF7AA-A874-419D-BAE0-168C9DBCE211}"
  setpath "product" "win32UserAppId" "{{FA3AE0C7-888E-45DA-AB58-B8E33DE0CB2E}"
  setpath "product" "win32x64UserAppId" "{{5B1813E3-1D97-4E00-AF59-C59A39CF066A}"
  setpath "product" "win32arm64UserAppId" "{{C2FA90D8-B265-41B1-B909-3BAEB21CAA9D}"
else
  setpath "product" "nameShort" "Aide"
  setpath "product" "nameLong" "Aide"
  setpath "product" "applicationName" "aide"
  setpath "product" "dataFolderName" ".aide"
  setpath "product" "linuxIconName" "aide"
  setpath "product" "quality" "stable"
  setpath "product" "urlProtocol" "aide"
  setpath "product" "serverApplicationName" "aide-server"
  setpath "product" "serverDataFolderName" ".aide-server"
  setpath "product" "darwinBundleIdentifier" "ai.codestory.Aide"
  setpath "product" "win32AppUserModelId" "Aide.Aide"
  setpath "product" "win32DirName" "Aide"
  setpath "product" "win32MutexName" "aide"
  setpath "product" "win32NameVersion" "Aide"
  setpath "product" "win32RegValueName" "Aide"
  setpath "product" "win32ShellNameShort" "Aide"
  setpath "product" "win32AppId" "{{E9E8C1CE-81FA-4BA0-BDD9-C8C682F44BBC}"
  setpath "product" "win32x64AppId" "{{B7106564-0459-4799-AE5B-F9B10C9E401E}"
  setpath "product" "win32arm64AppId" "{{2FB9B2B9-703E-4F52-B157-241A9326FC81}"
  setpath "product" "win32UserAppId" "{{5493D6BE-C20A-4D40-B22F-E7D7ED48E4D8}"
  setpath "product" "win32x64UserAppId" "{{D14DBE6B-F111-4E33-AA3A-CEFA1854EC5A}"
  setpath "product" "win32arm64UserAppId" "{{134C4C10-FE90-4DED-9198-9066C11905E5}"
fi

jsonTmp=$( jq -s '.[0] * .[1]' product.json ../product.json )
echo "${jsonTmp}" > product.json && unset jsonTmp

cat product.json

# package.json
cp package.json{,.bak}

setpath "package" "version" "$( echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\1/p" )"
setpath "package" "release" "$( echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\2/p" )"

replace 's|Microsoft Corporation|Aide|' package.json

# announcements
replace "s|\\[\\/\\* BUILTIN_ANNOUNCEMENTS \\*\\/\\]|$( tr -d '\n' < ../announcements-builtin.json )|" src/vs/workbench/contrib/welcomeGettingStarted/browser/gettingStarted.ts

../undo_telemetry.sh

replace 's|Microsoft Corporation|Aide|' build/lib/electron.js
replace 's|Microsoft Corporation|Aide|' build/lib/electron.ts
replace 's|([0-9]) Microsoft|\1 Aide|' build/lib/electron.js
replace 's|([0-9]) Microsoft|\1 Aide|' build/lib/electron.ts

if [[ "${OS_NAME}" == "linux" ]]; then
  # microsoft adds their apt repo to sources
  # unless the app name is code-oss
  # as we are renaming the application to aide
  # we need to edit a line in the post install template
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i "s/code-oss/aide-insiders/" resources/linux/debian/postinst.template
  else
    sed -i "s/code-oss/aide/" resources/linux/debian/postinst.template
  fi

  # fix the packages metadata
  # code.appdata.xml
  sed -i 's|Visual Studio Code|Aide|g' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://docs.aide.dev|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/home/home-screenshot-linux-lg.png|https://vscodium.com/img/vscodium.png|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com|https://aide.dev|' resources/linux/code.appdata.xml

  # control.template
  sed -i 's|Microsoft Corporation <vscode-linux@microsoft.com>|Aide Team <team@codestory.ai>|'  resources/linux/debian/control.template
  sed -i 's|Visual Studio Code|Aide|g' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://docs.aide.dev|' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com|https://aide.dev|' resources/linux/debian/control.template

  # code.spec.template
  sed -i 's|Microsoft Corporation|Aide Team|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code Team <vscode-linux@microsoft.com>|Aide Team <team@codestory.ai>|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code|Aide|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://docs.aide.dev|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com|https://aide.dev|' resources/linux/rpm/code.spec.template

  # snapcraft.yaml
  sed -i 's|Visual Studio Code|Aide|'  resources/linux/rpm/code.spec.template
elif [[ "${OS_NAME}" == "windows" ]]; then
  # code.iss
  sed -i 's|https://code.visualstudio.com|https://aide.dev|' build/win32/code.iss
  sed -i 's|Microsoft Corporation|Aide|' build/win32/code.iss
fi

cd ..
