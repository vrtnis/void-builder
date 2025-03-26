#!/usr/bin/env bash
# shellcheck disable=SC1091

set -e

# Debug logging setup
DEBUG=${DEBUG:-false}
log_debug() {
  if [[ "${DEBUG}" == "true" ]]; then
    echo "[DEBUG] $*" >&2
  fi
}

QUALITY="stable"
COLOR="blue1"

while getopts ":i" opt; do
  case "$opt" in
    i)
      export QUALITY="insider"
      export COLOR="orange1"
      log_debug "Setting QUALITY=${QUALITY} and COLOR=${COLOR}"
      ;;
    *)
      ;;
  esac
done

check_programs() { # {{{
  log_debug "Checking for required programs: $*"
  for arg in "$@"; do
    if ! command -v "${arg}" &> /dev/null; then
      echo "${arg} could not be found"
      log_debug "Missing required program: ${arg}"
      exit 0
    fi
  done
  log_debug "All required programs found"
} # }}}

check_programs "iconutil" "composite" "convert" "icotool" "rsvg-convert" "sed"

. ./utils.sh

SRC_PREFIX=""
VSCODE_PREFIX=""

log_debug "SRC_PREFIX=${SRC_PREFIX}"
log_debug "VSCODE_PREFIX=${VSCODE_PREFIX}"

build_darwin_main() { # {{{
  log_debug "Entering build_darwin_main"
  if [[ ! -f "${SRC_PREFIX}src/${QUALITY}/resources/darwin/code.icns" ]]; then
    log_debug "Building darwin main icons"
    log_debug "Converting SVG to PNG"
    rsvg-convert -w 717 -h 717 "icons/${QUALITY}/codium_cnl.svg" -o "code_logo.png"
    if [[ $? -ne 0 ]]; then log_debug "rsvg-convert failed"; fi

    log_debug "Compositing logo"
    composite "code_logo.png" -gravity center "icons/template_macos.png" "code_1024.png"
    if [[ $? -ne 0 ]]; then log_debug "composite failed"; fi

    # Create iconset directory
    ICONSET_DIR="code.iconset"
    mkdir -p "${ICONSET_DIR}"
    log_debug "Created iconset directory: ${ICONSET_DIR}"

    # Generate all required sizes
    convert "code_1024.png" -resize 16x16 "${ICONSET_DIR}/icon_16x16.png"
    convert "code_1024.png" -resize 32x32 "${ICONSET_DIR}/icon_16x16@2x.png"
    convert "code_1024.png" -resize 32x32 "${ICONSET_DIR}/icon_32x32.png"
    convert "code_1024.png" -resize 64x64 "${ICONSET_DIR}/icon_32x32@2x.png"
    convert "code_1024.png" -resize 128x128 "${ICONSET_DIR}/icon_128x128.png"
    convert "code_1024.png" -resize 256x256 "${ICONSET_DIR}/icon_128x128@2x.png"
    convert "code_1024.png" -resize 256x256 "${ICONSET_DIR}/icon_256x256.png"
    convert "code_1024.png" -resize 512x512 "${ICONSET_DIR}/icon_256x256@2x.png"
    convert "code_1024.png" -resize 512x512 "${ICONSET_DIR}/icon_512x512.png"
    cp "code_1024.png" "${ICONSET_DIR}/icon_512x512@2x.png"

    log_debug "Creating icns file"
    iconutil --convert icns "${ICONSET_DIR}"

    log_debug "Moving icns file to target location"
    mkdir -p "$(dirname "${SRC_PREFIX}src/${QUALITY}/resources/darwin/code.icns")"
    mv "code.icns" "${SRC_PREFIX}src/${QUALITY}/resources/darwin/code.icns"

    log_debug "Cleaning up temporary files"
    rm -rf "${ICONSET_DIR}"
    rm code_1024.png code_logo.png
  else
    log_debug "Darwin main icons already exist, skipping"
  fi
  log_debug "Exiting build_darwin_main"
} # }}}

