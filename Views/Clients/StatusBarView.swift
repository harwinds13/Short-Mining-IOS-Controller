import SwiftUI

struct StatusBarView: View {
    let finishedCount: Int
    let errorCount: Int
    let processingCount: Int
    let lockedCount: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: 0) {
            if totalCount > 0 {
                segment(label: "Success", count: finishedCount, color: .green)
                segment(label: "Locked", count: lockedCount, color: .blue)
                segment(label: "Submitted", count: processingCount, color: .gray)
                segment(label: "Expired", count: errorCount, color: .red)
            } else {
                Text("No clients")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 28)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(.separator), lineWidth: 0.5))
    }

    @ViewBuilder
    private func segment(label: String, count: Int, color: Color) -> some View {
        if count > 0 {
            let fraction = Double(count) / Double(max(totalCount, 1))
            GeometryReader { geo in
                ZStack {
                    color.opacity(0.3)
                    Text("\(label) \(count)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
