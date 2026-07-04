import XCTest

@testable import AgentCore

final class ContactLibraryTests: XCTestCase {
  func testSearchFindsContactsByNameEmailPhoneAndOrganization() throws {
    let service = ContactLibraryService(provider: StubContactProvider(contacts: sampleContacts))

    XCTAssertEqual(try service.search("ivan").map(\.id), ["1", "3"])
    XCTAssertEqual(try service.search("legal").map(\.id), ["2"])
    XCTAssertEqual(try service.search("555").map(\.id), ["1", "3"])
    XCTAssertEqual(try service.search("mail@example.com").map(\.id), ["2"])
  }

  func testSearchRejectsBlankQuery() throws {
    let service = ContactLibraryService(provider: StubContactProvider(contacts: sampleContacts))

    XCTAssertEqual(try service.search("  "), [])
  }

  func testFindsDuplicateCandidatesByEmailAndPhone() throws {
    let service = ContactLibraryService(provider: StubContactProvider(contacts: sampleContacts))

    XCTAssertEqual(try service.findDuplicateCandidates().map(\.id), ["1", "3"])
  }

  func testCreateContactUsesProvider() throws {
    let service = ContactLibraryService(provider: StubContactProvider(contacts: sampleContacts))
    let contact = try service.create(
      ContactDraft(
        givenName: "Anna",
        familyName: "Ivanova",
        organizationName: "Supply",
        phoneNumber: "+1 555 0199",
        emailAddress: "anna@example.com"))

    XCTAssertEqual(contact.givenName, "Anna")
    XCTAssertEqual(contact.emailAddresses, ["anna@example.com"])
  }

  func testBuildsUpdateAndDeletePreviewsWithoutMutatingContacts() throws {
    let service = ContactLibraryService(provider: StubContactProvider(contacts: sampleContacts))
    let contact = sampleContacts[0]

    let update = service.updatePreview(
      contact: contact,
      draft: ContactDraft(
        givenName: "Ivan",
        familyName: "Petrov",
        organizationName: "Legal",
        phoneNumber: "+1 555 0100",
        emailAddress: "ivan@example.com"))
    let delete = service.deletePreview(contact: contact)

    XCTAssertEqual(update.action, .update)
    XCTAssertEqual(update.contactID, "1")
    XCTAssertTrue(update.summary.contains("Update"))
    XCTAssertEqual(delete.action, .delete)
    XCTAssertEqual(delete.contactID, "1")
    XCTAssertTrue(delete.summary.contains("Delete"))
  }

  func testBuildsMergePreviewFromDuplicateContacts() throws {
    let service = ContactLibraryService(provider: StubContactProvider(contacts: sampleContacts))

    let preview = service.mergePreview(contacts: [sampleContacts[0], sampleContacts[2]])

    XCTAssertEqual(preview.primaryContactID, "1")
    XCTAssertEqual(preview.duplicateContactIDs, ["3"])
    XCTAssertEqual(preview.mergedContact?.phoneNumbers, ["+1 555 0100"])
    XCTAssertEqual(preview.mergedContact?.emailAddresses, ["ivan@example.com"])
  }
}

private let sampleContacts = [
  ContactSummary(
    id: "1",
    givenName: "Ivan",
    familyName: "Petrov",
    organizationName: "",
    phoneNumbers: ["+1 555 0100"],
    emailAddresses: ["ivan@example.com"]),
  ContactSummary(
    id: "2",
    givenName: "Olga",
    familyName: "Sidorova",
    organizationName: "Legal Dept",
    phoneNumbers: [],
    emailAddresses: ["mail@example.com"]),
  ContactSummary(
    id: "3",
    givenName: "Ivan",
    familyName: "P.",
    organizationName: "",
    phoneNumbers: ["+1 555 0100"],
    emailAddresses: ["ivan@example.com"]),
]

private struct StubContactProvider: ContactProviding {
  let contacts: [ContactSummary]

  func fetchContacts() throws -> [ContactSummary] {
    contacts
  }

  func createContact(_ draft: ContactDraft) throws -> ContactSummary {
    ContactSummary(
      id: "created",
      givenName: draft.givenName,
      familyName: draft.familyName,
      organizationName: draft.organizationName,
      phoneNumbers: draft.phoneNumber.isEmpty ? [] : [draft.phoneNumber],
      emailAddresses: draft.emailAddress.isEmpty ? [] : [draft.emailAddress])
  }
}
