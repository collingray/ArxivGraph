import SwiftUI

struct AddPaperSheetView: View {
    @ObservedObject var viewModel: GraphViewModel
    
    @Binding var isDisplayed: Bool

    @State var searchText: String = ""
    @State var idError: Bool = false

    var body: some View {
        Form {
            VStack(alignment: .leading) {
                Text("Enter URL or Identifier")

                TextField(text: $searchText, prompt: Text("arXiv:XXXX.XXXXX")) {
                    Text("Enter URL or ID")
                }
                .onSubmit(submitAction)
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
                    
                    Button("Add Paper", action: submitAction)
                        .buttonStyle(BorderedProminentButtonStyle())
                        .disabled(searchText.isEmpty)
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
    
    func submitAction() {
        if !searchText.isEmpty {
            if let id = extractIdentifier(from: searchText) {
                viewModel.addPaper(identifier: id)
                idError = false
                isDisplayed = false
            } else {
                idError = true
            }
        }
    }
}

#Preview {
    AddPaperSheetView(viewModel: GraphViewModel(), isDisplayed: Binding(get: { false }, set: { _ in () }))
}
