import Foundation

#if canImport(Photos)
  import Photos
#endif

public struct PhotoLibraryService {
  private let provider: any PhotoAssetProviding
  private let classifier: PhotoAssetClassifier

  public init(
    provider: any PhotoAssetProviding = PhotoKitAssetProvider(),
    classifier: PhotoAssetClassifier = PhotoAssetClassifier()
  ) {
    self.provider = provider
    self.classifier = classifier
  }

  public func listAssets(limit: Int = 50) -> [PhotoAssetSummary] {
    provider.fetchAssets(limit: max(limit, 0))
  }

  public func findScreenshots(limit: Int = 50) -> [PhotoAssetSummary] {
    listAssets(limit: limit).filter(\.isScreenshot)
  }

  public func findDocuments(limit: Int = 50) -> [PhotoAssetSummary] {
    listAssets(limit: limit).filter { classifier.classify($0).contains(.documentCandidate) }
  }

  public func findDuplicateCandidates(limit: Int = 50) -> [PhotoAssetSummary] {
    listAssets(limit: limit).filter {
      classifier.classify($0).contains(.possibleDuplicateCandidate)
    }
  }

  public func classifyCandidates(limit: Int = 50) -> [PhotoClassificationResult] {
    listAssets(limit: limit).map { asset in
      PhotoClassificationResult(asset: asset, labels: classifier.classify(asset))
    }
  }

  public func createAlbum(title: String) async throws -> PhotoAlbumSummary {
    try await provider.createAlbum(title: title)
  }

  public func addToAlbum(assetIDs: [String], albumTitle: String) async throws
    -> PhotoAlbumMutationResult
  {
    try await provider.addAssets(assetIDs, toAlbumNamed: albumTitle)
  }

  public func favorite(assetID: String) async throws -> PhotoAssetSummary {
    try await provider.favoriteAsset(id: assetID)
  }

  public func removeFromAlbumPreview(assetIDs: [String], albumTitle: String) -> PhotoChangePreview {
    PhotoChangePreview(
      action: .removeFromAlbum,
      assetIDs: assetIDs,
      summary: "Remove \(assetIDs.count) assets from \(albumTitle)")
  }

  public func hidePreview(assetIDs: [String]) -> PhotoChangePreview {
    PhotoChangePreview(
      action: .hide,
      assetIDs: assetIDs,
      summary: "Hide \(assetIDs.count) assets")
  }

  public func deletePreview(assetIDs: [String]) -> PhotoChangePreview {
    PhotoChangePreview(
      action: .delete,
      assetIDs: assetIDs,
      summary: "Delete \(assetIDs.count) assets")
  }
}

public protocol PhotoAssetProviding {
  func fetchAssets(limit: Int) -> [PhotoAssetSummary]
  func createAlbum(title: String) async throws -> PhotoAlbumSummary
  func addAssets(_ assetIDs: [String], toAlbumNamed albumTitle: String) async throws
    -> PhotoAlbumMutationResult
  func favoriteAsset(id: String) async throws -> PhotoAssetSummary
}

public struct PhotoAlbumSummary: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String

  public init(id: String, title: String) {
    self.id = id
    self.title = title
  }
}

public struct PhotoAlbumMutationResult: Equatable, Sendable {
  public let albumTitle: String
  public let assetIDs: [String]

  public init(albumTitle: String, assetIDs: [String]) {
    self.albumTitle = albumTitle
    self.assetIDs = assetIDs
  }
}

public struct PhotoChangePreview: Equatable, Sendable {
  public let action: PhotoChangeAction
  public let assetIDs: [String]
  public let summary: String

  public init(action: PhotoChangeAction, assetIDs: [String], summary: String) {
    self.action = action
    self.assetIDs = assetIDs
    self.summary = summary
  }
}

public enum PhotoChangeAction: String, Equatable, Sendable {
  case removeFromAlbum
  case hide
  case delete
}

public enum PhotoLibraryError: Error, Equatable {
  case emptyAlbumTitle
  case assetNotFound(String)
  case albumNotFound(String)
}

public struct PhotoAssetClassifier: Sendable {
  public init() {}

  public func classify(_ asset: PhotoAssetSummary) -> [PhotoCandidateLabel] {
    var labels: [PhotoCandidateLabel] = []
    if asset.isScreenshot {
      labels.append(.screenshot)
    }
    if asset.pixelWidth >= asset.pixelHeight, asset.pixelWidth > 1600, asset.pixelHeight > 900 {
      labels.append(.documentCandidate)
    }
    if asset.pixelWidth == asset.pixelHeight {
      labels.append(.possibleDuplicateCandidate)
    }
    return labels
  }
}

public struct PhotoAssetSummary: Equatable, Identifiable, Sendable {
  public let id: String
  public let creationDate: Date?
  public let pixelWidth: Int
  public let pixelHeight: Int
  public let isScreenshot: Bool
  public let isFavorite: Bool
  public let isHidden: Bool

