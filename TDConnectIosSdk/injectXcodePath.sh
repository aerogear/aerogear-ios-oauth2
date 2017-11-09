#!/bin/sh
sed -i '' s#{xcodepath}#`xcode-select -p`# TDConnectIosSdk/TDConnectIosSdk.modulemap
