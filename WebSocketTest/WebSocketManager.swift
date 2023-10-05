//
//  WebSocketManager.swift
//  WebSocketTest
//
//  Created by 김가람 on 2023/09/27.
//

import Foundation

private let BaseURL = ""

enum WebSocketState: String {
    case connected
    case disconnected
}

class WebSocketManager: NSObject, ObservableObject {
    // MARK: Shared Instance
    static let shared = WebSocketManager()
    
    private var token: String?
    
    private var session: URLSession?
    private var task: URLSessionWebSocketTask?
    
    @Published var messages = [String]()
    @Published var state = WebSocketState.disconnected
    
    override init() {
        print("init")
        
        super.init()
        
        connect()
    }
    
    deinit {
        disconnect()
    }
    
    func connect() {
        // disconnect 후 connect 시도시 (재연결)
        // resume 작동 안하는 이슈로 connect시 task 새로 만들도록 작업
        if task == nil, let url = URL(string: "\(BaseURL)") {
            var request = URLRequest(url: url)
            if let token = token, !token.isEmpty {
                request.addValue(token, forHTTPHeaderField: "Authorization")
            }
            
            session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
            task = session?.webSocketTask(with: request)
        }
        
        // 핸드쉐이킹 진행
        task?.resume()

        receiveMessage()
    }
    
    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }
    
    private func ping() {
        guard state == .connected else { return }
        
        // task connected 상태인 경우에만 ping...
        task?.sendPing(pongReceiveHandler: { error in
            if let error = error {
                print("Sending PING failed: \(error)")
            }
            
            print("Sending PING...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.ping()
            }
        })
    }
    
    private func receiveMessage() {
        // recive : Reads a WebSocket message once all the frames of the message are available.
        task?.receive { result in
            print("receive : \(result)")
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self.messages.append(text)
                    }
                case .data(let data):
                    DispatchQueue.main.async {
                        let text = String(decoding: data, as: UTF8.self)
                        self.messages.append(text)
                    }
                @unknown default:
                    break
                }
            }
            
            // 메시지 한 번 수신후 해제되기때문에 다시 receive 호출 필요.
            self.receiveMessage()
        }
    }
    
    func sendMessage(_ message: String, completionHandler: @escaping ((Error)?) -> Void) {
        print("sendMessage : \(message)")
        task?.send(.string(message), completionHandler: completionHandler)
    }
    
    func sendMessage(_ message: Data, completionHandler: @escaping ((Error)?) -> Void) {
        print("sendMessageData : \(message)")
        task?.send(.data(message), completionHandler: completionHandler)
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol prot: String?) {
        DispatchQueue.main.async {
            self.state = .connected
        }
        print("didOpenWithProtocol \(prot ?? "nil")")
        
        ping()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.state = .disconnected
        }
        print("didCloseWith \(String(describing: reason))")
    }
}
