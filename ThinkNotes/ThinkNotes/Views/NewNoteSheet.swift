import SwiftUI

struct NewNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var theme: NoteTheme = .ink

    let onCreate: (String, String, NoteTheme) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextField("Title", text: $title)
                    TextField("Description (helps the AI understand intent)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Theme") {
                    ThemePickerView(selection: $theme)
                }
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let finalTitle = title.isEmpty ? "Untitled" : title
                        onCreate(finalTitle, description, theme)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty && description.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ThemePickerView: View {
    @Binding var selection: NoteTheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NoteTheme.allCases) { theme in
                    Button {
                        selection = theme
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.background)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(selection == theme ? theme.accent : .clear, lineWidth: 3)
                                )
                                .overlay(
                                    Circle()
                                        .fill(theme.accent)
                                        .frame(width: 12, height: 12)
                                        .offset(x: 18, y: -18),
                                    alignment: .topTrailing
                                )
                            Text(theme.displayName)
                                .font(.caption)
                                .foregroundStyle(selection == theme ? theme.accent : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
