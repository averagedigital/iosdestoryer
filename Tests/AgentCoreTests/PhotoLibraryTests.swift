import XCTest

@testable import AgentCore

final class PhotoLibraryTests: XCTestCase {
  func testListsAssetsFromProviderWithLimit() {
    let service = PhotoLibraryService(provider: StubPhotoAssetProvider(assets: sampleAssets))

    XCTAssertEqual(service.listAssets(limit: 2).map(\.id), ["screen", "doc"])
  }

  func testFindsScreenshots() {
    let service = PhotoLibraryService(provider: StubPhotoAssetProvider(assets: sampleAssets))

    XCTAssertEqual(service.findScreenshots().map(\.id), ["screen"])
  }

  func testClassifiesDocumentAndDuplicateCandidates() {
    let service = PhotoLibraryService(provider: StubPhotoAssetProvider(assets: sampleAssets))

    let labelsByID = Dictionary(
      uniqueKeysWithValues: service.classifyCandidates().map { ($0.asset.id, $0.labels) })

    XCTAssertEqual(labelsByID["screen"], [.screenshot, .documentCandidate])
    XCTAssertEqual(labelsByID["doc"], [.documentCandidate])
    XCTAssertEqual(labelsByID["square"], [.possibleDuplicateCandidate])
  }

  func testFindsDocumentCandidates() {
    let service = PhotoLibraryService(provider: StubPhotoAssetProvider(assets: sampleAssets))

    XCTAssertEqual(service.findDocuments().map(\.id), ["screen", "doc"])
  }

  func testFindsDuplicateCandidates() {
    let service = PhotoLibraryService(provider: StubPhotoAssetProvider(assets: sampleAssets))

    XCTAssertEqual(service.findDuplicateCandidates().map(\.id), ["square"])
  }
}

private let sampleAssets = [
  PhotoAssetSummary(
    id: "screen", creationDate: nil, pixelWidth: 2532, pixelHeight: 1170,
    isScreenshot: true, isFavorite: false, isHidden: false),
  PhotoAssetSummary(
    id: "doc", creationDate: nil, pixelWidth: 2400, pixelHeight: 1200,
    isScreenshot: false, isFavorite: false, isHidden: false),
  PhotoAssetSummary(
    id: "square", creationDate: nil, pixelWidth: 1024, pixelHeight: 1024,
    isScreenshot: false, isFavorite: false, isHidden: false),
]

private struct StubPhotoAssetProvider: PhotoAssetProviding {
  let assets: [PhotoAssetSummary]

  func fetchAssets(limit: Int) -> [PhotoAssetSummary] {
    Array(assets.prefix(limit))
  }
}
