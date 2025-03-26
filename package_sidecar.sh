#!/usr/bin/env bash

mkdir -p sidecar_bin

echo "download the zip from gcp"
if [[ "${OS_NAME}" == "osx" ]]; then
    gsutil cp gs://sidecar-bin/latest/darwin/${VSCODE_ARCH}/sidecar.zip .
    # Now we unzip the zip binary
    echo "unzip the zip file"
    unzip ./sidecar.zip -d ./sidecar_bin
elif [[ "${OS_NAME}" == "windows" ]]; then
    gsutil cp "gs://sidecar-bin/latest/win32/${VSCODE_ARCH}/sidecar.zip" .
    # Now we unzip the zip binary
    echo "unzip the zip file"
    7z x ./sidecar.zip -osidecar_bin
else # linux
    gsutil cp gs://sidecar-bin/latest/linux/${VSCODE_ARCH}/sidecar.zip .
    # Now we unzip the zip file
    echo "unzip the zip file"
    unzip ./sidecar.zip -d ./sidecar_bin
fi

# And then remove the zip file
echo "remove the zip file"
rm -rf ./sidecar.zip

# Move the binary to the correct location
echo "copying over the binary to vscode/.build/extensions/voideditor/sidecar_bin"
mv ./sidecar_bin vscode/.build/extensions/voideditor/sidecar_bin
