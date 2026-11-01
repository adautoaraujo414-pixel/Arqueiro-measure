#!/usr/bin/env python3
"""Conferência do que a Apple costuma recusar na revisão (roda no CI antes de compilar).

Não substitui a revisão da Apple nem um teste num iPhone de verdade: confere no código e nos arquivos
os pontos que mais dão recusa (permissões, privacidade, assinatura, ícone, iPad, textos de outra plataforma).
Sai com código 1 se achar algum problema.
"""
import json, os, plistlib, re, struct, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
IOS = os.path.join(ROOT, 'ios')
APP = os.path.join(IOS, 'Arquemestre')
RES = os.path.join(APP, 'Resources')
EDITOR = os.path.join(ROOT, 'app', 'src', 'main', 'assets', 'editor.html')
problems, notes = [], []


def bad(msg):
    problems.append(msg)


def ok(msg):
    notes.append(msg)


def swift_sources():
    out = {}
    for d, _, fs in os.walk(APP):
        for f in fs:
            if f.endswith('.swift'):
                p = os.path.join(d, f)
                out[os.path.relpath(p, ROOT)] = open(p, encoding='utf-8').read()
    return out


def strip_swift_comments(s):
    s = re.sub(r'/\*.*?\*/', '', s, flags=re.S)
    return '\n'.join(re.sub(r'(^|[^:])//.*$', r'\1', l) for l in s.split('\n'))


SRC = swift_sources()
CODE = {k: strip_swift_comments(v) for k, v in SRC.items()}
ALL = '\n'.join(CODE.values())
info = plistlib.load(open(os.path.join(RES, 'Info.plist'), 'rb'))
proj = open(os.path.join(IOS, 'project.yml'), encoding='utf-8').read()

# ---------- 1. Info.plist básico ----------
for k in ['CFBundleDisplayName', 'CFBundleShortVersionString', 'CFBundleVersion', 'LSRequiresIPhoneOS', 'UILaunchScreen']:
    if k not in info:
        bad(f'Info.plist sem {k}')
if info.get('ITSAppUsesNonExemptEncryption') is not False:
    bad('Info.plist: ITSAppUsesNonExemptEncryption tem que ser false (o app só usa a criptografia do sistema)')
lc = (info.get('UILaunchScreen') or {}).get('UIColorName')
if lc is not None:
    if not lc:
        bad('Info.plist: UILaunchScreen.UIColorName vazio')
    elif not os.path.isdir(os.path.join(RES, 'Assets.xcassets', lc + '.colorset')):
        bad(f'Info.plist: cor da tela de abertura "{lc}" não existe no Assets.xcassets')
m = re.search(r'MARKETING_VERSION:\s*"([^"]+)"', proj)
if not m or not re.fullmatch(r'\d+\.\d+(\.\d+)?', m.group(1)):
    bad('project.yml: MARKETING_VERSION tem que ser tipo 1.0.0')
m = re.search(r'iOS:\s*"(\d+)\.', proj)
if not m or int(m.group(1)) < 15:
    bad('project.yml: versão mínima do iOS muito antiga')
ok('Info.plist e versão conferidos')

# ---------- 2. Permissões: cada recurso usado precisa do texto explicando o porquê ----------
USES = [
    (r'\bCBCentralManager\b|\bCBPeripheralManager\b', 'NSBluetoothAlwaysUsageDescription', 'Bluetooth'),
    (r'sourceType\s*=\s*\.camera|\.camera\b.*UIImagePicker|AVCaptureDevice|capture=|getUserMedia', 'NSCameraUsageDescription', 'câmera'),
    (r'kUTTypeMovie|UTType\.movie|public\.movie|mediaTypes.*movie|AVAudioSession|AVAudioRecorder', 'NSMicrophoneUsageDescription', 'microfone'),
    (r'UIImageWriteToSavedPhotosAlbum|UISaveVideoAtPathToSavedPhotosAlbum|PHAssetCreationRequest|PHAssetChangeRequest', 'NSPhotoLibraryAddUsageDescription', 'salvar na galeria'),
    (r'PHPhotoLibrary\.requestAuthorization\(|PHAsset\.fetchAssets', 'NSPhotoLibraryUsageDescription', 'ler a galeria'),
    (r'MCNearbyServiceBrowser|MCNearbyServiceAdvertiser|NWBrowser|NetService', 'NSLocalNetworkUsageDescription', 'rede local'),
    (r'CLLocationManager', 'NSLocationWhenInUseUsageDescription', 'localização'),
    (r'CNContactStore', 'NSContactsUsageDescription', 'contatos'),
    (r'EKEventStore', 'NSCalendarsFullAccessUsageDescription', 'calendário'),
    (r'LAContext', 'NSFaceIDUsageDescription', 'Face ID'),
    (r'SFSpeechRecognizer', 'NSSpeechRecognitionUsageDescription', 'reconhecimento de voz'),
]
editor = open(EDITOR, encoding='utf-8').read()
for pat, key, what in USES:
    used = re.search(pat, ALL) or (key == 'NSCameraUsageDescription' and re.search(r'capture=|getUserMedia', editor))
    if used:
        txt = info.get(key, '')
        if not isinstance(txt, str) or len(txt.strip()) < 25:
            bad(f'usa {what} mas o Info.plist não explica o porquê ({key})')
