import SwiftUI

struct KidsMarkdownDocumentView: View {
    let title: String
    let resourceName: String
    let fileExtension: String

    @Environment(\.dismiss) private var dismiss

    @State private var attributedContent: AttributedString?
    @State private var rawContent: String = ""
    @State private var loadError: String?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let loadError {
                        Text(loadError)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let attributedContent {
                        Text(attributedContent)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(KidsTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if !rawContent.isEmpty {
                        Text(rawContent)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(KidsTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ProgressView()
                            .tint(KidsTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    }
                }
                .padding(20)
            }
        }
        .background(KidsTheme.backgroundGradient.ignoresSafeArea())
        .task {
            await load()
        }
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(KidsTheme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(KidsTheme.surface)
                    .clipShape(Circle())
            }

            Spacer()

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(KidsTheme.textPrimary)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding()
        .background(KidsTheme.surface)
    }

    private func load() async {
        guard attributedContent == nil, rawContent.isEmpty, loadError == nil else { return }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
            loadError = "Could not load \(resourceName).\(fileExtension)."
            return
        }

        do {
            let markdown = try String(contentsOf: url, encoding: .utf8)

            if let parsed = try? AttributedString(
                markdown: markdown,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
            ) {
                attributedContent = parsed
            } else {
                rawContent = markdown
            }
        } catch {
            loadError = "Could not read document."
        }
    }
}

#Preview {
    KidsMarkdownDocumentView(title: "Privacy Policy", resourceName: "PRIVACY_POLICY", fileExtension: "md")
}
