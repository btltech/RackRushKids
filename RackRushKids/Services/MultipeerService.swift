import Foundation
import MultipeerConnectivity

// MARK: - Multipeer Message Types
enum PartyMultipeerMessage: Codable {
    case playerJoined(name: String, colorHex: String)
    case playerLeft(peerId: String)
    case gameSettings(letterCount: Int, rounds: Int)
    case startGame
    case roundStart(roundNumber: Int, rack: [String], bonuses: [(Int, String)])
    case wordSubmitted(playerId: String, word: String, score: Int, time: Double, isValid: Bool)
    case roundEnd
    case gameEnd
    
    // Codable custom implementation for tuple
    enum CodingKeys: String, CodingKey {
        case type, name, colorHex, peerId, letterCount, rounds
        case roundNumber, rack, bonuses, playerId, word, score, time, isValid
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .playerJoined(let name, let colorHex):
            try container.encode("playerJoined", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(colorHex, forKey: .colorHex)
        case .playerLeft(let peerId):
            try container.encode("playerLeft", forKey: .type)
            try container.encode(peerId, forKey: .peerId)
        case .gameSettings(let letterCount, let rounds):
            try container.encode("gameSettings", forKey: .type)
            try container.encode(letterCount, forKey: .letterCount)
            try container.encode(rounds, forKey: .rounds)
        case .startGame:
            try container.encode("startGame", forKey: .type)
        case .roundStart(let roundNumber, let rack, let bonuses):
            try container.encode("roundStart", forKey: .type)
            try container.encode(roundNumber, forKey: .roundNumber)
            try container.encode(rack, forKey: .rack)
            let bonusStrings = bonuses.map { "\($0.0):\($0.1)" }
            try container.encode(bonusStrings, forKey: .bonuses)
        case .wordSubmitted(let playerId, let word, let score, let time, let isValid):
            try container.encode("wordSubmitted", forKey: .type)
            try container.encode(playerId, forKey: .playerId)
            try container.encode(word, forKey: .word)
            try container.encode(score, forKey: .score)
            try container.encode(time, forKey: .time)
            try container.encode(isValid, forKey: .isValid)
        case .roundEnd:
            try container.encode("roundEnd", forKey: .type)
        case .gameEnd:
            try container.encode("gameEnd", forKey: .type)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "playerJoined":
            let name = try container.decode(String.self, forKey: .name)
            let colorHex = try container.decode(String.self, forKey: .colorHex)
            self = .playerJoined(name: name, colorHex: colorHex)
        case "playerLeft":
            let peerId = try container.decode(String.self, forKey: .peerId)
            self = .playerLeft(peerId: peerId)
        case "gameSettings":
            let letterCount = try container.decode(Int.self, forKey: .letterCount)
            let rounds = try container.decode(Int.self, forKey: .rounds)
            self = .gameSettings(letterCount: letterCount, rounds: rounds)
        case "startGame":
            self = .startGame
        case "roundStart":
            let roundNumber = try container.decode(Int.self, forKey: .roundNumber)
            let rack = try container.decode([String].self, forKey: .rack)
            let bonusStrings = try container.decode([String].self, forKey: .bonuses)
            let bonuses = bonusStrings.compactMap { str -> (Int, String)? in
                let parts = str.split(separator: ":")
                guard parts.count == 2, let idx = Int(parts[0]) else { return nil }
                return (idx, String(parts[1]))
            }
            self = .roundStart(roundNumber: roundNumber, rack: rack, bonuses: bonuses)
        case "wordSubmitted":
            let playerId = try container.decode(String.self, forKey: .playerId)
            let word = try container.decode(String.self, forKey: .word)
            let score = try container.decode(Int.self, forKey: .score)
            let time = try container.decode(Double.self, forKey: .time)
            let isValid = try container.decode(Bool.self, forKey: .isValid)
            self = .wordSubmitted(playerId: playerId, word: word, score: score, time: time, isValid: isValid)
        case "roundEnd":
            self = .roundEnd
        case "gameEnd":
            self = .gameEnd
        default:
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unknown type"))
        }
    }
}

// MARK: - Network Party Player
struct NetworkPartyPlayer: Identifiable, Codable {
    let id: String  // peer displayName
    let name: String
    let colorHex: String
    var isHost: Bool = false
    var isReady: Bool = false
}

// MARK: - Multipeer Service
@MainActor
final class MultipeerService: NSObject, ObservableObject {
    
    // MARK: - Published State
    @Published var isHosting = false
    @Published var isBrowsing = false
    @Published var isConnected = false
    @Published var connectedPeers: [MCPeerID] = []
    @Published var lobbyPlayers: [NetworkPartyPlayer] = []
    @Published var availableHosts: [MCPeerID] = []
    @Published var errorMessage: String?
    