build_darwin_types() { # {{{
  log_debug "Entering build_darwin_types"
  log_debug "Converting SVG to PNG for darwin types"
  rsvg-convert -w 128 -h 128 "icons/${QUALITY}/codium_cnl_w80_b8.svg" -o "code_logo.png"

  for file in "${VSCODE_PREFIX}"resources/darwin/*; do
    if [[ -f "${file}" ]]; then
      name=$(basename "${file}" '.icns')
      log_debug "Processing file: ${file}, basename: ${name}"

      if [[ "${name}" != 'code' ]] && [[ ! -f "${SRC_PREFIX}src/${QUALITY}/resources/darwin/${name}.icns" ]]; then
        log_debug "Converting icns to png for ${name}"
        icns2png -x -s 512x512 "${file}" -o .

        log_debug "Compositing corner and logo for ${name}"
        composite -blend 100% -geometry +323+365 "icons/corner_512.png" "${name}_512x512x32.png" "${name}.png"
        composite -geometry +359+374 "code_logo.png" "${name}.png" "${name}.png"

        # Create iconset directory for this file
        ICONSET_DIR="${name}.iconset"
        mkdir -p "${ICONSET_DIR}"
        log_debug "Created iconset directory: ${ICONSET_DIR}"

        # Generate all required sizes
        convert "${name}.png" -resize 16x16 "${ICONSET_DIR}/icon_16x16.png"
        convert "${name}.png" -resize 32x32 "${ICONSET_DIR}/icon_16x16@2x.png"
        convert "${name}.png" -resize 32x32 "${ICONSET_DIR}/icon_32x32.png"
        convert "${name}.png" -resize 64x64 "${ICONSET_DIR}/icon_32x32@2x.png"
        convert "${name}.png" -resize 128x128 "${ICONSET_DIR}/icon_128x128.png"
        convert "${name}.png" -resize 256x256 "${ICONSET_DIR}/icon_128x128@2x.png"
        convert "${name}.png" -resize 256x256 "${ICONSET_DIR}/icon_256x256.png"
        convert "${name}.png" -resize 512x512 "${ICONSET_DIR}/icon_256x256@2x.png"
        convert "${name}.png" -resize 512x512 "${ICONSET_DIR}/icon_512x512.png"
        cp "${name}.png" "${ICONSET_DIR}/icon_512x512@2x.png"

        log_debug "Creating icns file using iconutil"
        mkdir -p "$(dirname "${SRC_PREFIX}src/${QUALITY}/resources/darwin/${name}.icns")"
        iconutil --convert icns "${ICONSET_DIR}" --output "${SRC_PREFIX}src/${QUALITY}/resources/darwin/${name}.icns"

        log_debug "Cleaning up temporary files for ${name}"
        rm -rf "${ICONSET_DIR}"
        rm "${name}_512x512x32.png" "${name}.png"
      else
        log_debug "Skipping ${name} - already exists or is 'code'"
      fi
    fi
  done

  log_debug "Cleaning up code_logo.png"
  rm "code_logo.png"
  log_debug "Exiting build_darwin_types"
} # }}}

build_linux_main() { # {{{
  if [[ ! -f "${SRC_PREFIX}src/${QUALITY}/resources/linux/code.png" ]]; then
    wget "https://raw.githubusercontent.com/VSCodium/icons/main/icons/linux/circle1/${COLOR}/paulo22s.png" -O "${SRC_PREFIX}src/${QUALITY}/resources/linux/code.png"
  fi

  mkdir -p "${SRC_PREFIX}src/${QUALITY}/resources/linux/rpm"

  if [[ ! -f "${SRC_PREFIX}src/${QUALITY}/resources/linux/rpm/code.xpm" ]]; then
    convert "${SRC_PREFIX}src/${QUALITY}/resources/linux/code.png" "${SRC_PREFIX}src/${QUALITY}/resources/linux/rpm/code.xpm"
  fi
} # }}}

build_media() { # {{{
  if [[ ! -f "${SRC_PREFIX}src/${QUALITY}/src/vs/workbench/browser/media/code-icon.svg" ]]; then
    cp "icons/${QUALITY}/codium_clt.svg" "${SRC_PREFIX}src/${QUALITY}/src/vs/workbench/browser/media/code-icon.svg"
    gsed -i 's|width="100" height="100"|width="1024" height="1024"|' "${SRC_PREFIX}src/${QUALITY}/src/vs/workbench/browser/media/code-icon.svg"
  fi
} # }}}

build_windows_main() { # {{{
  if [[ ! -f "${SRC_PREFIX}src/${QUALITY}/resources/win32/code.ico" ]]; then
    wget "https://raw.githubusercontent.com/VSCodium/icons/main/icons/win32/nobg/${COLOR}/paulo22s.ico" -O "${SRC_PREFIX}src/${QUALITY}/resources/win32/code.ico"
  fi
} # }}}

build_windows_type() {
  local FILE_PATH IMG_SIZE IMG_BG_COLOR LOGO_SIZE GRAVITY

  FILE_PATH="$1"
  IMG_SIZE="$2"
  IMG_BG_COLOR="$3"
  LOGO_SIZE="$4"
  GRAVITY="$5"

  log_debug "Processing windows type icon: ${FILE_PATH}"
  log_debug "Parameters - Size: ${IMG_SIZE}, Background: ${IMG_BG_COLOR}, Logo size: ${LOGO_SIZE}, Gravity: ${GRAVITY}"

  if [[ ! -f "${FILE_PATH}" ]]; then
    log_debug "Creating base image for ${FILE_PATH}"
    if [[ "${FILE_PATH##*.}" == "png" ]]; then
      log_debug "Creating PNG format image"
      convert -size "${IMG_SIZE}" "${IMG_BG_COLOR}" PNG32:"${FILE_PATH}"
    else
      log_debug "Creating non-PNG format image"
      convert -size "${IMG_SIZE}" "${IMG_BG_COLOR}" "${FILE_PATH}"
    fi

    log_debug "Converting SVG logo to PNG"
    rsvg-convert -w "${LOGO_SIZE}" -h "${LOGO_SIZE}" "icons/${QUALITY}/codium_cnl.svg" -o "code_logo.png"

    log_debug "Compositing logo with gravity: ${GRAVITY}"
    if [[ "${GRAVITY}" =~ ^\+[0-9]+\+[0-9]+$ ]]; then
      log_debug "Using geometry-based composition"
      composite -geometry "${GRAVITY}" "code_logo.png" "${FILE_PATH}" "${FILE_PATH}"
    else
      log_debug "Using gravity-based composition"
      composite -gravity "${GRAVITY}" "code_logo.png" "${FILE_PATH}" "${FILE_PATH}"
    fi
  else
    log_debug "File ${FILE_PATH} already exists, skipping"
  fi
}

build_windows_types() { # {{{
  log_debug "Entering build_windows_types"

  log_debug "Creating directory structure for win32 resources"
  mkdir -p "${SRC_PREFIX}src/${QUALITY}/resources/win32"

  log_debug "Converting SVG logo for windows types"
  rsvg-convert -b "#F5F6F7" -w 64 -h 64 "icons/${QUALITY}/codium_cnl.svg" -o "code_logo.png"

  for file in "${VSCODE_PREFIX}"vscode/resources/win32/*.ico; do
    if [[ -f "${file}" ]]; then
      name=$(basename "${file}" '.ico')
      log_debug "Processing icon file: ${file}, basename: ${name}"

      if [[ "${name}" != 'code' ]] && [[ ! -f "${SRC_PREFIX}src/${QUALITY}/resources/win32/${name}.ico" ]]; then
        log_debug "Extracting 256px image from ${name}.ico"
        icotool -x -w 256 "${file}"

        log_debug "Compositing logo for ${name}"
        composite -geometry +150+185 "code_logo.png" "${name}_9_256x256x32.png" "${name}.png"

        log_debug "Creating multi-size ico file for ${name}"
        convert "${name}.png" -define icon:auto-resize=256,128,96,64,48,32,24,20,16 "${SRC_PREFIX}src/${QUALITY}/resources/win32/${name}.ico"

        log_debug "Cleaning up temporary files for ${name}"
        rm "${name}_9_256x256x32.png" "${name}.png"
      else
        log_debug "Skipping ${name} - already exists or is 'code'"
      fi
    fi
  done

  log_debug "Processing Windows specific image types"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/code_70x70.png" "70x70" "canvas:transparent" "45" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/code_150x150.png" "150x150" "canvas:transparent" "64" "+44+25"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-big-100.bmp" "164x314" "xc:white" "126" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-big-125.bmp" "192x386" "xc:white" "147" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-big-150.bmp" "246x459" "xc:white" "190" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-big-175.bmp" "273x556" "xc:white" "211" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-big-200.bmp" "328x604" "xc:white" "255" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-big-225.bmp" "355x700" "xc:white" "273" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-big-250.bmp" "410x797" "xc:white" "317" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-small-100.bmp" "55x55" "xc:white" "44" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-small-125.bmp" "64x68" "xc:white" "52" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-small-150.bmp" "83x80" "xc:white" "63" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-small-175.bmp" "92x97" "xc:white" "76" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-small-200.bmp" "110x106" "xc:white" "86" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-small-225.bmp" "119x123" "xc:white" "103" "center"
  build_windows_type "${SRC_PREFIX}src/${QUALITY}/resources/win32/inno-small-250.bmp" "138x140" "xc:white" "116" "center"
  build_windows_type "${SRC_PREFIX}build/windows/msi/resources/${QUALITY}/wix-banner.bmp" "493x58" "xc:white" "50" "+438+6"
  build_windows_type "${SRC_PREFIX}build/windows/msi/resources/${QUALITY}/wix-dialog.bmp" "493x312" "xc:white" "120" "+22+152"

  log_debug "Cleaning up code_logo.png"
  rm code_logo.png
  log_debug "Exiting build_windows_types"
} # }}}

if [[ "${0}" == "${BASH_SOURCE[0]}" ]]; then
  log_debug "Starting main execution"
  build_darwin_main
  build_linux_main
  build_windows_main

  build_darwin_types
  build_windows_types

  build_media
  log_debug "Completed main execution"
fi
