// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let libmpvTargets = [
    "Ass",
    "Avcodec",
    "Avfilter",
    "Avformat",
    "Avutil",
    "Dav1d",
    "Freetype",
    "Fribidi",
    "Harfbuzz",
    "Mbedcrypto",
    "Mbedtls",
    "Mbedx509",
    "Mpv",
    "Png16",
    "Swresample",
    "Swscale",
    "Uchardet",
    "Xml2"
]

let libmpvArtifactBase = "https://github.com/Predidit/libmpv-darwin-build/releases/download/0.6.8/libmpv-xcframeworks_0.6.8_ios-universal-video-default"
let libmpvChecksums = [
    "Ass": "96751f9b3536a2dc031f4abefc3f2e52b1440ade80a969446b024abb1dafe8bf",
    "Avcodec": "e8067adfbbf9108c9ca70b3b2ceee496e82e3037181c8b65473cf92ec0a6883a",
    "Avfilter": "82ea8041f831214eadb5aac8c40be8829a6af1c534287efdabecfe63f38120ab",
    "Avformat": "7140cd2595e46d9e8fe4a4a8f0bc15982ea5b328733f844c66ff3a4f84237b6b",
    "Avutil": "ed7abc0497fdb4eedd18b376a7889fd5e6d26588b1b6beda584c5b4be2afbe07",
    "Dav1d": "78038b49a493d71a5a0a20ea98c4875340276c88d3295349c92cfc93d8ca8e22",
    "Freetype": "aa2efdfd84d6ecf40e2db9730914e03242a48dbda4f38a6a3721dff032a74a13",
    "Fribidi": "92d15100178db3258d860390c852b9d910bc8723f09db5d5078050b1a8a5d732",
    "Harfbuzz": "b9bd9c8a2d7dec742ba74b639441fc5b6ccc37024907c70b2eccda3f6f8517da",
    "Mbedcrypto": "c130c48401361b2ac3d404bc1afe721c4832f16dcbbaa5c65644e294843a9eb1",
    "Mbedtls": "c13f8649684ec7d7997c6638acc4d310a754db96845e7c1078e6cdf20b6b72d3",
    "Mbedx509": "5fb5214fe3fff44a159c64dd33c0087cac9f4d934c37e136a72f99646b348d2e",
    "Mpv": "443ae3d64e13c68cac18b7c611e82959f030d3d622709df4540c0bee9282dc8b",
    "Png16": "0106717d37931e1dcc312c98db47a10afb47b4eeb93d14ef6c3e497aa6797a23",
    "Swresample": "6c753d91bb4caa717b070d015aba700d86f943b910707b1f9fed50437cfb96aa",
    "Swscale": "75ffa8ecd9e75aac37e9181dbeaccd68883996cef869f2b7a2dec3aca47a22fc",
    "Uchardet": "b9d133c2c41dc5399cba002d6c3d2b8dbc04b643309f4b291dd0c123d84fd4f0",
    "Xml2": "642635c6172c55c622948cbb194ae61381822d5a2526238b21bc8204c04d05db"
]
let libmpvProductTargets: [String] = ["media_kit_libs_ios_video"] + libmpvTargets

let package = Package(
    name: "media_kit_libs_ios_video",
    platforms: [
        .iOS("9.0")
    ],
    products: [
        .library(name: "media-kit-libs-ios-video", targets: libmpvProductTargets),
        .library(name: "Mpv", targets: ["Mpv"])
    ],
    dependencies: [],
    targets: libmpvTargets.map { framework in
        .binaryTarget(
            name: framework,
            url: "\(libmpvArtifactBase)_\(framework).zip",
            checksum: libmpvChecksums[framework]!
        )
    } + [
        .target(
            name: "media_kit_libs_ios_video",
            dependencies: libmpvTargets.map { framework in .target(name: framework) },
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
