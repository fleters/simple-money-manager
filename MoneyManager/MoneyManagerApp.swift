import SwiftUI
import SwiftData

@main
struct MoneyManagerApp: App {
    var sharedModelContainer: ModelContainer = Self.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }

    /// Membuat ModelContainer dengan fallback: jika migrasi skema gagal (mis. setelah
    /// perubahan model saat development), store lama dihapus dan dibuat ulang dari nol,
    /// alih-alih meng-crash seluruh app lewat fatalError.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Bank.self, Expense.self, Income.self, Transfer.self, ExpenseCategoryEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            seedDefaultCategoriesIfNeeded(context: container.mainContext)
            return container
        } catch {
            print("⚠️ ModelContainer migration failed, resetting local store: \(error)")
            deleteExistingStore()

            do {
                let container = try ModelContainer(for: schema, configurations: [config])
                seedDefaultCategoriesIfNeeded(context: container.mainContext)
                return container
            } catch {
                fatalError("Could not create ModelContainer even after reset: \(error)")
            }
        }
    }

    /// Menghapus file SQLite default SwiftData (termasuk -wal dan -shm) di Application Support.
    private static func deleteExistingStore() {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let baseNames = ["default.store", "default.store-wal", "default.store-shm"]
        for name in baseNames {
            let url = appSupport.appendingPathComponent(name)
            try? FileManager.default.removeItem(at: url)
        }
    }
}

private func seedDefaultCategoriesIfNeeded(context: ModelContext) {
    let descriptor = FetchDescriptor<ExpenseCategoryEntity>()
    let existingCount = (try? context.fetchCount(descriptor)) ?? 0
    guard existingCount == 0 else { return }
    for name in defaultExpenseCategories {
        context.insert(ExpenseCategoryEntity(name: name))
    }
    for name in defaultBankAccount {
        context.insert(Bank(name: name))
    }
    try? context.save()
}

#Preview {
    RootView()
}
