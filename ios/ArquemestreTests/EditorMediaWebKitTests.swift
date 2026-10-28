import XCTest
import WebKit
@testable import Arquemestre

final class EditorMediaWebKitTests: XCTestCase {
    private final class Loaded: NSObject, WKNavigationDelegate {
        let ready: XCTestExpectation
        init(_ ready: XCTestExpectation) { self.ready = ready }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { ready.fulfill() }
    }

    @MainActor
    private func loadEditor(saved: String = "null") async throws -> WKWebView {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "EditorMediaBackup", withExtension: "js"))
        let script = try String(contentsOf: url, encoding: .utf8)
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.userContentController.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let web = WKWebView(frame: .zero, configuration: config)
        let ready = expectation(description: "editor carregado"), delegate = Loaded(ready)
        web.navigationDelegate = delegate
        web.loadHTMLString("""
        <html><body><script>
        window.saved = \(saved); window.records = []; window.notices = [];
        window.phPut = function(o, cb) { records.push(o); if(cb) cb(); };
        window.phDel = function() {};
        window.phAll = function(cb) { cb(records); };
        window.toast = function(t) { notices.push(t); };
        window.ArqueApp = {
          putVideo: function(j) { saved = JSON.parse(j); return true; },
          listFiles: function() { return saved ? '["video_v1.json"]' : '[]'; },
          getFile: function() { return btoa(unescape(encodeURIComponent(JSON.stringify(saved)))); },
          delFile: function() { saved = null; }
        };
        </script></body></html>
        """, baseURL: nil)
        await fulfillment(of: [ready], timeout: 15)
        web.navigationDelegate = nil
        _ = delegate
        return web
    }

    @MainActor
    func testFileReaderPersistsVideoBeforeSuccessInRealWebKit() async throws {
        let web = try await loadEditor()
        let result = try await web.callAsyncJavaScript("""
          return await new Promise(resolve => {
            phPut({id:'v1', pid:'p1', kind:'video', nome:'área.mov',
              blob:new Blob([new Uint8Array([1,2,3])], {type:'video/quicktime'})},
              () => resolve(saved.videoData));
          });
          """, arguments: [:], in: nil, contentWorld: .page)
        XCTAssertEqual(result as? String, "data:video/quicktime;base64,AQID")
    }

    @MainActor
    func testNativeVideoRestoresAsPlayableBlobInRealWebKit() async throws {
        let saved = #"{"id":"v1","pid":"p1","kind":"video","nome":"área.mov","videoData":"data:video/quicktime;base64,AQID"}"#
        let web = try await loadEditor(saved: saved)
        let result = try await web.callAsyncJavaScript("""
          const o = records[0];
          return JSON.stringify({nome:o.nome, type:o.blob.type,
            bytes:Array.from(new Uint8Array(await o.blob.arrayBuffer()))});
          """, arguments: [:], in: nil, contentWorld: .page)
        let json = try XCTUnwrap(result as? String)
        let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        XCTAssertEqual(obj["nome"] as? String, "área.mov")
        XCTAssertEqual(obj["type"] as? String, "video/quicktime")
        XCTAssertEqual(obj["bytes"] as? [Int], [1, 2, 3])
    }
}
