#!/bin/sh
echo "Appsee - Starting debug symbols upload..."

APIKEY="$1"
APIURL="https://api.appsee.com/crashes/upload-symbols"

# Check given APIKey
if [ ! "${APIKEY}" ]; then
    echo "Appsee - Please provide your API Key"
    echo "Appsee - Usage: ./upload_symbols.sh APIKEY"
    exit 1
fi

# Skip simulator build
if [ "$EFFECTIVE_PLATFORM_NAME" == "-iphonesimulator" ]; then
    echo "Appsee - Ignoring Simulator build"
    exit 0
fi

# Skip simulator build
if [ "$CONFIGURATION" != "Release" ]; then
    echo "Appsee - Ignoring Debug build"
    exit 0
fi

DSYM_PATH=${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
ZIP_DIR="/tmp/Appsee"
ZIP_PATH="${ZIP_DIR}/$DWARF_DSYM_FILE_NAME.zip"

# Check if zip directory available
if [ ! -d "$ZIP_DIR" ]; then
    mkdir "${ZIP_DIR}"
fi

# Check if dSym available
if [ ! -d "$DSYM_PATH" ]; then
    echo "Appsee - dSYM file not found on: ${DSYM_PATH}. Please contact support@appsee.com for assistance"
    exit 1
fi

# Zip dSYM
cd ${DWARF_DSYM_FOLDER_PATH}
/usr/bin/zip -D -r -q  "${ZIP_PATH}" "${DWARF_DSYM_FILE_NAME}"

if [ $? -ne 0 ]; then
    echo "Appsee - dSYM zip failed. Please contact support@appsee.com for assistance"
    exit 1
fi

# Upload dSYM
RES=$(curl "${APIURL}?APIKey=${APIKEY}" --write-out %{http_code} --silent --output /dev/null -F dsym=@"${ZIP_PATH}")
if [ $RES -ne 200 ]; then
    echo "Appsee - Upload failed with status $RES. Please contact support@appsee.com for assistance"
    exit 1
fi

# Remove Zip file
/bin/rm -f "${ZIP_PATH}"

echo "Appsee - Debug symbols uploaded successfully"