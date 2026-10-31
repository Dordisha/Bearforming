// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "FitnessCore", platforms: [.iOS(.v17), .macOS(.v13)], products: [.library(name: "FitnessCore", targets: ["FitnessCore"])], targets: [.target(name: "FitnessCore"), .testTarget(name: "FitnessCoreTests", dependencies: ["FitnessCore"])])
