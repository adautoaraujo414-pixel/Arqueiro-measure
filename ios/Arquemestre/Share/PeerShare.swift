import Foundation
import MultipeerConnectivity
import UIKit

/// Ver o projeto de móveis ao vivo em outro iPhone/iPad por perto (Wi-Fi/Bluetooth ponto a ponto).
/// Quem compartilha manda o projeto inteiro a cada alteração; quem vê só recebe.
/// Entre iPhone e Android isso não funciona (o iOS não abre Bluetooth "clássico" para apps);
/// para Android ↔ iPhone, use o backup ZIP.
final class PeerShare: NSObject, ObservableObject {
    static let serviceType = "arque-proj"

    @Published private(set) var hosting = false
    @Published private(set) var viewers = 0
    @Published private(set) var viewState = "idle" // idle, browsing, connecting, connected, closed, error
    @Published private(set) var found: [MCPeerID] = []
    @Published private(set) var frame: String?
    @Published private(set) var viewFrom = ""

    private let me = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var last: Data?

    // ---- dono ----
    func startHost() {
        if hosting { return }
        let s = MCSession(peer: me, securityIdentity: nil, encryptionPreference: .required)
        s.delegate = self
        session = s
        let adv = MCNearbyServiceAdvertiser(peer: me, discoveryInfo: ["app": "arquemestre"], serviceType: PeerShare.serviceType)
        adv.delegate = self
        adv.startAdvertisingPeer()
        advertiser = adv
        hosting = true
    }

    func update(_ json: String) {
        guard hosting, let s = session else { return }
        guard let packed = try? (Data(json.utf8) as NSData).compressed(using: .zlib) as Data else { return }
        last = packed
        if !s.connectedPeers.isEmpty { try? s.send(packed, toPeers: s.connectedPeers, with: .reliable) }
    }

    func stopHost() {
        advertiser?.stopAdvertisingPeer(); advertiser = nil
        session?.disconnect(); session = nil
        hosting = false; viewers = 0; last = nil
    }

    // ---- quem vê ----
    func browse() {
        disconnect()
        let s = MCSession(peer: me, securityIdentity: nil, encryptionPreference: .required)
        s.delegate = self
        session = s
        let b = MCNearbyServiceBrowser(peer: me, serviceType: PeerShare.serviceType)
        b.delegate = self
        b.startBrowsingForPeers()
        browser = b
        found = []
        viewState = "browsing"
    }

    func connect(_ peer: MCPeerID) {
        guard let s = session, let b = browser else { return }
        viewFrom = peer.displayName
        viewState = "connecting"
        frame = nil
        b.invitePeer(peer, to: s, withContext: nil, timeout: 20)
    }

    func disconnect() {
        browser?.stopBrowsingForPeers(); browser = nil
        if !hosting { session?.disconnect(); session = nil }
        if viewState != "idle" { viewState = "idle" }
    }
}

extension PeerShare: MCSessionDelegate {
    func session(_ s: MCSession, peer: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            if self.hosting {
                self.viewers = s.connectedPeers.count
                if state == .connected, let b = self.last { try? s.send(b, toPeers: [peer], with: .reliable) }
            } else {
                switch state {
                case .connected: self.viewState = "connected"; self.browser?.stopBrowsingForPeers()
                case .connecting: self.viewState = "connecting"
                case .notConnected: self.viewState = self.viewState == "connecting" ? "error" : "closed"
                @unknown default: break
                }
            }
        }
    }

    func session(_ s: MCSession, didReceive data: Data, fromPeer peer: MCPeerID) {
        guard let raw = try? (data as NSData).decompressed(using: .zlib) as Data, let txt = String(data: raw, encoding: .utf8) else { return }
        DispatchQueue.main.async { self.frame = txt }
    }

    func session(_ s: MCSession, didReceive stream: InputStream, withName: String, fromPeer: MCPeerID) {}
    func session(_ s: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {}
    func session(_ s: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}
}

extension PeerShare: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ a: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peer: MCPeerID, withContext: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // só visualização: aceita quem pede para ver
        invitationHandler(true, session)
    }
}

extension PeerShare: MCNearbyServiceBrowserDelegate {
    func browser(_ b: MCNearbyServiceBrowser, foundPeer peer: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async { if !self.found.contains(peer) { self.found.append(peer) } }
    }
    func browser(_ b: MCNearbyServiceBrowser, lostPeer peer: MCPeerID) {
        DispatchQueue.main.async { self.found.removeAll { $0 == peer } }
    }
}
