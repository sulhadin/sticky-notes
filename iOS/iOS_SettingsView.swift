import SwiftUI

struct iOS_SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultFontSize") private var defaultFontSize: Double = 14

    var body: some View {
        NavigationStack {
            Form {
                Section("Font") {
                    HStack {
                        Text("Default Font Size")
                        Spacer()
                        Text("\(Int(defaultFontSize)) pt")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $defaultFontSize, in: 10...32, step: 1)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
