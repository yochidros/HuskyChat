//
//  Created by yochidros on 3/21/23
//

import Foundation
import Prelude
import SwiftUI

public struct RecoveryChatView: View {
    @Environment(\.dismiss) var dismissHandler
    @StateObject var viewModel: RecoveryChatViewModel
    @State var searchText: String = ""

    init(viewModel: RecoveryChatViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    public var body: some View {
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
                        Text(DateFormatter.default.string(from: element.date))
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