if re.search(r'MCNearbyService', ALL) and not info.get('NSBonjourServices'):
    bad('MultipeerConnectivity sem NSBonjourServices no Info.plist')
for k, v in info.items():
    if k.endswith('UsageDescription') and (not isinstance(v, str) or len(v.strip()) < 25):
        bad(f'{k} curto ou vazio')
ok('textos das permissões conferidos')

# ---------- 3. iPad ----------
if '"1,2"' in proj or "'1,2'" in proj:
    o = info.get('UISupportedInterfaceOrientations~ipad', [])
    if len(set(o)) < 4 and not info.get('UIRequiresFullScreen'):
        bad('iPad: precisa das 4 orientações (ou UIRequiresFullScreen)')
    ok('roda no iPad com as 4 orientações')

# ---------- 4. Ícone 1024 sem transparência ----------
iconset = os.path.join(RES, 'Assets.xcassets', 'AppIcon.appiconset')
cj = json.load(open(os.path.join(iconset, 'Contents.json')))
big = [i for i in cj.get('images', []) if i.get('size') == '1024x1024' and i.get('filename')]
if not big:
    bad('ícone 1024×1024 faltando')
for i in big:
    b = open(os.path.join(iconset, i['filename']), 'rb').read(33)
    if b[:8] != b'\x89PNG\r\n\x1a\n':
        bad('ícone não é PNG')
        continue
    w, h, depth, ctype = struct.unpack('>IIBB', b[16:26])
    if (w, h) != (1024, 1024):
        bad(f'ícone com {w}×{h} (tem que ser 1024×1024)')
    if ctype in (4, 6):
        bad('ícone com transparência (a App Store recusa: ITMS-90717)')
ok('ícone 1024 sem transparência')

# ---------- 5. Manifesto de privacidade: cada API "de motivo obrigatório" usada tem que estar declarada ----------
pm_path = os.path.join(RES, 'PrivacyInfo.xcprivacy')
if not os.path.exists(pm_path):
    bad('falta o PrivacyInfo.xcprivacy')
else:
    pm = plistlib.load(open(pm_path, 'rb'))
    if pm.get('NSPrivacyTracking') is not False:
        bad('PrivacyInfo: NSPrivacyTracking tem que ser false (o app não rastreia)')
    decl = {d.get('NSPrivacyAccessedAPIType'): d.get('NSPrivacyAccessedAPITypeReasons', []) for d in pm.get('NSPrivacyAccessedAPITypes', [])}
    REQ = [
        (r'UserDefaults|@AppStorage', 'NSPrivacyAccessedAPICategoryUserDefaults'),
        (r'systemUptime|mach_absolute_time', 'NSPrivacyAccessedAPICategorySystemBootTime'),
        (r'creationDate|modificationDate|contentModificationDateKey|creationDateKey|attributesOfItem|\.fileModificationDate', 'NSPrivacyAccessedAPICategoryFileTimestamp'),
        (r'volumeAvailableCapacity|systemFreeSize|NSFileSystemFreeSize|statfs', 'NSPrivacyAccessedAPICategoryDiskSpace'),
        (r'activeInputModes', 'NSPrivacyAccessedAPICategoryActiveKeyboards'),
    ]
    for pat, cat in REQ:
        if re.search(pat, ALL) and not decl.get(cat):
            bad(f'PrivacyInfo: o código usa {cat.replace("NSPrivacyAccessedAPICategory", "")} e não declarou o motivo')
    ok('manifesto de privacidade cobre as APIs usadas')

# ---------- 6. Assinatura (regras 3.1.1 e 3.1.2) ----------
sk = json.load(open(os.path.join(RES, 'Arquemestre.storekit'), encoding='utf-8'))
subs = [s for g in sk.get('subscriptionGroups', []) for s in g.get('subscriptions', [])]
pid = re.search(r'"(arquemestre_[a-z_]+)"', ALL)
if not pid:
    bad('não achei o ID do produto da assinatura no código')
elif not any(s.get('productID') == pid.group(1) for s in subs):
    bad(f'o ID {pid.group(1)} não está no Arquemestre.storekit')
for s in subs:
    if s.get('recurringSubscriptionPeriod') != 'P1M':
        bad('assinatura tem que ser mensal (P1M)')
    if str(s.get('displayPrice')) not in ('29.90', '29.9'):
        bad(f'preço da assinatura no .storekit é {s.get("displayPrice")} (combinado: R$ 29,90)')
    io = s.get('introductoryOffer') or {}
    if io.get('paymentMode') != 'free' or io.get('subscriptionPeriod') != 'P3D':
        bad('oferta introdutória tem que ser 3 dias grátis (free, P3D)')
