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

let libmpvArtifactBase = "https://github.com/Predidit/libmpv-darwin-build/releases/download/0.6.8/libmpv-xcframeworks_0.6.8_macos-universal-video-default"
let libmpvChecksums = [
    "Ass": "349cc791690222de522ccfc54a6cf6cf67221834a33f53e7beef947f6375e106",
    "Avcodec": "a15bd6d4d30e63f9c6d194aad4988db1baf5504075c1774c70bd55bcc138eed3",
    "Avfilter": "0f86101192d6a79e5f77350287010aec38bd116ff45599acf57f27e24377ba7f",
    "Avformat": "c9050b13121ec7f8a7b4edd65e2c9d11563dadfb534581685878f6bbe2ef09c0",
    "Avutil": "8d3c7e560c14e013718e614a516333bf1158d8fb0bd6781463bb6d7d556fa0f3",
    "Dav1d": "b9336c02f641539fbe8012764ad002d3038ee632fbeacd7b4be23e18b5c282a1",
    "Freetype": "ea4204874ad7993c4ff0a04c258768e70c0349bc722f335be5e2187b1750dbc3",
    "Fribidi": "a42fcb59cb12a11469a6e201cab3ba60fb7c216455cb34ff30bb18ce5c1a8be9",
    "Harfbuzz": "0e50fb9dedd625215725234c637cde497717dae4b7837e3a599ac6997e6a19a4",
    "Mbedcrypto": "f0349d5180f1b84c2093e64ffa9fadce1d5076e0129ddbca3a4e71b800849467",
    "Mbedtls": "2bceb6e9577be7eff37f2603420836f15590b01759f6b2cd5b0e39473f5d1f91",
    "Mbedx509": "8bec77448cf12c5ad9a6faae8e063a1c1b420ec5adb71f29f4a5f8418bd8423b",
    "Mpv": "9d3c36df1eede452a3cc8ce9fcdc6989fbb4e87649165f32a505e319c502984a",
    "Png16": "db4a5ba9618c4342694431b83fdc7b2fcb705daf2f28377f28567c7d4d6653d9",
    "Swresample": "b83a71df4e9e76098448863e01a3f0d77e7fd7fd78ad4d3720fd0c41401d31dc",
    "Swscale": "0cd0e34e02048259cd2c4697f3879b01780927fc9ae373224450e5197ceaf85c",
    "Uchardet": "cfa014837d33f03a0d96a0f7563e0f269201a7a56cdc415e61e584314388a1ae",
    "Xml2": "d2af8a9a85cb061907127d26904b1060e4c22d9c1a91f0eaa8b294fe352c5e4c"
]
let libmpvProductTargets: [String] = ["media_kit_libs_macos_video"] + libmpvTargets

let package = Package(
    name: "media_kit_libs_macos_video",
    platforms: [
        .macOS("10.9")
    ],
    products: [
        .library(name: "media-kit-libs-macos-video", targets: libmpvProductTargets),
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
            name: "media_kit_libs_macos_video",
            dependencies: libmpvTargets.map { framework in .target(name: framework) },
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
