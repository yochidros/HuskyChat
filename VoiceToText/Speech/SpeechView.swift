//
//  SpeechView.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import SwiftUI

struct SpeechView: View {
    @StateObject var recognizer: SpeechRecognizerViewModel = .init(
        recognizer: .init(locale: .init(identifier: "en-US"))!
    )
    var body: some View {
        VStack {
            HStack {
                Image("icon")
                    .resizable()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .padding(.leading, 16)
                Text("Chat Conversation by voice")
                    .bold()
                Spacer()
            }

            HStack {
                Button(action: {
                    recognizer.requestPermission()
                }, label: {
                    HStack(spacing: 4) {
                        Text("Permission")
                    }
                })
                .disabled(recognizer.isEnabled)

                Button(action: {
                    withAnimation {
                        if recognizer.isRecoring {
                            recognizer.stop()
                        } else {
                            recognizer.record()
                        }
                    }
                }, label: {
                    HStack(spacing: 4) {
                        if !recognizer.isRecoring {
                            Image(systemName: "mic")
                                .imageScale(.medium)
                                .foregroundColor(recognizer.isRecoring ? .red : .accentColor)
                        }
                        Text(recognizer.isRecoring ? "Stop" : "Record")
                            .foregroundColor(recognizer.isRecoring ? .red : .accentColor)
                    }.padding()
                })
                .disabled(!recognizer.isEnabled)

                Button {
                    recognizer.send()
                } label: {
                    if recognizer.isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.circle")
                            .foregroundColor(recognizer.text.isEmpty ? .gray : .blue)
                            .padding()
                    }
                }
                .disabled(recognizer.text.isEmpty)

                #if DEBUG
                    Button {
                        recognizer.debugSend()
                    } label: {
                        Image(systemName: "paperplane.circle")
                            .foregroundColor(.yellow)
                            .padding()
                    }
                #endif
            }
            HStack {
                if recognizer.text.isEmpty {
                    Text("Recognized text here ...")
                        .foregroundColor(.gray.opacity(0.5))
                        .padding()
                } else {
                    Text(recognizer.text)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                Spacer()
            }
            .background(Color.white)

            ScrollViewReader { proxy in
                ZStack(alignment: .bottom) {
                    ScrollView {
                        LazyVStack {
                            ForEach(recognizer.messages, id: \.self) { message in
                                MessageView(message: message)
                                    .onChange(of: recognizer.lastItemId ?? "") { _ in
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
                            if recognizer.isRecoring {
                                recognizer.stop()
                            } else {
                                recognizer.record()
                            }
                        }
                    }, label: {
                        Image(systemName: recognizer.isRecoring ? "record.circle.fill" : "record.circle")
                            .resizable()
                            .foregroundColor(recognizer.isRecoring ? .red : .blue)
                            .frame(width: 40, height: 40)
                            .padding()
                            .background(recognizer.isRecoring ? Color.black : Color.white)
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
        SpeechView()
    }
}
