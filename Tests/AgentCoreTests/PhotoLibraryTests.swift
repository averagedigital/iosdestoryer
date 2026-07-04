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

  func testCreatesAlbumAddsAssetsAndFavoritesAsset() async throws {
    let service = PhotoLibraryService(provider: StubPhotoAssetProvider(assets: sampleAssets))

    let album = try await service.createAlbum(title: "Docs")
    let result = try await service.addToAlbum(assetIDs: ["doc"], albumTitle: album.title)
    let favorite = try await service.favorite(assetID: "doc")

    XCTAssertEqual(album.title, "Docs")
    XCTAssertEqual(result.assetIDs, ["doc"])
    XCTAssertTrue(favorite.isFavorite)
  }

  func testBuildsPhotoMutationPreviews() {
    let service = PhotoLibraryService(provider: StubPhotoAssetProvider(assets: sampleAssets))

    let remove = service.removeFromAlbumPreview(assetIDs: ["doc"], albumTitle: "Docs")
    let hide = service.hidePreview(assetIDs: ["doc"])
    let delete = service.deletePreview(assetIDs: ["doc"])

    XCTAssertEqual(remove.action, .removeFromAlbum)
    XCTAssertEqual(hide.action, .hide)
    XCTAssertEqual(delete.action, .delete)
    XCTAssertEqual(delete.assetIDs, ["doc"])
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

  func createAlbum(title: String) async throws -> PhotoAlbumSummary {
    PhotoAlbumSummary(id: "album-\(title)", title: title)
  }

  func addAssets(_ assetIDs: [String], toAlbumNamed albumTitle: String) async throws
    -> PhotoAlbumMutationResult
  {
    PhotoAlbumMutationResult(albumTitle: albumTitle, assetIDs: assetIDs)
  }

  func favoriteAsset(id: String) async throws -> PhotoAssetSummary {
    guard let asset = assets.first(where: { $0.id == id }) else {
      throw PhotoLibraryError.assetNotFound(id)
    }
    return PhotoAssetSummary(
      id: asset.id,
      creationDate: asset.creationDate,
      pixelWidth: asset.pixelWidth,
      pixelHeight: asset.pixelHeight,
      isScreenshot: asset.isScreenshot,
      isFavorite: true,
      isHidden: asset.isHidden)
  }
}