need = {
    'restaurar compras': r'AppStore\.sync\(\)',
    'gerenciar assinatura': r'showManageSubscriptions|manageSubscriptionsSheet|apps\.apple\.com/account/subscriptions',
    'link dos Termos de uso (EULA)': r'apple\.com/legal/internet-services/itunes/dev/stdeula|[Tt]ermos',
    'link da Política de privacidade': r'privacidade\.html|privacy\.html',
    'texto da renovação automática': r'renova',
}
for what, pat in need.items():
    if not re.search(pat, ALL):
        bad(f'tela de assinatura sem {what}')
# nada de senha, compra por fora ou preço diferente no iPhone
for pat, why in [(r'149[,.]90', 'preço da versão do site'), (r'senha de desbloqueio|digite a senha|desbloquear com senha', 'desbloqueio por senha'),
                 (r'\bpix\b|\bboleto\b|mercado ?pago|pagseguro', 'pagamento por fora da Apple')]:
    for f, c in CODE.items():
        if re.search(pat, c, re.I):
            bad(f'{f}: {why} (regra 3.1.1)')
ok('assinatura mensal R$ 29,90 com 3 dias grátis, restaurar, gerenciar, termos e privacidade')

# ---------- 7. Textos que o usuário vê: sem outra plataforma, sem "beta", sem texto de exemplo ----------
FORBID = r'\bAndroid\b|Google Play|Play Store|\bAPK\b|\bbeta\b|lorem ipsum'
FORBID_CS = re.compile(r'\bTODO\b|\bFIXME\b|\bXXX\b')
lit = re.compile(r'(?:tr|Text|Button|Label|TextField|Section|navigationTitle|toast\s*=)\(\s*"((?:[^"\\]|\\.)*)"')
for f, c in CODE.items():
    for m in lit.finditer(c):
        if re.search(FORBID, m.group(1), re.I) or FORBID_CS.search(m.group(1)):
            bad(f'{f}: texto na tela fala "{m.group(1)[:60]}" (regra 2.3.10: sem outras plataformas/beta)')
vis = re.sub(r'/\*.*?\*/', '', editor, flags=re.S)
vis = re.sub(r'<!--.*?-->', '', vis, flags=re.S)
for m in re.finditer(FORBID, vis, re.I):
    ctx = vis[max(0, m.start() - 60):m.end() + 60].replace('\n', ' ')
    if re.search(r'//[^\n]*$', vis[max(0, m.start() - 200):m.start()]):
        continue
    bad(f'editor.html mostra "{m.group(0)}": …{ctx}…')
tr_en = json.load(open(os.path.join(ROOT, 'app', 'src', 'main', 'assets', 'i18n', 'en.json'), encoding='utf-8'))
tr_es = json.load(open(os.path.join(ROOT, 'app', 'src', 'main', 'assets', 'i18n', 'es.json'), encoding='utf-8'))
keys = set(m.group(1) for c in CODE.values() for m in re.finditer(r'tr\(\s*"((?:[^"\\]|\\.)*)"', c))
for k in keys:
    for d in (tr_en, tr_es):
        v = d.get(k)
        if v and re.search(FORBID, v, re.I):
            bad(f'tradução de "{k[:50]}" fala de outra plataforma: "{v[:60]}"')
ok('nenhum texto na tela fala de Android/Play/APK/beta')

# ---------- 8. Links: só https e páginas que existem ----------
for f, c in CODE.items():
    for m in re.finditer(r'"(http://[^"]+)"', c):
        if 'www.w3.org' not in m.group(1):
            bad(f'{f}: link sem https ({m.group(1)})')
pages = set(re.findall(r'github\.io/Arqueiro-measure/([a-z\-]+\.html)', ALL))
for p in pages:
    if not os.path.exists(os.path.join(ROOT, 'docs', p)):
        bad(f'o app abre a página {p}, mas ela não existe em docs/')
for p in ['privacidade.html', 'privacy.html', 'privacidad.html', 'suporte.html', 'support.html', 'soporte.html']:
    if not os.path.exists(os.path.join(ROOT, 'docs', p)):
        bad(f'falta docs/{p} (link obrigatório na ficha da App Store)')
ok(f'links conferidos ({len(pages)} páginas do site usadas no app)')

# ---------- 9. Atalhos de teste não podem ficar ligados na versão da loja ----------
for f, c in SRC.items():
    if 'ProcessInfo.processInfo.arguments' in c:
        body = re.sub(r'#if DEBUG.*?#endif', '', c, flags=re.S)
        for m in re.finditer(r'ProcessInfo\.processInfo\.arguments\.contains\("(-[A-Za-z]+)"\)', body):
            if m.group(1) in ('-trialOffer', '-unlock', '-pro', '-free') or (m.group(1) == '-demo' and 'License' in f):
                ctx = body[max(0, m.start() - 200):m.start()]
                if 'isDemo' not in ctx and 'DEBUG' not in ctx:
                    bad(f'{f}: atalho {m.group(1)} funciona fora do modo de teste')
ok('atalhos de teste só no DEBUG')

print('\n'.join('✓ ' + n for n in notes))
if problems:
    print('\nPROBLEMAS (a Apple pode recusar):')
    print('\n'.join('✗ ' + p for p in problems))
    sys.exit(1)
print('\nTudo certo: nenhum dos pontos que mais dão recusa na App Store.')
