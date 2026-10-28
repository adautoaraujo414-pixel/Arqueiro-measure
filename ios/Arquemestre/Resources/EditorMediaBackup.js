/* iOS: mantém os vídeos do editor em arquivos incluídos no backup nativo.
   O editor compartilhado com Android permanece intacto. */
(function () {
  'use strict';
  var A = window.ArqueApp;
  if (!A || !A.putVideo || typeof window.phPut !== 'function') return;
  var put = window.phPut, del = window.phDel;
  var maxBytes = 64 * 1024 * 1024;
  var versions = Object.create(null);
  function failed() {
    if (typeof window.toast === 'function') window.toast('Não foi possível guardar o vídeo no backup. Tente um vídeo menor (até 64 MB).');
  }
  function persist(o, done) {
    if (!o.blob || o.blob.size > maxBytes) { done(false); return; }
    var version = versions[o.id] || 0;
    var reader = new FileReader();
    reader.onerror = reader.onabort = function () { done(false); };
    reader.onload = function () {
      // Não recria um vídeo que foi excluído ou atualizado enquanto o FileReader trabalhava.
      if ((versions[o.id] || 0) !== version) { done(null); return; }
      var copy = Object.assign({}, o);
      delete copy.blob;
      copy.videoData = reader.result;
      try { done(A.putVideo(JSON.stringify(copy)) === true); } catch (_) { done(false); }
    };
    try { reader.readAsDataURL(o.blob); } catch (_) { done(false); }
  }
  window.phPut = function (o, cb) {
    if (!o.blob) { put(o, cb); return; }
    versions[o.id] = (versions[o.id] || 0) + 1;
    persist(o, function (ok) {
      // Só confirma o salvamento depois que a cópia nativa estiver no disco.
      if (ok) put(o, cb); else if (ok === false) failed();
    });
  };
  window.phDel = function (id, cb) {
    versions[id] = (versions[id] || 0) + 1;
    try { A.delFile('video_' + id + '.json'); } catch (_) {}
    del(id, cb);
  };
  window.phAll(function (all) {
    var have = {};
    all.forEach(function (o) {
      have[o.id] = true;
      // Migração de vídeos já existentes no IndexedDB do iPhone.
      if (o.blob) persist(o, function (ok) { if (ok === false) failed(); });
    });
    var names;
    try { names = JSON.parse(A.listFiles() || '[]'); } catch (_) { return; }
    names.filter(function (n) { return /^video_.*\.json$/.test(n); }).forEach(function (name) {
      try {
        var o = JSON.parse(decodeURIComponent(escape(atob(A.getFile(name)))));
        if (have[o.id] || typeof o.videoData !== 'string') return;
        var comma = o.videoData.indexOf(','), header = o.videoData.slice(0, comma);
        if (comma < 0 || !/^data:[^,]*;base64$/.test(header)) return;
        var bytes = atob(o.videoData.slice(comma + 1));
        if (bytes.length > maxBytes) return;
        var buf = new Uint8Array(bytes.length);
        for (var i = 0; i < bytes.length; i++) buf[i] = bytes.charCodeAt(i);
        o.blob = new Blob([buf], {type: header.slice(5, -7) || 'application/octet-stream'});
        delete o.videoData;
        have[o.id] = true;
        put(o);
      } catch (_) { failed(); }
    });
  });
})();
