const { test } = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');
const script = fs.readFileSync(path.join(__dirname, '../Arquemestre/Resources/EditorMediaBackup.js'), 'utf8');

function editor({ records = [], files = {}, failWrite = false } = {}) {
  const stored = new Map(records.map(o => [o.id, o]));
  const notices = [];
  class FileReader {
    readAsDataURL(blob) {
      blob.arrayBuffer().then(bytes => {
        this.result = `data:${blob.type || 'application/octet-stream'};base64,${Buffer.from(bytes).toString('base64')}`;
        this.onload();
      }).catch(() => this.onerror());
    }
  }
  const context = {
    Blob, Uint8Array, FileReader, atob, btoa, escape, unescape,
    phPut(o, cb) { stored.set(o.id, o); cb?.(); },
    phDel(id, cb) { stored.delete(id); cb?.(); },
    phAll(cb) { cb([...stored.values()]); },
    toast(message) { notices.push(message); },
    ArqueApp: {
      putVideo(json) {
        if (failWrite) return false;
        const o = JSON.parse(json); files[`video_${o.id}.json`] = json; return true;
      },
      delFile(name) { delete files[name]; },
      listFiles() { return JSON.stringify(Object.keys(files)); },
      getFile(name) { return Buffer.from(files[name]).toString('base64'); }
    }
  };
  context.window = context;
  vm.runInNewContext(script, context);
  return { context, stored, files, notices };
}
const drain = () => new Promise(resolve => setImmediate(resolve));
const video = () => ({ id: 'v1', pid: 'p1', kind: 'video', nome: 'área.mov', blob: new Blob([Buffer.from([1, 2, 3])], {type: 'video/quicktime'}) });

test('salva vídeo nativo antes de confirmar e recupera bytes após limpar IndexedDB', async () => {
  const e = editor(); let confirmed = false;
  e.context.phPut(video(), () => { assert.ok(e.files['video_v1.json']); confirmed = true; });
  await drain(); assert.equal(confirmed, true);
  const restored = editor({files: e.files});
  const o = restored.stored.get('v1');
  assert.equal(o.nome, 'área.mov'); assert.equal(o.pid, 'p1');
  assert.equal(o.blob.type, 'video/quicktime');
  assert.deepEqual(Buffer.from(await o.blob.arrayBuffer()), Buffer.from([1, 2, 3]));
});
test('migra vídeos existentes e remove cópia nativa ao excluir', async () => {
  const e = editor({records: [video()]}); await drain();
  assert.ok(e.files['video_v1.json']);
  e.context.phDel('v1'); assert.equal(e.files['video_v1.json'], undefined); assert.equal(e.stored.size, 0);
});
test('falha de disco não confirma salvamento e mostra aviso', async () => {
  const e = editor({failWrite: true}); let confirmed = false;
  e.context.phPut(video(), () => { confirmed = true; }); await drain();
  assert.equal(confirmed, false); assert.equal(e.stored.size, 0); assert.equal(e.notices.length, 1);
});
test('não modifica o fluxo de fotos e não substitui vídeo já existente', async () => {
  const existing = video();
  const e = editor({records: [existing], files: {'video_v1.json': '{invalid'}});
  const photo = {id: 'f1', data: 'data:image/jpeg;base64,AQID'};
  let done = false; e.context.phPut(photo, () => { done = true; });
  assert.equal(done, true); assert.equal(e.stored.get('f1'), photo);
  assert.equal(e.stored.get('v1'), existing); await drain();
});
test('rejeita vídeo acima do limite antes de ler o conteúdo', () => {
  const e = editor(); let done = false;
  e.context.phPut({id: 'large', kind: 'video', blob: {size: 64 * 1024 * 1024 + 1}}, () => { done = true; });
  assert.equal(done, false); assert.equal(e.notices.length, 1);
});
test('excluir durante migração não recria o vídeo no backup', async () => {
  const e = editor({records: [video()]});
  e.context.phDel('v1');
  await drain();
  assert.equal(e.files['video_v1.json'], undefined);
  assert.equal(e.stored.size, 0);
});
