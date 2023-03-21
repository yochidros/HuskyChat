//
//  SpeechView.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import FeatureBuilder
import Message
import RecoveryChatFeatureBuilder
import SwiftUI
#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

@MainActor public struct SpeechView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel: SpeechRecognizerViewModel
    private let featureBuilder: FeatureBuilderProtocol
    public init(
        viewModel: SpeechRecognizerViewModel,
        featureBuilder: FeatureBuilderProtocol
    ) {
        _viewModel = .init(wrappedValue: viewModel)
        self.featureBuilder = featureBuilder
    }

    public var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack {
                                ForEach(
                                    viewModel.messages,
                                    id: \.self
                                ) { message in
                                    MessageView(
                                        message: message,
                                        onTapAssistantMessage: {
                                            viewModel.speak(message: $0.message)
                                        }
                                    )
                                    .onChange(of: viewModel.lastItemId ?? "") { _ in
                                        withAnimation {
                                            proxy.scrollTo(-1, anchor: .bottom)
                                        }
                                    }
                                }
                                Spacer().frame(height: 90)
                                    .id(-1)
                            }
                            .padding()
                        }
                        .background(Color.gray.opacity(0.1))
                    }

                    TextInputView(
                        text: $viewModel.text,
                        width: proxy.size.width,
                        font: .body,
                        isEnabled: viewModel.isEnabled,
                        isRecording: viewModel.isRecoring,
                        isSendEnable: !viewModel.text.isEmpty,
                        isSending: viewModel.isSending,
                        onSendButton: {
                            withAnimation {
                                viewModel.send()
                            }
                        },
                        onTapRecordButton: {
                            if viewModel.isRecoring {
                                viewModel.stop()
                            } else {
                                viewModel.record()
                            }
                        }
                    )
                }
            }
            .navigationTitle(viewModel.currentDateString)
            .toolbar {
                Menu(content: {
                    Button(action: { viewModel.recoveryChat() }, label: {
                        Label("Recovery", systemImage: "list.bullet.rectangle.portrait")
                    })
                    Button(action: { viewModel.newChat() }, label: {
                        Label("New", systemImage: "plus.app")
                    })
                }, label: {
                    Image(systemName: "note.text")
                })
            }
            .toolbar(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $viewModel.isRecovery, content: {
            featureBuilder.build(request: RecoveryChatFeatureRequest(completion: { message in
                viewModel.didSelectedLocalMessage(message)
            }))
        })
    }

    struct TextInputView: View {
        @Environment(\.colorScheme) private var colorScheme
        @FocusState var textFocused: Bool
        @Binding private var text: String
        private let width: CGFloat
        private let font: Font
        private let isSendEnable: Bool
        private let isSending: Bool
        private let isEnabled: Bool
        private let isRecording: Bool

        private let onSendButton: () -> Void
        private let onTapRecordButton: () -> Void
        enum Const {
            static let maxHeight: CGFloat = 120
            static let padding: CGFloat = 8
        }

        init(
            text: Binding<String>,
            width: CGFloat,
            font: Font = .body,
            isEnabled: Bool,
            isRecording: Bool,
            isSendEnable: Bool,
            isSending: Bool,
            onSendButton: @escaping () -> Void,
            onTapRecordButton: @escaping () -> Void
        ) {
            _text = text
            self.width = width
            self.font = font
            self.isEnabled = isEnabled
            self.isRecording = isRecording
            self.isSending = isSending
            self.isSendEnable = isSendEnable
            self.onSendButton = onSendButton
            self.onTapRecordButton = onTapRecordButton
        }

        var height: CGFloat {
            let height = text.boundingRect(
                with: .init(
                    width: width - Const.padding * 2,
                    height: .greatestFiniteMagnitude
                ),
                options: .usesLineFragmentOrigin,
                attributes: nil,
                context: nil
            ).height
            let paddingHeight = height + Const.padding * 2 + 12
            return paddingHeight < Const.maxHeight ? paddingHeight : Const.maxHeight
        }

        var body: some View {
            HStack(spacing: 0) {
                VStack {
                    Button(action: {
                        withAnimation {
                            onTapRecordButton()
                        }
                    }, label: {
                        HStack(spacing: 4) {
                            Image(systemName: "mic")
                                .imageScale(.medium)
                                .foregroundColor(isRecording ? .red : .blue)
                        }
                        .background(
                            Circle().fill(
                                colorScheme == .light ? .white : .black
                            )
                            .frame(width: 32, height: 32)
                        )
                        .frame(width: 32, height: 32)
                        .padding(.leading, 6)

                    })
                    .disabled(!isEnabled)

                    if textFocused {
                        Button(action: {
                            UIApplication.shared.endEditing()
                        }, label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .background(
                                    Circle().fill(
                                        colorScheme == .light ? .white : .black
                                    )
                                    .frame(width: 32, height: 32)
                                )
                                .frame(width: 32, height: 32)
                                .padding(.leading, 6)
                        })
                    }

                    Spacer(minLength: 0)
                }

                VStack(spacing: 0) {
                    TextEditor(text: $text)
                        .font(font)
                        .frame(height: height)
                        .fontWeight(.bold)
                        .cornerRadius(6)
                        .padding(.horizontal, 8)
                        .overlay {
                            if text.isEmpty {
                                HStack {
                                    Text("Let's start lesson about Speaking English")
                                        .lineLimit(1)
                                        .foregroundColor(.gray)
                                        .allowsHitTesting(false)
                                        .padding(.leading, 4)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                        .focused($textFocused)
                    Spacer()
                }

                VStack(spacing: 0) {
                    Button {
                        onSendButton()
                        UIApplication.shared.endEditing()
                    } label: {
                        if isSending {
                            ProgressView()
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: "paperplane")
                                .foregroundColor(!isSendEnable ? .gray : .blue)
                                .background(
                                    Circle().fill(
                                        colorScheme == .light ? .white : .black
                                    )
                                    .frame(width: 32, height: 32)
                                )
                                .frame(width: 32, height: 32)
                                .padding(.trailing, 8)
                        }
                    }
                    .disabled(!isSendEnable)

                    Spacer(minLength: 0)
                }
            }
            .frame(height: height + (textFocused ? 18 : 0))
            .padding(.vertical, 8)
            .background(colorScheme == .light ? .white : .black)
        }
    }

    struct MessageView: View {
        let message: Message
        let onTapAssistantMessage: (Message) -> Void

        @ViewBuilder
        var body: some View {
            HStack {
                if message.isAssistant {
                    Button(action: { onTapAssistantMessage(message) }, label: {
                        HStack(alignment: .top, spacing: 6) {
                            VStack {
                                Image(systemName: "lasso.and.sparkles")
                                    .foregroundColor(.black)
                                Spacer()
                            }

                            VStack(alignment: .leading) {
                                Text(message.message)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.leading)
                                    .font(.body)
                                Spacer(minLength: 0)
                            }
                            .textSelection(.enabled)
                        }
                        .padding(.all, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                    })
                    Spacer(minLength: 24)
                } else {
                    Spacer(minLength: 24)
                    HStack(alignment: .top, spacing: 6) {
                        VStack {
                            Image(systemName: "person.crop.circle")
                            Spacer()
                        }
                        VStack(alignment: .leading) {
                            Text(message.message)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .textSelection(.enabled)
                    }
                    .padding(.all, 8)
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(8)
                }
            }.id(message.id)
        }
    }
}

//
// struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        SpeechView(
//            viewModel: .init(
//                recognizer: .init(locale: .init(identifier: "en-US"))!
//            )
//        )
//    }
// }

#if canImport(UIKit)
    extension Font {
        var uiFontTextStyle: UIFont.TextStyle {
            switch self {
            case .largeTitle:
                return .largeTitle
            case .title:
                return .title1
            case .title2:
                return .title2
            case .title3:
                return .title3
            case .headline:
                return .headline
            case .subheadline:
                return .subheadline
            case .body:
                return .body
            case .callout:
                return .callout
            case .footnote:
                return .footnote
            case .caption:
                return .caption1
            case .caption2:
                return .caption2
            default:
                fatalError()
            }
        }
    }

    extension UIApplication {
        func endEditing() {
            sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
#endif
