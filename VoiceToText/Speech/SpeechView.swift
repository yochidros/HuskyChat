//
//  SpeechView.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import SwiftUI

@MainActor struct SpeechView: View {
    @StateObject var viewModel: SpeechRecognizerViewModel

    var body: some View {
        VStack {
            HeaderView(totalCount: viewModel.totalToken)
                .padding(.vertical, 12)

            ButtonView(
                onTapPermission: {
                    viewModel.requestPermission()
                },
                isEnabled: viewModel.isEnabled,
                onTapRecordButton: {
                    if viewModel.isRecoring {
                        viewModel.stop()
                    } else {
                        viewModel.record()
                    }
                },
                isRecording: viewModel.isRecoring,
                onSendButton: {
                    viewModel.send()
                },
                isSending: viewModel.isSending,
                isSendEnable: !viewModel.text.isEmpty,
                onDebugButton: {
                    #if DEBUG
                        viewModel.debugSend()
                    #endif
                }
            )

            HStack {
                if viewModel.text.isEmpty {
                    Text("Recognized text here ...")
                        .foregroundColor(.gray.opacity(0.5))
                        .padding()
                } else {
                    TextEditor(text: $viewModel.text)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                Spacer()
            }

            ScrollViewReader { proxy in
                ZStack(alignment: .bottom) {
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.messages, id: \.self) { message in
                                MessageView(message: message)
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

                    Button(action: {
                        withAnimation {
                            if viewModel.isRecoring {
                                viewModel.stop()
                            } else {
                                viewModel.record()
                            }
                        }
                    }, label: {
                        Image(systemName: viewModel.isRecoring ? "record.circle.fill" : "record.circle")
                            .resizable()
                            .foregroundColor(viewModel.isRecoring ? .red : .blue)
                            .frame(width: 30, height: 30)
                            .padding()
                            .background(viewModel.isRecoring ? Color.black : Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 1, y: 1)
                            .padding(.bottom, 10)
                    })
                }
                .background(Color.gray.opacity(0.1))
            }
            .padding()
        }
    }

    struct HeaderView: View {
        let totalCount: Int
        var body: some View {
            HStack {
                Image("icon")
                    .resizable()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .padding(.leading, 16)
                Text("Chat Conversation by voice")
                    .bold()
                Spacer()
                Text("\(totalCount)")
                Spacer()
            }
        }
    }

    struct ButtonView: View {
        let onTapPermission: () -> Void
        let isEnabled: Bool
        let onTapRecordButton: () -> Void
        let isRecording: Bool
        let onSendButton: () -> Void
        let isSending: Bool
        let isSendEnable: Bool
        let onDebugButton: () -> Void

        var body: some View {
            HStack {
                Button(action: {
                    onTapPermission()
                }, label: {
                    HStack(spacing: 4) {
                        Text("Permission")
                    }
                })
                .disabled(isEnabled)

                Button(action: {
                    withAnimation {
                        onTapRecordButton()
                    }
                }, label: {
                    HStack(spacing: 4) {
                        if !isRecording {
                            Image(systemName: "mic")
                                .imageScale(.medium)
                                .foregroundColor(isRecording ? .red : .accentColor)
                        }
                        Text(isRecording ? "Stop" : "Record")
                            .foregroundColor(isRecording ? .red : .accentColor)
                    }.padding()
                })
                .disabled(!isEnabled)

                Button {
                    onSendButton()
                } label: {
                    if isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.circle")
                            .foregroundColor(isSendEnable ? .gray : .blue)
                            .padding()
                    }
                }
                .disabled(!isSendEnable)

                #if DEBUG
                    Button {
                        onDebugButton()
                    } label: {
                        Image(systemName: "paperplane.circle")
                            .foregroundColor(.yellow)
                            .padding()
                    }
                #endif
            }
        }
    }

    struct MessageView: View {
        let message: Message

        @ViewBuilder
        var body: some View {
            HStack {
                if message.isAssistant {
                    HStack {
                        VStack {
                            Image(systemName: "lasso.and.sparkles")
                            Spacer()
                        }

                        Text(message.message)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                    Spacer(minLength: 24)
                } else {
                    Spacer(minLength: 24)
                    HStack {
                        VStack {
                            Image(systemName: "person.crop.circle")
                            Spacer()
                        }
                        Text(message.message)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }.id(message.id)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SpeechView(
            viewModel: .init(
                recognizer: .init(locale: .init(identifier: "en-US"))!
            )
        )
    }
}
