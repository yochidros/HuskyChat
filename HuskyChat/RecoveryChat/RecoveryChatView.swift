//
//  RecoveryChatView.swift
//  HuskyChat
//
//  Created by yochidros on 3/18/23.
//

import SwiftUI
@MainActor class RecoveryChatViewModel: ObservableObject {
    @Published var localMessages: [LocalMessage] = []
    private let selectedMessageHandler: (LocalMessage) -> Void
    init(
        selectedMessageHandler: @escaping (LocalMessage) -> Void
    ) {
        self.selectedMessageHandler = selectedMessageHandler

        load()
    }

    private func load() {
        localMessages = LocalMessageManager.load()
    }

    func selectMessage(_ message: LocalMessage) {
        selectedMessageHandler(message)
    }
}

enum RecoveryChatViewBuilder {
    @MainActor static func build(
        selectedMessageHandler: @escaping (LocalMessage) -> Void
    ) -> RecoveryChatView {
        let vm = RecoveryChatViewModel(selectedMessageHandler: selectedMessageHandler)
        return RecoveryChatView(viewModel: vm)
    }
}

struct RecoveryChatView: View {
    @Environment(\.dismiss) var dismissHandler
    @StateObject var viewModel: RecoveryChatViewModel
    @State var searchText: String = ""
    let dataFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    init(viewModel: RecoveryChatViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    dismissHandler()
                }, label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 16, height: 16)
                })
                Spacer().frame(width: 16)
            }
            .background(Color.clear)
            .padding(.vertical, 12)
            List(viewModel.localMessages, id: \.self) { element in
                Button(action: {
                    viewModel.selectMessage(element)
                    dismissHandler()
                }, label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dataFormatter.string(from: element.date))
                        Text("Chat count: \(element.messages.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                })
            }
            Spacer()
        }
    }
}

struct RecoveryChatView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryChatView(viewModel: .init(selectedMessageHandler: { _ in }))
    }
}
