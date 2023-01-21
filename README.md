# swift-toolchain-for-android-on-macos

Swift toolchain for android on macos

## Prerequisites
- Install NDK and CMake. (Instructions)[https://developer.android.com/studio/projects/install-ndk]

## Execute
```
$ swift run SwiftBuilder --working-folder <WORKING_FOLDER> --cmake-path <PATH_TO_CMAKE_BINARY>
```
For example, values might be
WORKING_FOLDER - `~/ws/SwiftAndroid`
PATH_TO_CMAKE_BINARY - `~/Library/Android/sdk/cmake/3.22.1/bin`


## How to update code fore new release

1. Find new release tag in (github repo)[https://github.com/apple/swift.git]
2. Follow steps [here](./Sources/SwiftBuilder/Repos/HowToGetCommitHashes.md) to update default checkout hashes
3. Execute and fix issue by issue...
