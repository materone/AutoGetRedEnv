#!/bin/sh

#  copyfile.sh
#  autoGetRedEnv
#
#  Created by tony on 16/11/21.
#

TOOL=/Users/tony/Dev/AutoGetRedEnv/Tools
TWPATH=/Users/tony/Dev/Payload
XCFILE=/Users/tony/Dev/xcodeset

echo "Begin package WeChat RedENV App"
cp $BUILT_PRODUCTS_DIR/$EXECUTABLE_NAME $TWPATH

cd $TWPATH
rm WeChat
cp WeChat.ori WeChat

$TOOL/yololib WeChat libautoGetRedEnv.dylib

cp $XCFILE/embedded.mobileprovision $XCFILE/Entitlements.plist libautoGetRedEnv.dylib WeChat WeChat.app

codesign -f -s "iPhone Developer: XIN TAN (76DJU7N3CS)" WeChat.app/libautoGetRedEnv.dylib
codesign -f -s "iPhone Developer: XIN TAN (76DJU7N3CS)" WeChat.app/Watch/WeChatWatchNative.app/PlugIns/WeChatWatchNativeExtension.appex
codesign -f -s "iPhone Developer: XIN TAN (76DJU7N3CS)" WeChat.app/Watch/WeChatWatchNative.app
codesign -f -s "iPhone Developer: XIN TAN (76DJU7N3CS)" WeChat.app/PlugIns/WeChatShareExtensionNew.appex
codesign -f -s "iPhone Developer: XIN TAN (76DJU7N3CS)" --entitlements Entitlements.plist WeChat.app

xcrun -sdk iphoneos PackageApplication -v WeChat.app  -o ~/WeChat31.ipa
