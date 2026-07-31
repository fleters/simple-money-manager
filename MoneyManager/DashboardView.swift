import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    var goToHistory: () -> Void

    @AppStorage("userNickname") private var nickname: String = ""
    @Query(sort: \Income.date, order: .reverse) private var incomes: [Income]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    private var totalIncome: Double { incomes.reduce(0) { $0 + $1.amount } }
    private var totalExpense: Double { expenses.reduce(0) { $0 + $1.amount } }
    private var balance: Double { totalIncome - totalExpense }
    private var totalNeeds: Double { expenses.filter { $0.budgetType == .needs }.reduce(0) { $0 + $1.amount } }
    private var totalWants: Double { expenses.filter { $0.budgetType == .wants }.reduce(0) { $0 + $1.amount } }

    private struct CategorySlice: Identifiable {
        let id = UUID()
        let category: String
        let amount: Double
        var pct: Double
    }

    private var categoryBreakdown: [CategorySlice] {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        let total = totalExpense
        return grouped.map { key, items in
            let sum = items.reduce(0) { $0 + $1.amount }
            return CategorySlice(category: key, amount: sum, pct: total == 0 ? 0 : sum / total * 100)
        }
        .sorted { $0.amount > $1.amount }
    }

    private var recentNeeds: [Expense] {
        Array(expenses.filter { $0.budgetType == .needs }.prefix(5))
    }
    private var recentWants: [Expense] {
        Array(expenses.filter { $0.budgetType == .wants }.prefix(5))
    }

    private let paletteColors: [Color] = [.red, .orange, .yellow, .pink, .purple, .indigo, .teal, .brown]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    categoryChart
                    incomeExpenseBar

                    Button(action: goToHistory) {
                        HStack {
                            Text("Riwayat Terbaru").font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    recentSplitContainer
                }
                .padding()
            }
            .navigationTitle("Halo, \(nickname.isEmpty ? "Kamu" : nickname) 👋")
        }
    }

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expense per Kategori")
                .font(.headline)

            if totalExpense == 0 {
                Text("Belum ada expense.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                ZStack {
                    Chart(Array(categoryBreakdown.enumerated()), id: \.element.id) { index, slice in
                        SectorMark(angle: .value("Amount", slice.amount), innerRadius: .ratio(0.6), angularInset: 1.5)
                            .foregroundStyle(paletteColors[index % paletteColors.count])
                            .cornerRadius(4)
                    }
                    .frame(height: 180)
                    .chartLegend(.hidden)

                    VStack(spacing: 2) {
                        Text("Balance")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(balance.currencyFormatted)
                            .font(.subheadline.bold())
                            .foregroundStyle(balance >= 0 ? .green : .red)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(categoryBreakdown.enumerated()), id: \.element.id) { index, slice in
                        HStack(spacing: 8) {
                            Circle().fill(paletteColors[index % paletteColors.count]).frame(width: 10, height: 10)
                            Text(slice.category).font(.caption.bold())
                            Spacer()
                            Text("\(slice.pct, specifier: "%.0f")%").font(.caption2).foregroundStyle(.secondary)
                            Text(slice.amount.currencyFormatted).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var incomeExpenseBar: some View {
        // Proporsi hijau (Income) vs merah (Expense) — mengikuti pola VotingBarView, fallback 50:50 saat kosong.
        let total = totalIncome + totalExpense
        let incomeRatio: CGFloat = total == 0 ? 0.5 : CGFloat(totalIncome / total)
        let incomePct = Int(incomeRatio * 100)
        let expensePct = 100 - incomePct

        return VStack(spacing: 8) {
            HStack {
                Text("Income \(incomePct)% (\(totalIncome.currencyFormatted))")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Spacer()

                Text("Expense \(expensePct)% (\(totalExpense.currencyFormatted))")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            GeometryReader { geometry in
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * incomeRatio)

                    Rectangle()
                        .fill(Color.red)
                }
            }
            .frame(height: 12)
            .cornerRadius(6)
            .clipped()
            .animation(.easeInOut(duration: 0.3), value: total)
        }
        .padding(.horizontal, 4)
    }

    private var recentSplitContainer: some View {
        HStack(alignment: .top, spacing: 12) {
            recentColumn(title: "Needs", color: Color(red: 0.7, green: 0.1, blue: 0.1)) {
                ForEach(recentNeeds) { item in
                    recentRow(title: item.itemOrService, amount: item.amount, date: item.date, color: Color(red: 0.7, green: 0.1, blue: 0.1))
                }
                if recentNeeds.isEmpty {
                    Text("Belum ada data").font(.caption).foregroundStyle(.secondary)
                }
            }

            recentColumn(title: "Wants", color: Color(red: 1.0, green: 0.45, blue: 0.4)) {
                ForEach(recentWants) { item in
                    recentRow(title: item.itemOrService, amount: item.amount, date: item.date, color: Color(red: 1.0, green: 0.45, blue: 0.4))
                }
                if recentWants.isEmpty {
                    Text("Belum ada data").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func recentColumn<Content: View>(title: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        Button(action: goToHistory) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.subheadline.bold()).foregroundStyle(color)
                VStack(alignment: .leading, spacing: 8) { content() }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func recentRow(title: String, amount: Double, date: Date, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption.bold()).lineLimit(1)
            Text(amount.currencyFormatted)
                .font(.caption2)
                .foregroundStyle(color)
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "Rp\(Int(self))"
    }
}
