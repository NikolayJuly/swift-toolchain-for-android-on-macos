# swift-toolchain-for-android-on-macos

Swift toolchain for android on macos

## Prerequisites
- You are on arm64 mac
- Install NDK and CMake. (Instructions)[https://developer.android.com/studio/projects/install-ndk]

## Execute
```
$ swift run SwiftBuilder \
  --working-folder <WORKING_FOLDER> \
  --cmake-path <PATH_TO_CMAKE_BINARY> \
  --ndk-path <PATH_TO_NDK_V25>
```
For example, values might be
WORKING_FOLDER - `~/ws/SwiftAndroid`, this should be empty folder, which will be used by app for checkout and build
PATH_TO_CMAKE_BINARY - `~/Library/Android/sdk/cmake/3.22.1/bin`
PATH_TO_NDK_V25 - `~/Library/Android/sdk/ndk/25.1.8937393`

While building, we will save progress with completed steps in `current-progress.json`. 
This helps us avoid re-running long build operations, if we encountered any problem
If you want start from scratch - just delete this file from working folder. Alternatively, you can manually remove steps, which you want to repeat


## How to update code fore new release

1. Find new release tag in (github repo)[https://github.com/apple/swift.git]
2. Follow steps [here](./Sources/SwiftBuilder/Repos/HowToGetCommitHashes.md) to update default checkout hashes
3. Consider changing `CMAKE_OSX_DEPLOYMENT_TARGET`
4. Execute and fix issue by issue...
