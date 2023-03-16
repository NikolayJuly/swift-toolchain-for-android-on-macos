#  How To Get Commit Hashes

- Checkout or download any revision of [swift repo](https://github.com/apple/swift/)
- Create empty folder and put swift repo there, for example to `~/ws/swift-checkout/swift-5.7-RELEASE`.
- Check file `utils/update_checkout/update-checkout-config.json`, look for `repos.branch-schemes.<release-version>`, copy needed hashes from it. 
- Replace ``updateChekcoutOutput`` from `DefaultRevisionsMap.swift` with output of `utils/update-checkout`
- Update some repo names, so they are equal to `Checkoutable.repoName`.
- Update checkout tag for swift repo itself. Search for `struct SwiftRepo`
- Some repos not not in `update-checkout-config.json`, like curl ot libxml, keep them while it is working
  
 
This process take some time, but ideally needed only once per release 


