import Foundation

#if canImport(Contacts)
  import Contacts
#endif

public struct ContactLibraryService {
  private let provider: any ContactProviding

  public init(provider: any ContactProviding = ContactStoreProvider()) {
    self.provider = provider
  }

  public func listContacts() throws -> [ContactSummary] {
    try provider.fetchContacts()
  }

  public func search(_ query: String) throws -> [ContactSummary] {
    let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !needle.isEmpty else { return [] }

    return try listContacts().filter { contact in
      contact.searchText.contains(needle)
    }
  }

  public func findDuplicateCandidates() throws -> [ContactSummary] {
    let contacts = try listContacts()
    let duplicateEmails = duplicateValues(contacts.flatMap(\.emailAddresses))
    let duplicatePhones = duplicateValues(contacts.flatMap(\.phoneNumbers))

    return contacts.filter { contact in
      !duplicateEmails.isDisjoint(with: contact.emailAddresses.map { $0.lowercased() })
        || !duplicatePhones.isDisjoint(with: contact.phoneNumbers.map { $0.lowercased() })
    }
  }

  private func duplicateValues(_ values: [String]) -> Set<String> {
    var seen: Set<String> = []
    var duplicates: Set<String> = []
    for value in values.map({ $0.lowercased() }) where !value.isEmpty {
      if !seen.insert(value).inserted {
        duplicates.insert(value)
      }
    }
    return duplicates
  }
}

public protocol ContactProviding {
  func fetchContacts() throws -> [ContactSummary]
}

public struct ContactSummary: Equatable, Identifiable, Sendable {
  public let id: String
  public let givenName: String
  public let familyName: String
  public let organizationName: String
  public let phoneNumbers: [String]
  public let emailAddresses: [String]

  public init(
    id: String,
    givenName: String,
    familyName: String,
    organizationName: String,
    phoneNumbers: [String],
    emailAddresses: [String]
  ) {
    self.id = id
    self.givenName = givenName
    self.familyName = familyName
    self.organizationName = organizationName
    self.phoneNumbers = phoneNumbers
    self.emailAddresses = emailAddresses
  }

  public var displayName: String {
    [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
  }

  fileprivate var searchText: String {
    ([givenName, familyName, organizationName] + phoneNumbers + emailAddresses)
      .joined(separator: " ")
      .lowercased()
  }
}

#if canImport(Contacts)
  public struct ContactStoreProvider: ContactProviding {
    public init() {}

    public func fetchContacts() throws -> [ContactSummary] {
      let keys =
        [
          CNContactIdentifierKey,
          CNContactGivenNameKey,
          CNContactFamilyNameKey,
          CNContactOrganizationNameKey,
          CNContactPhoneNumbersKey,
          CNContactEmailAddressesKey,
        ] as [CNKeyDescriptor]
      let request = CNContactFetchRequest(keysToFetch: keys)
      var contacts: [ContactSummary] = []

      try CNContactStore().enumerateContacts(with: request) { contact, _ in
        contacts.append(
          ContactSummary(
            id: contact.identifier,
            givenName: contact.givenName,
            familyName: contact.familyName,
            organizationName: contact.organizationName,
            phoneNumbers: contact.phoneNumbers.map { $0.value.stringValue },
            emailAddresses: contact.emailAddresses.map { String($0.value) }))
      }

      return contacts
    }
  }
#else
  public struct ContactStoreProvider: ContactProviding {
    public init() {}

    public func fetchContacts() throws -> [ContactSummary] {
      []
    }
  }
#endif
