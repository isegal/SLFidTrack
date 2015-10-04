#!/bin/bash
cd RakNet
cmake -G Xcode -DRAKNET_ENABLE_SAMPLES=false -DRAKNET_ENABLE_DLL=false -DRAKNET_GENERATE_INCLUDE_ONLY_DIR=true
xcodebuild -project RakNet.xcodeproj -configuration Release -alltargets

