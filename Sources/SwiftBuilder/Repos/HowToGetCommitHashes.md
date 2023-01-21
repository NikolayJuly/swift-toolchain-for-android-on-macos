#  How To Get Commit Hashes

- Checkout or download any revision of [swift repo](https://github.com/apple/swift/)
- Create empty folder and put swift repo there, for example to `~/ws/swift-checkout/swift-5.7-RELEASE`.
- `$ cd ~/ws/swift-checkout/swift-5.7-RELEASE && utils/update-checkout --clone-with-ssh --tag swift-5.7-RELEASE`. It will checkout all needed repos. In the end you will get output with all revisions. Replace `swift-swift-5.7-RELEASE` with needed release tag.
- Replace ``updateChekcoutOutput`` from `DefaultRevisionsMap.swift` with output of `utils/update-checkout`
- Update some repo names, so they are equal to `Checkoutable.repoName`.
- Update checkout tag for swift repo itself. Search for `struct SwiftRepo`
  
 
This process take some time, but ideally needed only once per release 


