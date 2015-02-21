#!/bin/bash

MOCK_BIN=/usr/bin/mock
MOCK_CONF_FOLDER=/etc/mock
MOUNT_POINT=/rpmbuild
OUTPUT_FOLDER=$MOUNT_POINT/output

if [ -z "$MOCK_CONFIG" ]; then
        echo "MOCK_CONFIG is empty. Should bin one of: "
	ls -l $MOCK_CONF_FOLDER
fi
if [ -z "$SOURCE_RPM" ] && [ -z "$SPEC_FILE" ]; then
        echo "You need to provide the src.rpm or spec file to build"
        echo "Set SOURCE_RPM or SPEC_FILE environment variables"
	exit 1
fi

if [ ! -d "$OUTPUT_FOLDER" ]; then
	mkdir -p $OUTPUT_FOLDER
else
	rm -f $OUTPUT_FOLDER/*
fi
echo "=> Building parameters:"
echo "========================================================================"
echo "      MOCK_CONFIG:    $MOCK_CONFIG"
#Priority to SOURCE_RPM if both source and spec file env variable are set
if [ ! -z "$SOURCE_RPM" ]; then
	echo "      SOURCE_RPM:     $SOURCE_RPM"
	echo "========================================================================"
	$MOCK_BIN -r $MOCK_CONFIG --rebuild $MOUNT_POINT/$SOURCE_RPM --resultdir=$OUTPUT_FOLDER
elif [ ! -z "$SPEC_FILE" ]; then
	if [ -z "$SOURCES" ]; then
		echo "You need to specify SOURCES env variable pointing to folder or sources file (only when building with SPEC_FILE)"
		exit 1;
	fi
	echo "      SPEC_FILE:     $SPEC_FILE"
	echo "      SOURCES:       $SOURCES"
	echo "========================================================================"
 	$MOCK_BIN -r $MOCK_CONFIG --buildsrpm --spec=$MOUNT_POINT/$SPEC_FILE --sources=$MOUNT_POINT/$SOURCES --resultdir=$OUTPUT_FOLDER 
	$MOCK_BIN -r $MOCK_CONFIG --rebuild $(find $OUTPUT_FOLDER -type f -name "*.src.rpm") --resultdir=$OUTPUT_FOLDER
fi

echo "Build finished. Check results inside the mounted volume folder."

