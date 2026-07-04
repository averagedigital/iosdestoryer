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
}
