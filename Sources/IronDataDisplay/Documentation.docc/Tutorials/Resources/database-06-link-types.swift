import IronUI

var database = IronDatabase(name: "Contacts")

// URL: Clickable web links
let websiteColumn = database.addColumn(name: "Website", type: .url)

// Email: Clickable email addresses
let emailColumn = database.addColumn(name: "Email", type: .email)

// Phone: Clickable phone numbers
let phoneColumn = database.addColumn(name: "Phone", type: .phone)

// Person: User reference with avatar
let assigneeColumn = database.addColumn(name: "Assignee", type: .person)

/// Set values
let row = database.addRow()
database.setValue(.url(URL(string: "https://example.com")), for: row.id, column: websiteColumn.id)
database.setValue(.email("hello@example.com"), for: row.id, column: emailColumn.id)
database.setValue(.phone("+1 (555) 123-4567"), for: row.id, column: phoneColumn.id)
database.setValue(.person(IronPerson(name: "John Doe")), for: row.id, column: assigneeColumn.id)
