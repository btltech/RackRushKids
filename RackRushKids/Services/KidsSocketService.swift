import Foundation
import SocketIO

// MARK: - Kids Socket Service
/// Connects to server for safe kids-only online matchmaking
@MainActor
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
    var onError: ((_ message: String) -> Void)?
    var onMatchFound: ((_ roomId: String, _ opponent: String) -> Void)?
    var onRoundStart: ((_ round: Int, _ letters: [String], _ secondsRemaining: Int) -> Void)?
    var onOpponentSubmitted: (() -> Void)?
    var onRoundResult: ((_ myWord: String, _ myScore: Int, _ oppWord: String, _ oppScore: Int, _ winner: String, _ myTotal: Int, _ oppTotal: Int, _ roundNumber: Int, _ totalRounds: Int, _ nextRoundStartsAt: Int?) -> Void)?
    var onMatchEnd: ((_ myTotal: Int, _ oppTotal: Int, _ winner: String) -> Void)?
    var onOpponentReconnecting: ((_ timeLeftSeconds: Int) -> Void)?
    var onOpponentReconnected: (() -> Void)?
    
    // Server URL - use production for both DEBUG and RELEASE
    // (localhost:3000 is typically not running; Railway handles all matchmaking)
    #if DEBUG
    private static let defaultServerURL = "https://rackrush-server-production.up.railway.app"
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
        isInQueue = false
        isConnected = false
        onDisconnect?()
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
        case "error":
            let message = data["message"] as? String ?? "Unknown error"
            onError?(message)

        case "queued":
            isInQueue = true
            
        case "matchFound":
            isInQueue = false
            let roomId = data["roomId"] as? String ?? ""
            let opponent = (data["opponent"] as? [String: Any])?["name"] as? String ?? "Friend"
            onMatchFound?(roomId, opponent)
            
        case "roundStart":
            let round = data["round"] as? Int ?? 1
            let letters = data["letters"] as? [String] ?? []

            // Server sends absolute `endsAt` + `durationMs` so clients can derive accurate remaining time.
            let nowMs = Int(Date().timeIntervalSince1970 * 1000)
            let endsAt = data["endsAt"] as? Int ?? 0
            let durationMs = data["durationMs"] as? Int ?? 30000

            let fallbackSeconds = max(1, Int((Double(durationMs) / 1000.0).rounded(.up)))
            let secondsRemaining: Int
            if endsAt > 0 {
                secondsRemaining = max(0, Int((Double(endsAt - nowMs) / 1000.0).rounded(.up)))
            } else {
                secondsRemaining = fallbackSeconds
            }

            onRoundStart?(round, letters, secondsRemaining)
            
        case "opponentSubmitted":
            onOpponentSubmitted?()
            
        case "roundResult":
            let myWord = data["yourWord"] as? String ?? ""
            let myScore = data["yourScore"] as? Int ?? 0
            let oppWord = data["oppWord"] as? String ?? ""
            let oppScore = data["oppScore"] as? Int ?? 0
            let winner = data["winner"] as? String ?? ""
            let myTotal = data["yourTotalScore"] as? Int ?? 0
            let oppTotal = data["oppTotalScore"] as? Int ?? 0
            let roundNumber = data["roundNumber"] as? Int ?? 1
            let totalRounds = data["totalRounds"] as? Int ?? 1
            let nextRoundStartsAt = data["nextRoundStartsAt"] as? Int
            onRoundResult?(myWord, myScore, oppWord, oppScore, winner, myTotal, oppTotal, roundNumber, totalRounds, nextRoundStartsAt)

        case "matchResult":
            let myTotal = data["yourTotalScore"] as? Int ?? 0
            let oppTotal = data["oppTotalScore"] as? Int ?? 0
            let winner = data["winner"] as? String ?? ""
            onMatchEnd?(myTotal, oppTotal, winner)

        case "opponentReconnecting":
            let timeLeft = data["timeLeft"] as? Int ?? 0
            onOpponentReconnecting?(timeLeft)

        case "opponentReconnected":
            onOpponentReconnected?()

        case "stateSync":
            // Best-effort resume based on the state snapshot.
            let state = data["state"] as? String ?? ""
            switch state {
            case "match":
                let round = data["round"] as? Int ?? 1
                let letters = data["letters"] as? [String] ?? []
                let nowMs = Int(Date().timeIntervalSince1970 * 1000)
                let endsAt = data["endsAt"] as? Int ?? 0
                let durationMs = data["durationMs"] as? Int ?? 30000
                let fallbackSeconds = max(1, Int((Double(durationMs) / 1000.0).rounded(.up)))
                let secondsRemaining: Int
                if endsAt > 0 {
                    secondsRemaining = max(0, Int((Double(endsAt - nowMs) / 1000.0).rounded(.up)))
                } else {
                    secondsRemaining = fallbackSeconds
                }
                onRoundStart?(round, letters, secondsRemaining)

            case "roundResult":
                let myWord = data["yourWord"] as? String ?? ""
                let myScore = data["yourScore"] as? Int ?? 0
                let oppWord = data["oppWord"] as? String ?? ""
                let oppScore = data["oppScore"] as? Int ?? 0
                let winner = data["winner"] as? String ?? ""
                let myTotal = data["yourTotalScore"] as? Int ?? 0
                let oppTotal = data["oppTotalScore"] as? Int ?? 0
                let roundNumber = data["roundNumber"] as? Int ?? 1
                let totalRounds = data["totalRounds"] as? Int ?? 1
                let nextRoundStartsAt = data["nextRoundStartsAt"] as? Int
                onRoundResult?(myWord, myScore, oppWord, oppScore, winner, myTotal, oppTotal, roundNumber, totalRounds, nextRoundStartsAt)

            case "matchResult":
                let myTotal = data["yourTotalScore"] as? Int ?? 0
                let oppTotal = data["oppTotalScore"] as? Int ?? 0
                let winner = data["winner"] as? String ?? ""
                onMatchEnd?(myTotal, oppTotal, winner)

            default:
                break
            }
            
        default:
            print("[KidsSocket] Unknown message type: \(type)")
        }
    }
    
    // MARK: - Actions
    
    func joinKidsQueue(ageGroup: KidsAgeGroup) {
        guard isConnected else {
            print("[KidsSocket] Cannot queue - not connected")
            return
        }
        
        isInQueue = true

        let kidsSettings: [String: Any] = [
            "kidsMode": true,
            "ageGroup": ageGroup.rawValue,
            "timerSeconds": ageGroup.timerSeconds,
            "letterCount": ageGroup.letterCount,
            "minWordLength": ageGroup.minWordLength,
            "roundsPerMatch": ageGroup.roundCount
        ]

        let queueMessage: [String: Any] = [
            "type": "queue",
            "mode": ageGroup.letterCount,
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
