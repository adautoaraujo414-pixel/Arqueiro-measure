import Foundation
import MultipeerConnectivity
import UIKit

/// Ver o projeto de móveis ao vivo em outro iPhone/iPad por perto (Wi-Fi/Bluetooth ponto a ponto).
/// Quem compartilha manda o projeto inteiro a cada alteração; quem vê só recebe.
/// Entre iPhone e Android isso não funciona (o iOS não abre Bluetooth "clássico" para apps);
/// para Android ↔ iPhone, use o backup ZIP.
/// Só aparece Arquemestre: a busca é pelo serviço "arque-proj" do próprio app (outros aparelhos e Bluetooth
/// nunca aparecem) e quem compartilha aparece como "Arquemestre · Empresa".
final class PeerShare: NSObject, ObservableObject {
    static let serviceType = "arque-proj"
    static let prefix = "Arquemestre"

    /// "Arquemestre · Marcenaria X" (sem empresa cadastrada: "Arquemestre · iPhone"). Máximo de 63 bytes (regra do MCPeerID).
    static func shareName(_ company: String) -> String {
        let who = company.trimmingCharacters(in: .whitespacesAndNewlines)
        var n = prefix + " · " + (who.isEmpty ? UIDevice.current.model : who)
        while n.utf8.count > 63 { n.removeLast() }
        return n
    }

    @Published private(set) var hosting = false
    @Published private(set) var viewers = 0
    @Published private(set) var viewState = "idle" // idle, browsing, connecting, connected, closed, error
    @Published private(set) var found: [MCPeerID] = []
    @Published private(set) var frame: String?
    @Published private(set) var viewFrom = ""

    private var me = MCPeerID(displayName: PeerShare.shareName(""))
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var last: Data?
    private var pendingInvitation: UUID?
    private var answerInvitation: ((Bool) -> Void)?
    private weak var invitationAlert: UIAlertController?

    // Separado da apresentação para testar aceitação, recusa e encerramento da sessão.
    var requestViewerApproval: ((String, @escaping (Bool) -> Void) -> Void)?

    private func finishInvitation(_ allowed: Bool) {
        let answer = answerInvitation
        answerInvitation = nil; pendingInvitation = nil
        invitationAlert?.dismiss(animated: true); invitationAlert = nil
        answer?(allowed)
    }

    // ---- dono ----
    func startHost(company: String = "") {
        if hosting { return }
        me = MCPeerID(displayName: PeerShare.shareName(company))
        let s = MCSession(peer: me, securityIdentity: nil, encryptionPreference: .required)
        s.delegate = self
        session = s
        let adv = MCNearbyServiceAdvertiser(peer: me, discoveryInfo: ["app": "arquemestre", "nome": String(company.prefix(40))], serviceType: PeerShare.serviceType)
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
        finishInvitation(false)
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
        viewFrom = PeerShare.display(peer)
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
        DispatchQueue.main.async {
            guard self.hosting, a === self.advertiser, let session = self.session,
                  self.pendingInvitation == nil else { invitationHandler(false, nil); return }
            let token = UUID()
            self.pendingInvitation = token
            self.answerInvitation = { [weak self, weak session] allowed in
                guard let self = self, let session = session,
                      allowed, self.hosting, self.session === session else {
                    invitationHandler(false, nil); return
                }
                invitationHandler(true, session)
            }
            let answer: (Bool) -> Void = { [weak self] allowed in
                DispatchQueue.main.async {
                    guard self?.pendingInvitation == token else { return }
                    self?.finishInvitation(allowed)
                }
            }
            if let approve = self.requestViewerApproval {
                approve(peer.displayName, answer)
            } else {
                guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }),
                      var presenter = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                    self.finishInvitation(false); return
                }
                while let top = presenter.presentedViewController { presenter = top }
                guard presenter.viewIfLoaded?.window != nil, !presenter.isBeingDismissed else {
                    self.finishInvitation(false); return
                }
                let alert = UIAlertController(title: tr("Permitir visualização do projeto?"),
                    message: tr("{0} quer ver este projeto e os dados do cliente ao vivo. Permita apenas se reconhecer o aparelho.", peer.displayName), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: tr("Não permitir"), style: .cancel) { _ in answer(false) })
                alert.addAction(UIAlertAction(title: tr("Permitir"), style: .default) { _ in answer(true) })
                self.invitationAlert = alert
                presenter.present(alert, animated: true)
            }
            // O convite do outro aparelho expira em 20 s; nunca deixa uma autorização pendente.
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                guard self.pendingInvitation == token else { return }
                self.finishInvitation(false)
            }
        }
    }
}

extension PeerShare: MCNearbyServiceBrowserDelegate {
    func browser(_ b: MCNearbyServiceBrowser, foundPeer peer: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // só o Arquemestre compartilhando (o serviço já é do app; confere a marca também)
        guard info?["app"] == "arquemestre" else { return }
        DispatchQueue.main.async { if !self.found.contains(peer) { self.found.append(peer) } }
    }

    /// Nome pra mostrar na lista: sempre começa com "Arquemestre".
    static func display(_ p: MCPeerID) -> String {
        p.displayName.hasPrefix(prefix) ? p.displayName : prefix + " · " + p.displayName
    }
    func browser(_ b: MCNearbyServiceBrowser, lostPeer peer: MCPeerID) {
        DispatchQueue.main.async { self.found.removeAll { $0 == peer } }
    }
}

