import SwiftUI
import SwiftData

enum SortOption: String, CaseIterable, Identifiable {
    case dateDesc = "Tanggal Terbaru"
    case dateAsc = "Tanggal Terlama"
    case titleAZ = "Judul A-Z"
    case titleZA = "Judul Z-A"
    case amountHigh = "Nominal Tertinggi"
    case amountLow = "Nominal Terendah"
    var id: String { rawValue }
}

enum KindFilter: String, CaseIterable, Identifiable {
    case all = "Semua"
    case income = "Income"
    case expense = "Expense"
    var id: String { rawValue }
}

enum DateRangeFilter: String, CaseIterable, Identifiable {
    case all = "Semua Waktu"
    case today = "Hari Ini"
    case week = "7 Hari Terakhir"
    case month = "30 Hari Terakhir"
    case year = "Tahun Ini"
    var id: String { rawValue }
}

enum BudgetTypeFilter: String, CaseIterable, Identifiable {
    case all = "Semua"
    case needs = "Needs"
    case wants = "Wants"
    var id: String { rawValue }
}

private let pageSize = 25

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Income.date, order: .reverse) private var incomes: [Income]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var searchText = ""
    @State private var kindFilter: KindFilter = .all
    @State private var dateFilter: DateRangeFilter = .all
    @State private var categoryFilter: String = "Semua Kategori"
    @State private var budgetTypeFilter: BudgetTypeFilter = .all
    @State private var sortOption: SortOption = .dateDesc
    @State private var visibleCount = pageSize
    @State private var showFilterSheet = false
    @State private var editingItem: TransactionItem?
    @State private var itemPendingDelete: TransactionItem?

    private var allItems: [TransactionItem] {
        incomes.map(TransactionItem.from) + expenses.map(TransactionItem.from)
    }

    private var categories: [String] {
        var set = Set(allItems.map { $0.category })
        set.insert("Semua Kategori")
        return ["Semua Kategori"] + set.subtracting(["Semua Kategori"]).sorted()
    }

    private var filtered: [TransactionItem] {
        var items = allItems

        if kindFilter != .all {
            items = items.filter { $0.kind == (kindFilter == .income ? .income : .expense) }
        }

        if categoryFilter != "Semua Kategori" {
            items = items.filter { $0.category == categoryFilter }
        }

        if budgetTypeFilter != .all {
            let target: BudgetType = budgetTypeFilter == .needs ? .needs : .wants
            items = items.filter { $0.budgetType == target }
        }

        if let cutoff = dateFilter.cutoffDate {
            items = items.filter { $0.date >= cutoff }
        }

        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchText.lowercased()
            items = items.filter {
                $0.title.lowercased().contains(q)
                || ($0.subtitle?.lowercased().contains(q) ?? false)
                || ($0.notes?.lowercased().contains(q) ?? false)
            }
        }

        switch sortOption {
        case .dateDesc: items.sort { $0.date > $1.date }
        case .dateAsc: items.sort { $0.date < $1.date }
        case .titleAZ: items.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleZA: items.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .amountHigh: items.sort { $0.amount > $1.amount }
        case .amountLow: items.sort { $0.amount < $1.amount }
        }

        return items
    }

    private var page: [TransactionItem] {
        Array(filtered.prefix(visibleCount))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(page) { item in
                    row(item)
                        .contentShape(Rectangle())
                        .onTapGesture { editingItem = item }
                        .swipeActions(edge: .trailing) {
                            Button("Hapus", role: .destructive) {
                                itemPendingDelete = item
                            }
                        }
                        .onAppear {
                            if item.id == page.last?.id, visibleCount < filtered.count {
                                visibleCount += pageSize
                            }
                        }
                }

                if filtered.isEmpty {
                    ContentUnavailableView("Tidak ada transaksi", systemImage: "tray")
                }
            }
            .listStyle(.plain)
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Cari judul, toko, atau catatan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSortSheet(
                    kindFilter: $kindFilter,
                    dateFilter: $dateFilter,
                    categoryFilter: $categoryFilter,
                    budgetTypeFilter: $budgetTypeFilter,
                    sortOption: $sortOption,
                    categories: categories
                )
            }
            .sheet(item: $editingItem) { item in
                EditTransactionSheet(item: item, incomes: incomes, expenses: expenses)
            }
            .alert(
                "Hapus transaksi ini?",
                isPresented: Binding(
                    get: { itemPendingDelete != nil },
                    set: { if !$0 { itemPendingDelete = nil } }
                )
            ) {
                Button("Batal", role: .cancel) { itemPendingDelete = nil }
                Button("Hapus", role: .destructive) {
                    if let item = itemPendingDelete { delete(item) }
                    itemPendingDelete = nil
                }
            } message: {
                Text("Tindakan ini tidak bisa dibatalkan.")
            }
            .onChange(of: searchText) { visibleCount = pageSize }
            .onChange(of: kindFilter) { visibleCount = pageSize }
            .onChange(of: dateFilter) { visibleCount = pageSize }
            .onChange(of: categoryFilter) { visibleCount = pageSize }
            .onChange(of: budgetTypeFilter) { visibleCount = pageSize }
            .onChange(of: sortOption) { visibleCount = pageSize }
        }
    }

    private func delete(_ item: TransactionItem) {
        switch item.kind {
        case .income:
            if let match = incomes.first(where: { $0.id == item.id }) {
                context.delete(match)
            }
        case .expense:
            if let match = expenses.first(where: { $0.id == item.id }) {
                context.delete(match)
            }
        }
    }

    private func row(_ item: TransactionItem) -> some View {
        HStack {
            Image(systemName: item.kind == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(item.kind == .income ? .green : .red)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title).font(.subheadline.bold())
                if let subtitle = item.subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Text(item.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2).foregroundStyle(.secondary)

                if item.kind == .expense {
                    HStack(spacing: 6) {
                        if let budgetType = item.budgetType {
                            budgetTypeLabel(budgetType)
                        }
                        categoryLabel(item.category)
                    }
                }
            }

            Spacer()

            Text((item.kind == .income ? item.amount : -item.amount).currencyFormatted)
                .font(.subheadline.bold())
                .foregroundStyle(item.kind == .income ? .green : .red)
        }
        .padding(.vertical, 4)
    }

    private func categoryLabel(_ category: String) -> some View {
        Text(category)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.gray.opacity(0.15), in: Capsule())
            .foregroundStyle(.secondary)
    }

    private func budgetTypeLabel(_ type: BudgetType) -> some View {
        Text(type.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background((type == .needs ? Color.red : Color.pink).opacity(0.15), in: Capsule())
            .foregroundStyle(type == .needs ? .red : .pink)
    }
}

