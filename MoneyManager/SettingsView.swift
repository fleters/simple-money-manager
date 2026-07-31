import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("userNickname") private var nickname: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Query(sort: \Bank.name) private var banks: [Bank]
    @Query(sort: \ExpenseCategoryEntity.name) private var categories: [ExpenseCategoryEntity]
    @Environment(\.modelContext) private var context

    @State private var newBankName = ""
    @State private var newCategoryName = ""
    @State private var showResetAlert = false
    @State private var categoryPendingDelete: ExpenseCategoryEntity?

    var body: some View {
        NavigationStack {
            Form {
                Section("Profil") {
                    TextField("Nama panggilan", text: $nickname)
                }

                Section("Rekening / Bank") {
                    ForEach(banks) { bank in
                        Text(bank.name)
                    }
                    .onDelete(perform: deleteBank)

                    HStack {
                        TextField("Tambah bank baru", text: $newBankName)
                        Button("Tambah") { addBank() }
                            .disabled(newBankName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("Kategori Expense") {
                    ForEach(categories) { category in
                        Text(category.name)
                    }
                    .onDelete { offsets in
                        if let index = offsets.first {
                            categoryPendingDelete = categories[index]
                        }
                    }

                    HStack {
                        TextField("Tambah kategori baru", text: $newCategoryName)
                        Button("Tambah") { addCategory() }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section {
                    Button("Ulangi Onboarding", role: .destructive) {
                        showResetAlert = true
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Ulangi Onboarding?", isPresented: $showResetAlert) {
                Button("Batal", role: .cancel) {}
                Button("Ya", role: .destructive) {
                    hasCompletedOnboarding = false
                }
            } message: {
                Text("Layar selamat datang akan muncul lagi saat app dibuka.")
            }
            .alert(
                "Hapus kategori \"\(categoryPendingDelete?.name ?? "")\"?",
                isPresented: Binding(
                    get: { categoryPendingDelete != nil },
                    set: { if !$0 { categoryPendingDelete = nil } }
                )
            ) {
                Button("Batal", role: .cancel) { categoryPendingDelete = nil }
                Button("Hapus", role: .destructive) {
                    if let category = categoryPendingDelete {
                        context.delete(category)
                    }
                    categoryPendingDelete = nil
                }
            } message: {
                Text("Expense lama yang sudah memakai kategori ini tidak akan terhapus, hanya tidak bisa dipilih lagi untuk data baru.")
            }
        }
    }

    private func addBank() {
        let trimmed = newBankName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        context.insert(Bank(name: trimmed))
        newBankName = ""
    }

    private func deleteBank(at offsets: IndexSet) {
        for index in offsets { context.delete(banks[index]) }
    }

    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !categories.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            newCategoryName = ""
            return
        }
        context.insert(ExpenseCategoryEntity(name: trimmed))
        newCategoryName = ""
    }
}
