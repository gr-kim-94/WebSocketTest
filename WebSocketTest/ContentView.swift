//
//  ContentView.swift
//  WebSocketTest
//
//  Created by 김가람 on 2023/09/27.
//

import SwiftUI

struct ContentView: View {
    @StateObject var webSocketManager = WebSocketManager.shared
    
    @State var inputMessage: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Input Message",
                      text: $inputMessage)
            .padding()
            .border(Color.gray, width: 1)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(webSocketManager.messages.enumerated()), id: \.offset) { (_, message) in
                        Text(message)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 40)
            }
            .padding()
            .border(Color.gray, width: 1)
            
            Text("state : \(webSocketManager.state.rawValue)")
            
            Button("Send Message") {
                if !inputMessage.isEmpty {
                    webSocketManager.sendMessage(inputMessage) { error in
                        print("error : \(String(describing: error))")
                    }
                }
            }
            
            Button(webSocketManager.state == .connected ? "Disconnected":"Connected") {
                if webSocketManager.state == .connected {
                    webSocketManager.disconnect()
                } else {
                    webSocketManager.connect()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
