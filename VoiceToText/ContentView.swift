//
//  ContentView.swift
//  VoiceToText
//
//  Created by yochidros on 3/11/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var recognizer: SpeechRecognizerViewModel = .init(
        recognizer: .init(locale: .init(identifier: "en-US"))!
    )
    var body: some View {
        VStack {
            Text("Chat Conversation by voice")
                .bold()

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
                    if recognizer.isRecoring {
                        recognizer.stop()
                    } else {
                        recognizer.record()
                    }
                }, label: {
                    HStack(spacing: 4) {
                        if !recognizer.isRecoring {
                            Image(systemName: "mic")
                                .imageScale(.medium)
                                .foregroundColor(recognizer.isRecoring ? .red : .black)
                        }
                        Text(recognizer.isRecoring ? "Stop" : "Record")
                            .foregroundColor(recognizer.isRecoring ? .red : .black)
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

                Button {
                    recognizer.speak(message: "I went to the shopping mall to buy a movie ticket.")
                } label: {
                    Image(systemName: "paperplane.circle")
                        .foregroundColor(.blue)
                        .padding()
                }

            }
            HStack {
                Text(recognizer.text)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
            .background(Color.white)


            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(recognizer.messages, id: \.self) { message in
                            HStack {
                                if message.isAssistant {
                                    HStack {
                                        VStack{
                                            Image(systemName: "lasso.and.sparkles")
                                            Spacer()
                                        }
                                        Text(message.message)
                                            .font(.body)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    Spacer(minLength: 240)
                                } else {
                                    Spacer()
                                    HStack {
                                        VStack {
                                            Image(systemName: "person.crop.circle" )
                                            Spacer()
                                        }
                                        Text(message.message)
                                            .font(.body)
                                            .padding()
                                    }
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }

                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .onAppear {
                    if let last = recognizer.messages.last {
                        proxy.scrollTo(last)
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
