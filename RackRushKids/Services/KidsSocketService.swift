import Foundation
import SocketIO

// MARK: - Kids Socket Service
/// Connects to server for safe kids-only online matchmaking
class KidsSocketService: ObservableObject {
    static let shared = KidsSocketService()
    
    @Published var isConnected = false
    @Published var isInQueue = false
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var deviceId: String
    
    // Callbacks
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    var onMatchFound: ((_ roomId: String, _ opponent: String, _ letters: [String]) -> Void)?
    var onRoundStart: ((_ round: Int, _ letters: [String], _ timer: Int) -> Void)?
    var onOpponentSubmitted: (() -> Void)?
    var onRoundResult: ((_ myWord: String, _ myScore: Int, _ oppWord: String, _ oppScore: Int, _ winner: String) -> Void)?
    var onMatchEnd: ((_ myTotal: Int, _ oppTotal: Int, _ winner: String) -> Void)?
    var onOpponentLeft: (() -> Void)?
    
    // Server URL - configurable per environment
    #if DEBUG
    private static let defaultServerURL = "http://localhost:3000"
    #else
    private static let defaultServerURL = "https://rackrush-server-production.up.railway.app"
    #endif
    
    private let serverURL: String
    
    private init() {
        // Initialize server URL
        self.serverURL = KidsSocketService.defaultServerURL
        
        // Get or create device ID
        self.deviceId = UserDefaults.standard.string(forKey: "kidsDeviceId") ?? {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: "kidsDeviceId")
            return id
        }()
    }
    
    func connect() {
        // Already connected
        if isConnected {
            onConnect?()
            return
        }
        
        // Already connecting
        if socket != nil {
            return
        }
        
        print("[KidsSocket] Connecting to \(serverURL)")
        
        manager = SocketManager(socketURL: URL(string: serverURL)!, config: [
            .log(false),
            .compress,
            .forceWebsockets(true),
            .forceNew(true),
            .reconnects(true),
            .reconnectWait(2)
        ])
        
        socket = manager?.defaultSocket
        setupHandlers()
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        manager = nil
        socket = nil
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    private func setupHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self = self else { return }
            print("[KidsSocket] Connected!")
            
            // Send hello message like adult app
            self.sendHello()
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("[KidsSocket] Disconnected")
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.isInQueue = false
                self?.onDisconnect?()
            }
        }
        
        socket?.on(clientEvent: .error) { data, _ in
            print("[KidsSocket] Error: \(data)")
        }
        
        // Handle all messages
        socket?.on("message") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let type = dict["type"] as? String else { return }
            
            print("[KidsSocket] Received: \(type)")
            
            DispatchQueue.main.async {
                self?.handleMessage(type: type, data: dict)
            }
        }
    }
    
    private func sendHello() {
        let playerName = UserDefaults.standard.string(forKey: "kidsPlayerName") ?? "KidsPlayer"
        
        let helloMessage: [String: Any] = [
            "type": "hello",
            "version": "1.0.0",
            "deviceId": deviceId,
            "playerName": playerName
        ]
        
        print("[KidsSocket] Sending hello: \(helloMessage)")
        socket?.emit("message", helloMessage)
        
        // Mark as connected after hello
        DispatchQueue.main.async {
            self.isConnected = true
            self.onConnect?()
        }
    }
    
    private func handleMessage(type: String, data: [String: Any]) {
        switch type {
        case "welcome":
            print("[KidsSocket] Server welcomed us!")
            
        case "matchFound":
            isInQueue = false
            let roomId = data["roomId"] as? String ?? ""
            let opponent = (data["opponent"] as? [String: Any])?["name"] as? String ?? "Friend"
            let letters = data["letters"] as? [String] ?? []
            onMatchFound?(roomId, opponent, letters)
            
        case "roundStart":
            let round = data["round"] as? Int ?? 1
            let letters = data["letters"] as? [String] ?? []
            let timer = data["timer"] as? Int ?? 30
            onRoundStart?(round, letters, timer)
            
        case "opponentSubmitted":
            onOpponentSubmitted?()
            
        case "roundResult":
            let submissions = data["submissions"] as? [[String: Any]] ?? []
            var myWord = "", myScore = 0, oppWord = "", oppScore = 0
            
            for sub in submissions {
                let isMe = sub["isMe"] as? Bool ?? false
                let word = sub["word"] as? String ?? ""
                let score = sub["score"] as? Int ?? 0
                if isMe {
                    myWord = word
                    myScore = score
                } else {
                    oppWord = word
                    oppScore = score
                }
            }
            
            let winner = data["winner"] as? String ?? ""
            onRoundResult?(myWord, myScore, oppWord, oppScore, winner)
            
        case "matchEnd":
            let myTotal = data["myTotal"] as? Int ?? 0
            let oppTotal = data["oppTotal"] as? Int ?? 0
            let winner = data["winner"] as? String ?? ""
            onMatchEnd?(myTotal, oppTotal, winner)
            
        case "opponentLeft":
            onOpponentLeft?()
            
        default:
            print("[KidsSocket] Unknown message type: \(type)")
        }
    }
    
    // MARK: - Actions
    
    func joinKidsQueue(ageGroup: String, letterCount: Int, timerSeconds: Int) {
        guard isConnected else {
            print("[KidsSocket] Cannot queue - not connected")
            return
        }
        
        isInQueue = true
        
        let kidsSettings: [String: Any] = [
            "isKidsMode": true,
            "ageGroup": ageGroup,
            "letterCount": letterCount,
            "timerSeconds": timerSeconds
        ]
        
        let queueMessage: [String: Any] = [
            "type": "queue",
            "mode": letterCount,
            "matchType": "pvp",
            "kidsMode": kidsSettings
        ]
        
        print("[KidsSocket] Joining queue: \(queueMessage)")
        socket?.emit("message", queueMessage)
    }
    
    func submitWord(_ word: String) {
        let submitMessage: [String: Any] = [
            "type": "submit",
            "word": word
        ]
        socket?.emit("message", submitMessage)
    }
    
    func leave() {
        isInQueue = false
        socket?.emit("message", ["type": "leave"])
    }
}
