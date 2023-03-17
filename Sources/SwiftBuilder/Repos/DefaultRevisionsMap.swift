import Foundation
import RegexBuilder

// TODO: Consider outomate retriving of `updateChekcoutOutput`
struct DefaultRevisionsMap {
    init() {
        let commitMatches = updateChekcoutOutput.matches(of: revisionLineRegex)
        let tagsMatches = updateChekcoutOutput.matches(of: tagLineRegex)

        var parsedMap = [String: CheckoutRevision]()
        for match in commitMatches {
            parsedMap[match.output.1] = .commit(match.output.2)
        }
        for match in tagsMatches {
            guard match.output.2 != "skip" else {
                continue
            }
            parsedMap[match.output.1] = .tag(match.output.2)
        }
        self.parsedMap = parsedMap
    }

    subscript(_ repoName: String) -> CheckoutRevision? {
        parsedMap[repoName]
    }

    // MARK: Private

    private let parsedMap: [String: CheckoutRevision]
}

private let updateChekcoutOutput =
"""
cmake                              : skip
cmark                              : 9c8096a23f44794bde297452d87c455fc4f76d42
icu                                : release-65-1
indexstore-db                      : 9305648b0a8700434fa2e55eeacf7c7f4402a0d5
llvm-project                       : 3dade082a9b1989207a7fa7f3975868485d16a49
ninja                              : 448ae1ccacd17025457ace965d78a45a113c70c6
sourcekit-lsp                      : 849de8fbb8248623701ef614da015408ef114f1c
swift                              : 50794e1ae31a08b492cc717ead6f99e7d6932e21
swift-argument-parser              : e394bf350e38cb100b6bc4172834770ede1b7232
swift-atomics                      : 919eb1d83e02121cdb434c7bfc1f0c66ef17febe
swift-cmark                        : 9c8096a23f44794bde297452d87c455fc4f76d42
swift-collections                  : 2d33a0ea89c961dcb2b3da2157963d9c0370347e
swift-corelibs-foundation          : a87d185cecfc50086a592852bae223d5ec214cea
swift-corelibs-libdispatch         : b602cbb26c5cee1aac51021aa2cd6a30a03b1bd3
swift-corelibs-xctest              : 56501e765303ccac2f104a6e45cfcd6e733cc74e
swift-crypto                       : 0141f53dd525706c803b0c20aa8ad36f9ecd45e5
swift-docc                         : 220803435350ea9ff03902fbbc227667867224b9
swift-docc-render-artifact         : 728d974c5f479fac3fdb5ade09f4d3c3ea1a170a
swift-docc-symbolkit               : 8682202025906dce29a8b04f9263f40ba87b89d8
swift-driver                       : 719426df790661020de657bf38beb2a8b1de5ad3
swift-experimental-string-processing: 6340818cbfc85b8469c22fa8735c8337c137a7fa
swift-format                       : bd89f0d9da6256d1d23524ef0f9b5197751af013
swift-installer-scripts            : 7e916a0f3eb9d5a71a65b8b2af0d1871ca6b2eb2
swift-integration-tests            : 3156cf37ab7c307cc92bb76f2a5e8236cef7d060
swift-llbuild                      : 564424db5fdb62dcb5d863bdf7212500ef03a87b
swift-lmdb                         : 6ea45a7ebf6d8f72bd299dfcc3299e284bbb92ee
swift-markdown                     : d6cd065a7e4b6c3fad615dcd39890e095a2f63a2
swift-nio                          : 1d425b0851ffa2695d488cce1d68df2539f42500
swift-nio-ssl                      : 2e74773972bd6254c41ceeda827f229bccbf1c0f
swift-numerics                     : 0a23770641f65a4de61daf5425a37ae32a3fd00d
swift-stress-tester                : 8275f723e7167c246d95aea26c07fef13ce15486
swift-syntax                       : 9716bcb42480438a051d68c9860d9ed6cb0fbbb1
swift-system                       : 836bc4557b74fe6d2660218d56e3ce96aff76574
swift-tools-support-core           : 184eba382f6abbb362ffc02942d790ff35019ad4
swift-xcode-playground-support     : dd0d8c8d121d2f20664e4779a3d29482a55908bb
swiftpm                            : 7b898e6cad75a3c096ad947508eb948ad5f614d4
yams                               : 00c403debcd0a007b854bb35e598466207a2d58c
"""

private let repoNameRegex = Regex {
    OneOrMore(.word)
    Repeat(0...) {
        "-"
        OneOrMore(.word)
    }
}

private let revisionLineRegex = Regex {
    ZeroOrMore(.whitespace)
    Capture {
        repoNameRegex
    } transform: { v -> String in
        String(v)
    }
    OneOrMore(.whitespace)
    ": "
    Capture {
        OneOrMore(.hexDigit)
    } transform: { v -> String in
        String(v)
    }
}

private let tagLineRegex = Regex {
    ZeroOrMore(.whitespace)
    Capture {
        repoNameRegex
    } transform: { v -> String in
        String(v)
    }
    OneOrMore(.whitespace)
    ": "
    Capture {
        OneOrMore(tagRegex)
    } transform: { v -> String in
        String(v)
    }
}

private let tagRegex = #/[a-zA-Z\-0-9\._]+/#