  public init(
    id: String,
    creationDate: Date?,
    pixelWidth: Int,
    pixelHeight: Int,
    isScreenshot: Bool,
    isFavorite: Bool,
    isHidden: Bool
  ) {
    self.id = id
    self.creationDate = creationDate
    self.pixelWidth = pixelWidth
    self.pixelHeight = pixelHeight
    self.isScreenshot = isScreenshot
    self.isFavorite = isFavorite
    self.isHidden = isHidden
  }
}

public struct PhotoClassificationResult: Equatable, Sendable {
  public let asset: PhotoAssetSummary
  public let labels: [PhotoCandidateLabel]

  public init(asset: PhotoAssetSummary, labels: [PhotoCandidateLabel]) {
    self.asset = asset
    self.labels = labels
  }
}

public enum PhotoCandidateLabel: String, Equatable, Sendable {
  case screenshot
  case documentCandidate
  case possibleDuplicateCandidate
}

#if canImport(Photos)
  public struct PhotoKitAssetProvider: PhotoAssetProviding {
    public init() {}

    public func fetchAssets(limit: Int) -> [PhotoAssetSummary] {
      let options = PHFetchOptions()
      options.fetchLimit = max(limit, 0)
      options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

      let assets = PHAsset.fetchAssets(with: .image, options: options)
      var summaries: [PhotoAssetSummary] = []
      summaries.reserveCapacity(assets.count)

      assets.enumerateObjects { asset, _, _ in
        summaries.append(
          PhotoAssetSummary(
            id: asset.localIdentifier,
            creationDate: asset.creationDate,
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight,
            isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot),
            isFavorite: asset.isFavorite,
            isHidden: asset.isHidden))
      }

      return summaries
    }

    public func createAlbum(title: String) async throws -> PhotoAlbumSummary {
      let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !cleanTitle.isEmpty else { throw PhotoLibraryError.emptyAlbumTitle }

      var albumID = UUID().uuidString
      try await performChanges {
        let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
          withTitle: cleanTitle)
        albumID = request.placeholderForCreatedAssetCollection.localIdentifier
      }
      return PhotoAlbumSummary(id: albumID, title: cleanTitle)
    }

    public func addAssets(_ assetIDs: [String], toAlbumNamed albumTitle: String) async throws
      -> PhotoAlbumMutationResult
    {
      let assets = PHAsset.fetchAssets(withLocalIdentifiers: assetIDs, options: nil)
      guard assets.count == assetIDs.count else {
        throw PhotoLibraryError.assetNotFound(assetIDs.first ?? "")
      }
      guard let album = album(named: albumTitle) else {
        throw PhotoLibraryError.albumNotFound(albumTitle)
      }

      try await performChanges {
        PHAssetCollectionChangeRequest(for: album)?.addAssets(assets)
      }
      return PhotoAlbumMutationResult(albumTitle: albumTitle, assetIDs: assetIDs)
    }

    public func favoriteAsset(id: String) async throws -> PhotoAssetSummary {
      let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
      guard let asset = assets.firstObject else { throw PhotoLibraryError.assetNotFound(id) }

      try await performChanges {
        PHAssetChangeRequest(for: asset).isFavorite = true
      }
      return PhotoAssetSummary(
        id: asset.localIdentifier,
        creationDate: asset.creationDate,
        pixelWidth: asset.pixelWidth,
        pixelHeight: asset.pixelHeight,
        isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot),
        isFavorite: true,
        isHidden: asset.isHidden)
    }

    private func album(named title: String) -> PHAssetCollection? {
      let options = PHFetchOptions()
      options.predicate = NSPredicate(format: "title = %@", title)
      return PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        .firstObject
    }

    private func performChanges(_ changes: @escaping () -> Void) async throws {
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Void, Error>) in
        PHPhotoLibrary.shared().performChanges(changes) { success, error in
          if let error {
            continuation.resume(throwing: error)
          } else if success {
            continuation.resume()
          } else {
            continuation.resume(throwing: PhotoLibraryError.assetNotFound(""))
          }
        }
      }
    }
  }
#else
  public struct PhotoKitAssetProvider: PhotoAssetProviding {
    public init() {}

    public func fetchAssets(limit: Int) -> [PhotoAssetSummary] {
      []
    }

    public func createAlbum(title: String) async throws -> PhotoAlbumSummary {
      PhotoAlbumSummary(id: UUID().uuidString, title: title)
    }

    public func addAssets(_ assetIDs: [String], toAlbumNamed albumTitle: String) async throws
      -> PhotoAlbumMutationResult
    {
      PhotoAlbumMutationResult(albumTitle: albumTitle, assetIDs: assetIDs)
    }

    public func favoriteAsset(id: String) async throws -> PhotoAssetSummary {
      throw PhotoLibraryError.assetNotFound(id)
    }
  }
#endif
