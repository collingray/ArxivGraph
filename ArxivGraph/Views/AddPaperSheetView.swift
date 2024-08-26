import SwiftUI

struct AddPaperSheetView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var isDisplayed: Bool
    @Binding var canvasPosition: CGPoint

    @State var idFieldText: String = ""
    @State var idError: Bool = false

    var body: some View {
        Form {
            VStack(alignment: .leading) {
                Text("Enter URL or Identifier")

                TextField(text: $idFieldText, prompt: Text("arXiv:XXXX.XXXXX")) {
                    Text("Enter URL or ID")
                }
                .onSubmit { Task {
                    try await submitAction()
                }}
                .labelsHidden()
                
                Text(verbatim: """
                    For example:
                    • https://arxiv.org/abs/2406.11944
                    • arXiv:2406.11944
                    • 2406.11944
                    • cs/9901002
                    """)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                
                HStack {
                    Spacer()
                    
                    if idError {
                        Text("Invalid identifier")
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                    
                    Button("Cancel", role: .cancel) {
                        isDisplayed = false
                    }
                    
                    Button("Add Paper", action: { Task {
                        try await submitAction()
                    }})
                        .buttonStyle(BorderedProminentButtonStyle())
                        .disabled(idFieldText.isEmpty)
                }
            }.padding()
        }
    }
    
    static let idRegex = /([a-z-]+(\.[A-Z]+)?\/\d{7}|\d{4}\.\d{4,5})(v\d+)?/
    
    func extractIdentifier(from val: String) -> String? {
        if let match = try? AddPaperSheetView.idRegex.firstMatch(in: val)?.output.1 {
            return String(match)
        } else {
            return nil
        }
    }
    
    func submitAction() async throws {
        if !idFieldText.isEmpty {
            if let id = extractIdentifier(from: idFieldText) {
                isDisplayed = false
                idError = false
                try await modelContext.addPaper(identifier: id, position: -canvasPosition)
            } else {
                idError = true
            }
        }
    }
}

//#Preview {
//    AddPaperSheetView(isDisplayed: Binding(get: { false }, set: { _ in () }))
//}
