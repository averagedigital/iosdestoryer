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

  public func create(_ draft: ContactDraft) throws -> ContactSummary {
    try provider.createContact(draft)
  }

  public func updatePreview(contact: ContactSummary, draft: ContactDraft) -> ContactChangePreview {
    ContactChangePreview(
      action: .update,
      contactID: contact.id,
      summary: "Update \(contact.displayLabel) to \(draft.displayLabel)",
      before: contact.displayLabel,
      after: draft.displayLabel)
  }

  public func deletePreview(contact: ContactSummary) -> ContactChangePreview {
    ContactChangePreview(
      action: .delete,
      contactID: contact.id,
      summary: "Delete \(contact.displayLabel)",
      before: contact.displayLabel,
      after: "")
  }

  public func mergePreview(contacts: [ContactSummary]) -> ContactMergePreview {
    guard let primary = contacts.first else {
      return ContactMergePreview(primaryContactID: "", mergedContact: nil, duplicateContactIDs: [])
    }

    let merged = ContactSummary(
      id: primary.id,
      givenName: primary.givenName,
      familyName: primary.familyName,
      organizationName: primary.organizationName,
      phoneNumbers: unique(contacts.flatMap(\.phoneNumbers)),
      emailAddresses: unique(contacts.flatMap(\.emailAddresses)))
    return ContactMergePreview(
      primaryContactID: primary.id,
      mergedContact: merged,
      duplicateContactIDs: contacts.dropFirst().map(\.id))
  }

  private func unique(_ values: [String]) -> [String] {
    var seen: Set<String> = []
    return values.filter { seen.insert($0.lowercased()).inserted }
  }
}

public protocol ContactProviding {
  func fetchContacts() throws -> [ContactSummary]
  func createContact(_ draft: ContactDraft) throws -> ContactSummary
}

public struct ContactDraft: Equatable, Sendable {
  public let givenName: String
  public let familyName: String
  public let organizationName: String
  public let phoneNumber: String
  public let emailAddress: String

  public init(
    givenName: String,
    familyName: String,
    organizationName: String,
    phoneNumber: String,
    emailAddress: String
  ) {
    self.givenName = givenName
    self.familyName = familyName
    self.organizationName = organizationName
    self.phoneNumber = phoneNumber
    self.emailAddress = emailAddress
  }

  fileprivate var displayLabel: String {
    [givenName, familyName, organizationName, emailAddress, phoneNumber]
      .filter { !$0.isEmpty }
      .joined(separator: " ")
  }
}

public struct ContactChangePreview: Equatable, Sendable {
  public let action: ContactChangeAction
  public let contactID: String
  public let summary: String
  public let before: String
  public let after: String
}

public enum ContactChangeAction: String, Sendable {
  case update
  case delete
}

public struct ContactMergePreview: Equatable, Sendable {
  public let primaryContactID: String
  public let mergedContact: ContactSummary?
  public let duplicateContactIDs: [String]
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

  public var displayLabel: String {
    [displayName, organizationName, emailAddresses.first ?? "", phoneNumbers.first ?? ""]
      .filter { !$0.isEmpty }
      .joined(separator: " ")
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

    public func createContact(_ draft: ContactDraft) throws -> ContactSummary {
      let contact = CNMutableContact()
      contact.givenName = draft.givenName
      contact.familyName = draft.familyName
      contact.organizationName = draft.organizationName
      if !draft.phoneNumber.isEmpty {
        contact.phoneNumbers = [
          CNLabeledValue(
            label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: draft.phoneNumber))
        ]
      }
      if !draft.emailAddress.isEmpty {
        contact.emailAddresses = [
          CNLabeledValue(label: CNLabelHome, value: draft.emailAddress as NSString)
        ]
      }

      let request = CNSaveRequest()
      request.add(contact, toContainerWithIdentifier: nil)
      try CNContactStore().execute(request)

      return ContactSummary(
        id: contact.identifier,
        givenName: contact.givenName,
        familyName: contact.familyName,
        organizationName: contact.organizationName,
        phoneNumbers: contact.phoneNumbers.map { $0.value.stringValue },
        emailAddresses: contact.emailAddresses.map { String($0.value) })
    }
  }
#else
  public struct ContactStoreProvider: ContactProviding {
    public init() {}

    public func fetchContacts() throws -> [ContactSummary] {
      []
    }

    public func createContact(_ draft: ContactDraft) throws -> ContactSummary {
      ContactSummary(
        id: UUID().uuidString,
        givenName: draft.givenName,
        familyName: draft.familyName,
        organizationName: draft.organizationName,
        phoneNumbers: draft.phoneNumber.isEmpty ? [] : [draft.phoneNumber],
        emailAddresses: draft.emailAddress.isEmpty ? [] : [draft.emailAddress])
    }
  }
#endif
