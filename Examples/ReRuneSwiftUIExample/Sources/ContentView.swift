import SwiftUI
import ReRuneCore

struct ContentView: View {
    @State private var resultMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            Text(reRuneString("home_title"))
                .font(.largeTitle)

            Text(reRuneString("home_subtitle"))
                .foregroundStyle(.secondary)

            Button(reRuneString("refresh_button")) {
                Task {
                    let result = await ReRune.checkForUpdates()
                    resultMessage = statusText(for: result)
                }
            }

            if !resultMessage.isEmpty {
                Text(resultMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func statusText(for result: ReRuneUpdateResult) -> String {
        switch result.status {
        case .updated:
            return "Updated locales: \(result.updatedLocales.sorted().joined(separator: ", "))"
        case .noChange:
            return "No translation changes found"
        case .failed:
            return result.errorMessage ?? "Update failed"
        }
    }
}
