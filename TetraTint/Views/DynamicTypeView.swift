import SwiftUI

struct DynamicTypeView: View {
    @State private var fontName: String = "Pretendard-Regular"
    @State private var selectedStyle: Int = 5 // Body
    @State private var categoryIndex: Double = 3 // Large (default)
    @State private var snippetTab: SnippetTab = .swiftUI
    @State private var showCopied = false

    private enum SnippetTab: String, CaseIterable, Identifiable {
        case swiftUI = "SwiftUI"
        case uiKit = "UIKit"
        case layout = "AX layout"
        var id: String { rawValue }
    }

    private var style: TextStyleInfo { DynamicTypeData.styles[selectedStyle] }
    private var currentSize: Int { style.sizes[Int(categoryIndex)] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                previewSection
                codeSection
                referenceTable
                axNote
            }
            .padding(20)
        }
        .navigationTitle("Dynamic Type")
    }

    // MARK: Live preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scaling preview")
                .font(.title3.weight(.semibold))

            HStack(spacing: 12) {
                Picker("Style", selection: $selectedStyle) {
                    ForEach(DynamicTypeData.styles.indices, id: \.self) { i in
                        Text(DynamicTypeData.styles[i].name).tag(i)
                    }
                }
                .frame(width: 200)

                TextField("Custom font PostScript name", text: $fontName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)
            }

            HStack(spacing: 12) {
                Text("Category")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Slider(value: $categoryIndex, in: 0...6, step: 1)
                    .frame(width: 280)
                Text(DynamicTypeData.categories[Int(categoryIndex)])
                    .font(.callout.weight(.medium))
                    .frame(width: 80, alignment: .leading)
                Text("\(currentSize)pt")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Text("The quick brown fox jumps over the lazy dog")
                .font(.system(size: CGFloat(currentSize), weight: style.weight == "Semibold" ? .semibold : .regular))
                .lineLimit(2)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: Code generator

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Code")
                    .font(.title3.weight(.semibold))
                Picker("", selection: $snippetTab) {
                    ForEach(SnippetTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                Spacer()

                Button {
                    Exporters.copyToClipboard(snippet)
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showCopied = false }
                } label: {
                    Label(showCopied ? "Copied" : "Copy", systemImage: "doc.on.doc")
                }
            }

            ScrollView(.horizontal) {
                Text(snippet)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 260)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private var snippet: String {
        switch snippetTab {
        case .swiftUI:
            return DynamicTypeData.swiftUISnippet(fontName: fontName, style: style, baseSize: style.sizes[3])
        case .uiKit:
            return DynamicTypeData.uiKitSnippet(fontName: fontName, style: style, baseSize: style.sizes[3])
        case .layout:
            return DynamicTypeData.layoutSnippet()
        }
    }

    // MARK: Reference table

    private var referenceTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Text style sizes (pt)")
                .font(.title3.weight(.semibold))

            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 4) {
                GridRow {
                    Text("Style")
                        .frame(width: 150, alignment: .leading)
                    ForEach(DynamicTypeData.categories, id: \.self) { c in
                        Text(c)
                            .frame(width: 68)
                    }
                }
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)

                ForEach(DynamicTypeData.styles.indices, id: \.self) { i in
                    let s = DynamicTypeData.styles[i]
                    GridRow {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(s.name)
                                .font(.body)
                            Text(".\(s.swiftUIStyle) / .\(s.uiKitStyle)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 150, alignment: .leading)

                        ForEach(s.sizes.indices, id: \.self) { j in
                            Text("\(s.sizes[j])")
                                .font(.system(.callout, design: .monospaced))
                                .frame(width: 68)
                                .foregroundStyle(j == 3 ? .primary : .secondary)
                        }
                    }
                    .padding(.vertical, 2)
                    .background(i == selectedStyle ? Color.accentColor.opacity(0.08) : .clear)
                }
            }
        }
    }

    private var axNote: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Large is the default. In accessibility sizes (AX1 to AX5), Body grows to \(DynamicTypeData.bodyAccessibilitySizes.map(String.init).joined(separator: " → "))pt, over three times the default, so avoid fixed heights, fixed padding, and lineLimit(1).")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
