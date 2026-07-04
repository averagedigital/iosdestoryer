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
}

public protocol PhotoAssetProviding {
  func fetchAssets(limit: Int) -> [PhotoAssetSummary]
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
  }
#else
  public struct PhotoKitAssetProvider: PhotoAssetProviding {
    public init() {}

    public func fetchAssets(limit: Int) -> [PhotoAssetSummary] {
      []
    }
  }
#endif
