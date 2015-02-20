#!/bin/bash

MOCK_BIN=/usr/bin/mock
MOCK_CONF_FOLDER=/etc/mock

if [ -z "$MOCK_CONFIG" ]; then
        echo "MOCK_CONFIG is empty. Should bin one of: "
	ls -l $MOCK_CONF_FOLDER
else 
	MOCK_CONFIG=$MOCK_CONF_FOLDER/$MOCK_CONFIG
fi
if [ -z "$SOURCE_RPM" ]; then
        echo "You need to provide the src.rpm to build"
	exit 1
fi

echo "=> Building parameters:"
echo "========================================================================"
echo "      MOCK_CONFIG:    $MOCK_CONFIG"
echo "      SOURCE_RPM:     $SOURCE_RPM"
echo "========================================================================"

$MOCK_BIN  -r $MOCK_CONFIG --rebuild /rpmbuild/$SOURCE_RPM