private extension DateRangeFilter {
    var cutoffDate: Date? {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .all: return nil
        case .today: return cal.startOfDay(for: now)
        case .week: return cal.date(byAdding: .day, value: -7, to: now)
        case .month: return cal.date(byAdding: .day, value: -30, to: now)
        case .year: return cal.date(from: cal.dateComponents([.year], from: now))
        }
    }
}

private struct EditTransactionSheet: View {
    let item: TransactionItem
    let incomes: [Income]
    let expenses: [Expense]
    @Environment(\.dismiss) private var dismiss
    @State private var saveAction: (() -> Void)?
    @State private var canSave = true
    @State private var isDirty = false
    @State private var showDiscardConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                switch item.kind {
                case .income:
                    if let income = incomes.first(where: { $0.id == item.id }) {
                        AddIncomeForm(editing: income, onSaved: { dismiss() }, saveAction: $saveAction, canSave: $canSave, isDirty: $isDirty)
                    }
                case .expense:
                    if let expense = expenses.first(where: { $0.id == item.id }) {
                        AddExpenseForm(editing: expense, onSaved: { dismiss() }, saveAction: $saveAction, canSave: $canSave, isDirty: $isDirty)
                    }
                }
            }
            .navigationTitle("Edit Transaksi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .destructive) {
                        requestDismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        saveAction?()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .tint(.accentColor)
                    .disabled(!canSave)
                }
            }
        }
        .interactiveDismissDisabled(isDirty)
        .presentationDetents([.medium, .large])
        .alert("Buang perubahan?", isPresented: $showDiscardConfirm) {
            Button("Batal", role: .cancel) {}
            Button("Buang", role: .destructive) { dismiss() }
        } message: {
            Text("Perubahan yang sudah diisi belum disimpan dan akan hilang.")
        }
    }

    private func requestDismiss() {
        if isDirty {
            showDiscardConfirm = true
        } else {
            dismiss()
        }
    }
}

private struct FilterSortSheet: View {
    @Binding var kindFilter: KindFilter
    @Binding var dateFilter: DateRangeFilter
    @Binding var categoryFilter: String
    @Binding var budgetTypeFilter: BudgetTypeFilter
    @Binding var sortOption: SortOption
    let categories: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Tipe") {
                    Picker("Tipe", selection: $kindFilter) {
                        ForEach(KindFilter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Needs / Wants") {
                    Picker("Needs / Wants", selection: $budgetTypeFilter) {
                        ForEach(BudgetTypeFilter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Rentang Waktu") {
                    Picker("Rentang Waktu", selection: $dateFilter) {
                        ForEach(DateRangeFilter.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Kategori") {
                    Picker("Kategori", selection: $categoryFilter) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section("Sortir") {
                    Picker("Sortir", selection: $sortOption) {
                        ForEach(SortOption.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
            }
            .navigationTitle("Filter & Sortir")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Selesai") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
