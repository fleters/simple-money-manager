import SwiftUI
import SwiftData

enum HubSection: String, CaseIterable, Identifiable {
    case addData = "Tambah Data"
    case settings = "Settings"
    var id: String { rawValue }
}

enum AddEntryType: String, CaseIterable, Identifiable {
    case expense = "Expense"
    case income = "Income"
    var id: String { rawValue }
}

struct AddEntryHubView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var section: HubSection = .addData
    @State private var entryType: AddEntryType = .expense
    @State private var saveAction: (() -> Void)?
    @State private var canSave = false
    @State private var isDirty = false
    @State private var showDiscardConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Section", selection: $section) {
                    ForEach(HubSection.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch section {
                case .addData:
                    Picker("Tipe", selection: $entryType) {
                        ForEach(AddEntryType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    switch entryType {
                    case .income:
                        AddIncomeForm(editing: nil, onSaved: { dismiss() }, saveAction: $saveAction, canSave: $canSave, isDirty: $isDirty)
                    case .expense:
                        AddExpenseForm(editing: nil, onSaved: { dismiss() }, saveAction: $saveAction, canSave: $canSave, isDirty: $isDirty)
                    }

                case .settings:
                    SettingsView()
                }
            }
            .padding(.top)
            .navigationTitle(section == .addData ? "Tambah Data" : "Settings")
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
                if section == .addData {
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
        }
        .interactiveDismissDisabled(section == .addData && isDirty)
        .presentationDetents([.medium, .large])
        .alert("Buang perubahan?", isPresented: $showDiscardConfirm) {
            Button("Batal", role: .cancel) {}
            Button("Buang", role: .destructive) { dismiss() }
        } message: {
            Text("Data yang sudah diisi belum disimpan dan akan hilang.")
        }
    }

    private func requestDismiss() {
        if section == .addData && isDirty {
            showDiscardConfirm = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Add / Edit Income Form
struct AddIncomeForm: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Bank.name) private var banks: [Bank]
    var editing: Income?
    var onSaved: () -> Void
    @Binding var saveAction: (() -> Void)?
    @Binding var canSave: Bool
    @Binding var isDirty: Bool

    @State private var title = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var selectedBank: Bank?
    @State private var notes = ""
    @State private var originalSnapshot: String = ""

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && Double(amountText) != nil
    }

    private var currentSnapshot: String {
        "\(title)|\(amountText)|\(date.timeIntervalSince1970)|\(selectedBank?.name ?? "")|\(notes)"
    }

    private var hasInput: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
        || !amountText.isEmpty
        || !notes.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func refreshDirty() {
        canSave = isValid
        isDirty = editing == nil ? hasInput : (currentSnapshot != originalSnapshot)
    }

    var body: some View {
        Form {
            Section("Detail Income") {
                TextField("Judul (mis. Gaji)", text: $title)
                TextField("Nominal", text: $amountText)
                    .keyboardType(.decimalPad)
                DatePicker("Tanggal", selection: $date, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Rekening") {
                Picker("Bank", selection: $selectedBank) {
                    Text("Tanpa rekening").tag(Bank?.none)
                    Divider()
                    ForEach(banks) { bank in
                        Text(bank.name).tag(Bank?.some(bank))
                    }
                }
            }

            Section("Catatan") {
                TextField("Opsional", text: $notes, axis: .vertical)
            }
        }
        .onAppear {
            populateIfEditing()
            originalSnapshot = currentSnapshot
            saveAction = save
            canSave = isValid
        }
        .onChange(of: title) { refreshDirty() }
        .onChange(of: amountText) { refreshDirty() }
        .onChange(of: date) { refreshDirty() }
        .onChange(of: selectedBank) { refreshDirty() }
        .onChange(of: notes) { refreshDirty() }
    }

    private func populateIfEditing() {
        guard let income = editing else { return }
        title = income.title
        amountText = String(income.amount)
        date = income.date
        selectedBank = income.account
        notes = income.notes ?? ""
    }

    private func save() {
        guard let amount = Double(amountText) else { return }
        if let income = editing {
            income.title = title.trimmingCharacters(in: .whitespaces)
            income.amount = amount
            income.date = date
            income.account = selectedBank
            income.notes = notes.isEmpty ? nil : notes
        } else {
            let income = Income(
                date: date,
                title: title.trimmingCharacters(in: .whitespaces),
                amount: amount,
                account: selectedBank,
                notes: notes.isEmpty ? nil : notes
            )
            context.insert(income)
        }
        onSaved()
    }
}

// MARK: - Add / Edit Expense Form
struct AddExpenseForm: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Bank.name) private var banks: [Bank]
    @Query(sort: \ExpenseCategoryEntity.name) private var categories: [ExpenseCategoryEntity]
    var editing: Expense?
    var onSaved: () -> Void
    @Binding var saveAction: (() -> Void)?
    @Binding var canSave: Bool
    @Binding var isDirty: Bool

    @State private var storeName = ""
    @State private var itemOrService = ""
    @State private var selectedCategory: ExpenseCategoryEntity?
    @State private var selectedBudgetType: BudgetType = .wants
    @State private var amountText = ""
    @State private var date = Date()
    @State private var selectedBank: Bank?
    @State private var notes = ""
    @State private var originalSnapshot: String = ""

    private var isValid: Bool {
        !storeName.trimmingCharacters(in: .whitespaces).isEmpty
        && !itemOrService.trimmingCharacters(in: .whitespaces).isEmpty
        && selectedCategory != nil
        && Double(amountText) != nil
    }

    private var currentSnapshot: String {
        "\(storeName)|\(itemOrService)|\(selectedCategory?.name ?? "")|\(selectedBudgetType.rawValue)|\(amountText)|\(date.timeIntervalSince1970)|\(selectedBank?.name ?? "")|\(notes)"
    }

    private var hasInput: Bool {
        !storeName.trimmingCharacters(in: .whitespaces).isEmpty
        || !itemOrService.trimmingCharacters(in: .whitespaces).isEmpty
        || !amountText.isEmpty
        || !notes.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func refreshDirty() {
        canSave = isValid
        isDirty = editing == nil ? hasInput : (currentSnapshot != originalSnapshot)
    }

    var body: some View {
        Form {
            Section("Detail Expense") {
                TextField("Nama Toko / Merchant", text: $storeName)
                TextField("Item / Jasa", text: $itemOrService)
                Picker("Kategori", selection: $selectedCategory) {
                    Text("Pilih kategori").tag(ExpenseCategoryEntity?.none)
                    Divider()
                    ForEach(categories) { cat in
                        Text(cat.name).tag(ExpenseCategoryEntity?.some(cat))
                    }
                }
                Picker("Needs / Wants", selection: $selectedBudgetType) {
                    ForEach(BudgetType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
//                .pickerStyle(.segmented)
                TextField("Nominal", text: $amountText)
                    .keyboardType(.decimalPad)
                DatePicker("Tanggal", selection: $date, displayedComponents: [.date, .hourAndMinute])
            }

            Section("Rekening") {
                Picker("Bank", selection: $selectedBank) {
                    Text("Tanpa rekening").tag(Bank?.none)
                    Divider()
                    ForEach(banks) { bank in
                        Text(bank.name).tag(Bank?.some(bank))
                    }
                }
            }

            Section("Catatan") {
                TextField("Opsional", text: $notes, axis: .vertical)
            }
        }
        .onAppear {
            populateIfEditing()
            originalSnapshot = currentSnapshot
            saveAction = save
            canSave = isValid
        }
        .onChange(of: storeName) { refreshDirty() }
        .onChange(of: itemOrService) { refreshDirty() }
        .onChange(of: selectedCategory) { refreshDirty() }
        .onChange(of: selectedBudgetType) { refreshDirty() }
        .onChange(of: amountText) { refreshDirty() }
        .onChange(of: date) { refreshDirty() }
        .onChange(of: selectedBank) { refreshDirty() }
        .onChange(of: notes) { refreshDirty() }
    }

    private func populateIfEditing() {
        if let expense = editing {
            storeName = expense.storeName
            itemOrService = expense.itemOrService
            selectedCategory = categories.first { $0.name == expense.category }
            selectedBudgetType = expense.budgetType
            amountText = String(expense.amount)
            date = expense.date
            selectedBank = expense.account
            notes = expense.notes ?? ""
        } else if selectedCategory == nil {
            selectedCategory = categories.first
        }
    }

    private func save() {
        guard let amount = Double(amountText), let category = selectedCategory else { return }
        if let expense = editing {
            expense.storeName = storeName.trimmingCharacters(in: .whitespaces)
            expense.itemOrService = itemOrService.trimmingCharacters(in: .whitespaces)
            expense.category = category.name
            expense.budgetType = selectedBudgetType
            expense.amount = amount
            expense.date = date
            expense.account = selectedBank
            expense.notes = notes.isEmpty ? nil : notes
        } else {
            let expense = Expense(
                date: date,
                storeName: storeName.trimmingCharacters(in: .whitespaces),
                itemOrService: itemOrService.trimmingCharacters(in: .whitespaces),
                category: category.name,
                budgetType: selectedBudgetType,
                amount: amount,
                account: selectedBank,
                notes: notes.isEmpty ? nil : notes
            )
            context.insert(expense)
        }
        onSaved()
    }
}
