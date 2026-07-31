import Foundation

enum TxKind: String {
    case income, expense
}

/// A lightweight, read-only projection over Income/Expense so History can
/// sort, filter, and search both in one unified list without changing the DB schema.
struct TransactionItem: Identifiable, Hashable {
    let id: Date
    let kind: TxKind
    let date: Date
    let title: String       // Income.title OR Expense.itemOrService
    let subtitle: String?   // nil for income, Expense.storeName for expense
    let amount: Double
    let category: String    // proxy category: Income.title / Expense.itemOrService
    let budgetType: BudgetType? // nil for income; Needs/Wants for expense
    let bankName: String?
    let notes: String?

    static func from(_ income: Income) -> TransactionItem {
        TransactionItem(
            id: income.id,
            kind: .income,
            date: income.date,
            title: income.title,
            subtitle: nil,
            amount: income.amount,
            category: income.title,
            budgetType: nil,
            bankName: income.account?.name,
            notes: income.notes
        )
    }

    static func from(_ expense: Expense) -> TransactionItem {
        TransactionItem(
            id: expense.id,
            kind: .expense,
            date: expense.date,
            title: expense.itemOrService,
            subtitle: expense.storeName,
            amount: expense.amount,
            category: expense.category,
            budgetType: expense.budgetType,
            bankName: expense.account?.name,
            notes: expense.notes
        )
    }
}
