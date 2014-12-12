#!/bin/bash
# 

unzip "$BITRISE_IPA_PATH" > /dev/null

BASE_NAME=${BITRISE_IPA_PATH##*/}
APP_NAME=${BASE_NAME%.*}

BUNDLEID=`/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ./Payload/"$APP_NAME".app/Info.plist`
BUNDLEVER=`/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" ./Payload/"$APP_NAME".app/Info.plist`
BUNDLESHORTVER=`/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" ./Payload/"$APP_NAME".app/Info.plist`

# PARSE_APPLICATION_ID=parseappid
# PARSE_REST_API_KEY=parseapikey
# S3_DEPLOY_STEP_EMAIL_READY_URL=s3test
# VERSION_CHANNEL=production
# BUNDLEID=com.ideo.bundle_identifier
# BUNDLESHORTVER=1.0.3
# BUNDLEVER=1012

curl -v -i -X POST \
  -H "X-Parse-Application-Id: ${PARSE_APPLICATION_ID}" \
  -H "X-Parse-REST-API-Key: ${PARSE_REST_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
        "install_url": "'${S3_DEPLOY_STEP_EMAIL_READY_URL}'",
        "version_channel": "'${VERSION_CHANNEL}'",
        "bundle_identifier": "'${BUNDLEID}'",
        "version_number": "'${BUNDLESHORTVER}'",
        "build_number": "'${BUNDLEVER}'"
    }' \
  https://api.parse.com/1/functions/buildServerUpdate