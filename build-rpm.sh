#!/bin/bash
MOCK_BIN=/usr/bin/mock
MOCK_CONF_FOLDER=/etc/mock
MOUNT_POINT=/rpmbuild
OUTPUT_FOLDER=$MOUNT_POINT/output
CACHE_FOLDER=$MOUNT_POINT/cache/mock
MOCK_DEFINES=($MOCK_DEFINES) # convert strings into array items
DEF_SIZE=${#MOCK_DEFINES[@]}

if [ $DEF_SIZE -gt 0 ];
then
  for ((i=0; i<$DEF_SIZE; i++));
  do
    #MOCK_DEFINES{$i}=$(echo ${MOCK_DEFINES[$i]} |sed 's/=/ /g')
    DEFINE_CMD+="--define '$(echo ${MOCK_DEFINES[$i]} |sed 's/=/ /g')' "
  done
fi

#$DEFINE_CMD=$(printf %s $DEFINE_CMD)

if [ -z "$MOCK_CONFIG" ]; then
        echo "MOCK_CONFIG is empty. Should bin one of: "
        ls -l $MOCK_CONF_FOLDER
fi
if [ ! -f "${MOCK_CONF_FOLDER}/${MOCK_CONFIG}.cfg" ]; then
        echo "MOCK_CONFIG is invalid. Should bin one of: "
        ls -l $MOCK_CONF_FOLDER
fi
if [ -z "$SOURCE_RPM" ] && [ -z "$SPEC_FILE" ]; then
        echo "You need to provide the src.rpm or spec file to build"
        echo "Set SOURCE_RPM or SPEC_FILE environment variables"
        exit 1
fi
if [ ! -z "$NO_CLEANUP" ]; then
        echo "WARNING: Disabling clean up of the build folder after build."
fi

#If proxy env variable is set, add the proxy value to the configuration file
if [ ! -z "$HTTP_PROXY" ] || [ ! -z "$http_proxy" ]; then
        TEMP_PROXY=""
        if [ ! -z "$HTTP_PROXY" ]; then
                TEMP_PROXY=$(echo $HTTP_PROXY | sed s/\\//\\\\\\//g)
        fi
        if [ ! -z "$http_proxy" ]; then
                TEMP_PROXY=$(echo $http_proxy | sed s/\\//\\\\\\//g)
        fi

        echo "Configuring http proxy to the mock build file to: $TEMP_PROXY"
        cp /etc/mock/$MOCK_CONFIG.cfg /tmp/$MOCK_CONFIG.cfg
        sed s/\\[main\\]/\[main\]\\\nproxy=$TEMP_PROXY/g /tmp/$MOCK_CONFIG.cfg > /etc/mock/$MOCK_CONFIG.cfg
fi

OUTPUT_FOLDER=${OUTPUT_FOLDER}/${MOCK_CONFIG}
if [ ! -d "$OUTPUT_FOLDER" ]; then
        mkdir -p $OUTPUT_FOLDER
else
        rm -f $OUTPUT_FOLDER/*
fi

if [ ! -d "$CACHE_FOLDER" ]; then
        mkdir -p $CACHE_FOLDER
fi

echo "=> Building parameters:"
echo "========================================================================"
echo "      MOCK_CONFIG:    $MOCK_CONFIG"
#Priority to SOURCE_RPM if both source and spec file env variable are set
if [ ! -z "$SOURCE_RPM" ]; then
        echo "      SOURCE_RPM:     $SOURCE_RPM"
        echo "      OUTPUT_FOLDER:  $OUTPUT_FOLDER"
        echo "========================================================================"
        if [ ! -z "$NO_CLEANUP" ]; then
          echo "$MOCK_BIN $DEFINE_CMD -r $MOCK_CONFIG --rebuild $MOUNT_POINT/$SOURCE_RPM --resultdir=$OUTPUT_FOLDER --no-clean" > $OUTPUT_FOLDER/script-test.sh
        else
          echo "$MOCK_BIN $DEFINE_CMD -r $MOCK_CONFIG --rebuild $MOUNT_POINT/$SOURCE_RPM --resultdir=$OUTPUT_FOLDER" > $OUTPUT_FOLDER/script-test.sh
        fi
elif [ ! -z "$SPEC_FILE" ]; then
        if [ -z "$SOURCES" ]; then
                echo "You need to specify SOURCES env variable pointing to folder or sources file (only when building with SPEC_FILE)"
                exit 1;
        fi
        echo "      SPEC_FILE:     $SPEC_FILE"
        echo "      SOURCES:       $SOURCES"
        echo "      OUTPUT_FOLDER: $OUTPUT_FOLDER"
        echo "      MOCK_DEFINES:  $MOCK_DEFINES"
        echo "========================================================================"
        if [ ! -z "$NO_CLEANUP" ]; then
          # do not cleanup chroot between both mock calls as 1st does not alter it
          echo "$MOCK_BIN $DEFINE_CMD -r $MOCK_CONFIG --buildsrpm --spec=$MOUNT_POINT/$SPEC_FILE --sources=$MOUNT_POINT/$SOURCES --resultdir=$OUTPUT_FOLDER --no-cleanup-after" > $OUTPUT_FOLDER/script-test.sh
          echo "$MOCK_BIN $DEFINE_CMD -r $MOCK_CONFIG --rebuild \$(find $OUTPUT_FOLDER -type f -name \"*.src.rpm\") --resultdir=$OUTPUT_FOLDER --no-clean" >> $OUTPUT_FOLDER/script-test.sh
        else
          echo "$MOCK_BIN $DEFINE_CMD -r $MOCK_CONFIG --buildsrpm --spec=$MOUNT_POINT/$SPEC_FILE --sources=$MOUNT_POINT/$SOURCES --resultdir=$OUTPUT_FOLDER" > $OUTPUT_FOLDER/script-test.sh
          echo "$MOCK_BIN $DEFINE_CMD -r $MOCK_CONFIG --rebuild \$(find $OUTPUT_FOLDER -type f -name \"*.src.rpm\") --resultdir=$OUTPUT_FOLDER" >> $OUTPUT_FOLDER/script-test.sh
        fi
fi

chmod 755 $OUTPUT_FOLDER/script-test.sh
$OUTPUT_FOLDER/script-test.sh

rm $OUTPUT_FOLDER/script-test.sh

echo "Build finished. Check results inside the mounted volume folder."


