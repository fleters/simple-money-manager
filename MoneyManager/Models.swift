import Foundation
import SwiftData

// MARK: - Bank Model
@Model
final class Bank {
    @Attribute(.unique) var id: Date
    @Attribute(.unique) var name: String

    init(id: Date = Date(), name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Budget Type (Needs vs Wants classification for expenses)
enum BudgetType: String, CaseIterable, Identifiable, Codable {
    case wants = "Wants"
    case needs = "Needs"
    var id: String { rawValue }
}

// MARK: - Expense Model
@Model
final class Expense {
    @Attribute(.unique) var id: Date
    var date: Date
    var storeName: String
    var itemOrService: String
    var category: String
    var budgetTypeRaw: String
    var amount: Double
    var account: Bank?
    var notes: String?

    var budgetType: BudgetType {
        get { BudgetType(rawValue: budgetTypeRaw) ?? .needs }
        set { budgetTypeRaw = newValue.rawValue }
    }

    init(
        id: Date = Date(),
        date: Date = Date(),
        storeName: String,
        itemOrService: String,
        category: String,
        budgetType: BudgetType,
        amount: Double,
        account: Bank? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.storeName = storeName
        self.itemOrService = itemOrService
        self.category = category
        self.budgetTypeRaw = budgetType.rawValue
        self.amount = amount
        self.account = account
        self.notes = notes
    }
}

// MARK: - Expense Category (user-editable, stored in SwiftData)
@Model
final class ExpenseCategoryEntity {
    @Attribute(.unique) var id: Date
    @Attribute(.unique) var name: String

    init(id: Date = Date(), name: String) {
        self.id = id
        self.name = name
    }
}

let defaultExpenseCategories = [
    "Makanan", "Transportasi", "Belanja", "Tagihan",
    "Kesehatan", "Hiburan", "Pendidikan", "Lainnya"
]
let defaultBankAccount = [
    "Cash"
]

// MARK: - Income Model
@Model
final class Income {
    @Attribute(.unique) var id: Date
    var date: Date
    var title: String
    var amount: Double
    var account: Bank?
    var notes: String?

    init(
        id: Date = Date(),
        date: Date = Date(),
        title: String,
        amount: Double,
        account: Bank? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.amount = amount
        self.account = account
        self.notes = notes
    }
}

// MARK: - Transfer Model
@Model
final class Transfer {
    @Attribute(.unique) var id: Date
    var date: Date
    var title: String
    var amount: Double
    var fromBank: Bank?
    var toBank: Bank?
    var notes: String?

    init(
        id: Date = Date(),
        date: Date = Date(),
        title: String,
        amount: Double,
        fromBank: Bank? = nil,
        toBank: Bank? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.amount = amount
        self.fromBank = fromBank
        self.toBank = toBank
        self.notes = notes
    }
}
