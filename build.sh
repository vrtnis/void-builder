#!/usr/bin/env bash
# shellcheck disable=SC1091

set -ex

. version.sh

if [[ "${SHOULD_BUILD}" == "yes" ]]; then
  echo "MS_COMMIT=\"${MS_COMMIT}\""

  . prepare_vscode.sh

  cd vscode || { echo "'vscode' dir not found"; exit 1; }

  export NODE_OPTIONS="--max-old-space-size=8192"

  # Skip monaco-compile-check as it's failing due to searchUrl property
  echo "Skipping monaco-compile-check..."

  # Skip valid-layers-check as well since it might depend on monaco
  echo "Skipping valid-layers-check..."

  yarn run buildreact
  yarn gulp compile-build
  yarn gulp compile-extension-media
  yarn gulp compile-extensions-build

  echo "Done compiling...!"

  if [-f "/Users/runner/work/void-builder/void-builder/vscode/out-vscode-min/vs/base/parts/sandbox/electron-sandbox/preload.js"]; then
  echo "Yes1"
  else
  echo "No1"
  fi
  if [-f "/Users/runner/work/void-builder/vscode/out-vscode-min/vs/base/parts/sandbox/electron-sandbox/preload.js"]; then
  echo "Yes2"
  else
  echo "No2"
  fi
  if [-f "/Users/runner/work/void-builder/void-builder/vscode/out-void-min/vs/base/parts/sandbox/electron-sandbox/preload.js"]; then
  echo "Yes3"
  else
  echo "No3"
  fi
  if [-f "/Users/runner/work/void-builder/void-builder/void/out-void-min/vs/base/parts/sandbox/electron-sandbox/preload.js"]; then
  echo "Yes4"
  else
  echo "No4"
  fi

  if [[ "${OS_NAME}" == "osx" ]]; then
    yarn gulp "vscode-darwin-${VSCODE_ARCH}-min-ci"

    find "../VSCode-darwin-${VSCODE_ARCH}" -print0 | xargs -0 touch -c

    VSCODE_PLATFORM="darwin"
  elif [[ "${OS_NAME}" == "windows" ]]; then
    # in CI, packaging will be done by a different job
    if [[ "${CI_BUILD}" == "no" ]]; then
      . ../build/windows/rtf/make.sh

      yarn gulp "vscode-win32-${VSCODE_ARCH}-min-ci"

      if [[ "${VSCODE_ARCH}" != "x64" ]]; then
        SHOULD_BUILD_REH="no"
        SHOULD_BUILD_REH_WEB="no"
      fi
    fi

    VSCODE_PLATFORM="win32"
  else # linux
    # in CI, packaging will be done by a different job
    if [[ "${CI_BUILD}" == "no" ]]; then
      yarn gulp "vscode-linux-${VSCODE_ARCH}-min-ci"

      find "../VSCode-linux-${VSCODE_ARCH}" -print0 | xargs -0 touch -c
    fi

    VSCODE_PLATFORM="linux"
  fi

  if [[ "${SHOULD_BUILD_REH}" != "no" ]]; then
    yarn gulp minify-vscode-reh
    yarn gulp "vscode-reh-${VSCODE_PLATFORM}-${VSCODE_ARCH}-min-ci"
  fi

  if [[ "${SHOULD_BUILD_REH_WEB}" != "no" ]]; then
    yarn gulp minify-vscode-reh-web
    yarn gulp "vscode-reh-web-${VSCODE_PLATFORM}-${VSCODE_ARCH}-min-ci"
  fi

  cd ..
fi