    // MARK: - Callbacks
    var onMessageReceived: ((PartyMultipeerMessage, MCPeerID) -> Void)?
    var onPlayerConnected: ((MCPeerID) -> Void)?
    var onPlayerDisconnected: ((MCPeerID) -> Void)?
    
    // MARK: - MultipeerConnectivity
    private let serviceType = "rackrush-party"
    private var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private var myName: String = ""
    private var myColorHex: String = ""
    
    // MARK: - Singleton
    static let shared = MultipeerService()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Setup
    
    func setup(playerName: String, colorHex: String) {
        myName = playerName
        myColorHex = colorHex
        peerID = MCPeerID(displayName: playerName)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        // Add self to lobby
        let selfPlayer = NetworkPartyPlayer(id: peerID.displayName, name: playerName, colorHex: colorHex, isHost: false, isReady: true)
        lobbyPlayers = [selfPlayer]
        
        print("🎮 MultipeerService setup: \(playerName)")
    }
    
    // MARK: - Host
    
    func startHosting() {
        guard session != nil else { return }
        
        stopAll()
        
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: ["name": myName], serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        isHosting = true
        lobbyPlayers[0].isHost = true
        
        print("🎮 Started hosting party")
    }
    
    // MARK: - Join
    
    func startBrowsing() {
        guard session != nil else { return }
        
        stopAll()
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        isBrowsing = true
        availableHosts = []
        
        print("🎮 Started browsing for parties")
    }
    
    func joinHost(_ hostPeer: MCPeerID) {
        guard let browser = browser else { return }
        browser.invitePeer(hostPeer, to: session, withContext: nil, timeout: 30)
        print("🎮 Requesting to join: \(hostPeer.displayName)")
    }
    
    // MARK: - Stop
    
    func stopAll() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        isHosting = false
        isBrowsing = false
    }
    
    func disconnect() {
        stopAll()
        session?.disconnect()
        connectedPeers = []
        lobbyPlayers = []
        isConnected = false
    }
    
    // MARK: - Send Message
    
    func send(_ message: PartyMultipeerMessage) {
        guard !connectedPeers.isEmpty else { return }
        
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: connectedPeers, with: .reliable)
            print("🎮 Sent: \(message)")
        } catch {
            print("🎮 Send error: \(error)")
        }
    }
    
    func sendTo(_ peer: MCPeerID, message: PartyMultipeerMessage) {
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("🎮 SendTo error: \(error)")
        }
    }
}

// MARK: - MCSessionDelegate
extension MultipeerService: MCSessionDelegate {
    
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                print("🎮 Connected: \(peerID.displayName)")
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                self.isConnected = true
                self.onPlayerConnected?(peerID)
                
                // If hosting, send our player info
                if self.isHosting {
                    self.sendTo(peerID, message: .playerJoined(name: self.myName, colorHex: self.myColorHex))
                }
                
            case .notConnected:
                print("🎮 Disconnected: \(peerID.displayName)")
                self.connectedPeers.removeAll { $0 == peerID }
                self.lobbyPlayers.removeAll { $0.id == peerID.displayName }
                self.isConnected = !self.connectedPeers.isEmpty
                self.onPlayerDisconnected?(peerID)
                
            case .connecting:
                print("🎮 Connecting: \(peerID.displayName)")
                
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            do {
                let message = try JSONDecoder().decode(PartyMultipeerMessage.self, from: data)
                print("🎮 Received from \(peerID.displayName): \(message)")
                
                // Handle player joined
                if case .playerJoined(let name, let colorHex) = message {
                    let player = NetworkPartyPlayer(id: peerID.displayName, name: name, colorHex: colorHex)
                    if !self.lobbyPlayers.contains(where: { $0.id == player.id }) {
                        self.lobbyPlayers.append(player)
                    }
                }
                
                self.onMessageReceived?(message, peerID)
            } catch {
                print("🎮 Decode error: \(error)")
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("🎮 Received invite from: \(peerID.displayName)")
        
        Task { @MainActor in
            // Auto-accept if room not full (max 4)
            if self.lobbyPlayers.count < 4 {
                invitationHandler(true, self.session)
            } else {
                invitationHandler(false, nil)
            }
        }
    }
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("🎮 Advertise error: \(error)")
        Task { @MainActor in
            self.errorMessage = "Failed to host: \(error.localizedDescription)"
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerService: MCNearbyServiceBrowserDelegate {
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🎮 Found host: \(peerID.displayName)")
        Task { @MainActor in
            if !self.availableHosts.contains(peerID) {
                self.availableHosts.append(peerID)
            }
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("🎮 Lost host: \(peerID.displayName)")
        Task { @MainActor in
            self.availableHosts.removeAll { $0 == peerID }
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("🎮 Browse error: \(error)")
        Task { @MainActor in
            self.errorMessage = "Failed to search: \(error.localizedDescription)"
        }
    }
}
