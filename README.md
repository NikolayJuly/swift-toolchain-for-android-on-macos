# swift-toolchain-for-android-on-macos

Swift toolchain for android on macos

## Prerequisites
- You are on arm64 mac
- Recent xcode vetsion installed on mac
- Install NDK and CMake. [Instructions](https://developer.android.com/studio/projects/install-ndk)

## Execute
```
$ swift run SwiftBuilder \
  --working-folder <WORKING_FOLDER> \
  --android-sdk <PATH_TO_ANDROID_SDK>
  --source-root "$PWD"
```
For example, values might be:
- WORKING_FOLDER - `~/ws/SwiftAndroid`, this should be empty folder, which will be used by app for checkout and build
- PATH_TO_ANDROID_SDK - `~/Library/Android/sdk/`, inside we expect ndk fodler with NDK v25

To modify some constants:
- NDK version in `HostConfig/NDK.swift`
- Android API level in `AndroidConfig/AndroidAPILevel.swift`
- To change macOS target, like arch or min deployment target - check `HostConfig/MacOS.swift` 

While building, we will save progress with completed steps in `current-progress.json`. 
This helps us avoid re-running long build operations, if we encountered any problem.
If you want start from scratch - just delete file from working folder. Alternatively, you can manually remove steps, which you want to repeat.


## How to update code for a new release

1. Find new release tag in [github repo](https://github.com/apple/swift.git)
2. Follow steps [here](./Sources/SwiftBuilder/Repos/HowToGetCommitHashes.md) to update default checkout hashes
3. Consider changing `CMAKE_OSX_DEPLOYMENT_TARGET`
4. Execute and fix issue by issue...
