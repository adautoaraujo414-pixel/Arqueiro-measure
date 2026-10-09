package com.arque.measure;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Environment;
import android.net.Uri;
import android.provider.MediaStore;
import android.content.ContentValues;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import java.io.ByteArrayInputStream;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/** Offline WebView shell; no INTERNET permission; Android BLE bridge. Alpha: physical device validation required. */
public final class MainActivity extends Activity {
    private static final int REQUEST_BLE = 301, REQUEST_EXPORT = 302, REQUEST_IMPORT = 303, REQUEST_PICK = 304;
    private static final UUID BOSCH_CHAR = UUID.fromString("02a6c0d1-0451-4000-b000-fb3210111989");
    private static final UUID CCCD = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");
    private static final byte[] ENABLE = new byte[]{(byte)0xc0,0x55,0x02,0x01,0x00,0x1a};
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Map<String, BluetoothDevice> found = new LinkedHashMap<>();
    private WebView web;
    private BluetoothAdapter bluetooth;
    private BluetoothLeScanner scanner;
    private BluetoothGatt gatt;
    private BluetoothGattCharacteristic characteristic;
    private ScanCallback callback;
    private ValueCallback<Uri[]> fileCallback;
    private Uri cameraUri;
    private String pendingBackup;
    private boolean scanning = false;
    private ArqueLink link;
    private ArqueLinkDiscovery discovery;
    private static final int REQUEST_LINK_BLE = 305;

    @SuppressLint({"SetJavaScriptEnabled", "JavascriptInterface"})
    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        web = new WebView(this);
        setContentView(web);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(false);
        s.setAllowContentAccess(true);
        s.setAllowFileAccessFromFileURLs(false);
        s.setAllowUniversalAccessFromFileURLs(false);
        web.setWebViewClient(new WebViewClient(){
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request){return !"appassets.arque.invalid".equals(request.getUrl().getHost());}
            @Override public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request){
                Uri uri=request.getUrl();
                if(!"https".equals(uri.getScheme())||!"appassets.arque.invalid".equals(uri.getHost()))return denied();
                String path=uri.getPath();
                if(path==null)return denied();
                String name=path.startsWith("/")?path.substring(1):path;
                if(!name.equals("index.html")&&!name.equals("core.js")&&!name.equals("app.js")&&!name.equals("cut.js")&&!name.equals("styles.css"))return denied();
                String mime=name.endsWith(".js")?"text/javascript":name.endsWith(".css")?"text/css":"text/html";
                try{return new WebResourceResponse(mime,"UTF-8",getAssets().open(name));}catch(Exception e){return denied();}
            }
            private WebResourceResponse denied(){return new WebResourceResponse("text/plain","UTF-8",403,"Forbidden",new java.util.HashMap<String,String>(),new ByteArrayInputStream(new byte[0]));}
        });
        web.setWebChromeClient(new WebChromeClient(){
            @Override public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if(fileCallback!=null)fileCallback.onReceiveValue(null);
                fileCallback=callback;
                boolean cameraOnly = params != null && params.isCaptureEnabled();
                Intent gallery = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                gallery.addCategory(Intent.CATEGORY_OPENABLE);
                gallery.setType("image/*");
                Intent chooser = Intent.createChooser(gallery, "Foto do ambiente");
                try {
                    ContentValues values = new ContentValues();
                    values.put(MediaStore.Images.Media.DISPLAY_NAME,"arque-photo-"+System.currentTimeMillis()+".jpg");
                    values.put(MediaStore.Images.Media.MIME_TYPE,"image/jpeg");
                    cameraUri=getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values);
                    if(cameraUri!=null){
                        Intent camera = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
                        camera.putExtra(MediaStore.EXTRA_OUTPUT,cameraUri);
                        camera.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION|Intent.FLAG_GRANT_READ_URI_PERMISSION);
                        if(cameraOnly){chooser=camera;}else{chooser.putExtra(Intent.EXTRA_INITIAL_INTENTS,new Intent[]{camera});}
                    }
                    startActivityForResult(chooser, REQUEST_PICK); return true;
                } catch(Exception e){fileCallback=null;callback.onReceiveValue(null);return false;}
            }
        });
        web.addJavascriptInterface(new Bridge(),"ArqueNative");
        link=new ArqueLink((kind,value)->{
            if("status".equals(kind)&&value.startsWith("Transferência enviada"))handler.post(()->discovery.stopAdvertising());
            if("received".equals(kind))js("window.ArqueLinkReceive("+JSONObject.quote(value)+")");
            else js("window.ArqueLinkEvent("+JSONObject.quote(kind)+","+JSONObject.quote(value)+")");
        });
        discovery=new ArqueLinkDiscovery(this,(kind,value)->js("window.ArqueLinkDiscoveryEvent("+JSONObject.quote(kind)+","+JSONObject.quote(value)+")"));
        BluetoothManager bm = (BluetoothManager)getSystemService(Context.BLUETOOTH_SERVICE);
        bluetooth = bm == null ? null : bm.getAdapter();
        web.loadUrl("https://appassets.arque.invalid/index.html");
    }
    private boolean linkBlePermissions(boolean advertising){
        if(Build.VERSION.SDK_INT>=31){
            java.util.ArrayList<String> needed=new java.util.ArrayList<>();
            if(checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN)!=PackageManager.PERMISSION_GRANTED)needed.add(Manifest.permission.BLUETOOTH_SCAN);
            if(checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)!=PackageManager.PERMISSION_GRANTED)needed.add(Manifest.permission.BLUETOOTH_CONNECT);
            if(advertising&&checkSelfPermission(Manifest.permission.BLUETOOTH_ADVERTISE)!=PackageManager.PERMISSION_GRANTED)needed.add(Manifest.permission.BLUETOOTH_ADVERTISE);
            if(!needed.isEmpty()){
                requestPermissions(needed.toArray(new String[0]),REQUEST_LINK_BLE);
                js("window.ArqueLinkDiscoveryEvent(\"discovery_status\",\"Autorize os dispositivos próximos e toque novamente\")");
                return false;
            }
        }else if(checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)!=PackageManager.PERMISSION_GRANTED){
            requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION},REQUEST_LINK_BLE);
            return false;
        }
        return true;
    }
    private void js(String call){handler.post(()->{if(web!=null)web.evaluateJavascript(call,null);});}
    private void status(String value){js("window.ArqueBleStatus("+JSONObject.quote(value)+")");}
    private boolean permissions(){
        if(bluetooth==null){status("Bluetooth indisponível");return false;}
        if(Build.VERSION.SDK_INT>=31){
            if(checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN)!=PackageManager.PERMISSION_GRANTED||checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)!=PackageManager.PERMISSION_GRANTED){
                requestPermissions(new String[]{Manifest.permission.BLUETOOTH_SCAN,Manifest.permission.BLUETOOTH_CONNECT},REQUEST_BLE);return false;
            }
        }else if(checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)!=PackageManager.PERMISSION_GRANTED){
            requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION},REQUEST_BLE);return false;
        }
        if(!bluetooth.isEnabled()){status("Ative o Bluetooth");return false;}
        return true;
    }
    @SuppressLint("MissingPermission") private void startScan(){
        if(!permissions())return;
        stopScan(); found.clear(); scanner=bluetooth.getBluetoothLeScanner();
        if(scanner==null){status("Scanner BLE indisponível");return;}
        callback=new ScanCallback(){
            @Override public void onScanResult(int type,ScanResult result){
                BluetoothDevice d=result.getDevice();if(d!=null&&d.getAddress()!=null)found.put(d.getAddress(),d);
            }
            @Override public void onScanFailed(int error){status("Falha na busca BLE: "+error);}
        };
        try{scanner.startScan(callback);scanning=true;status("Procurando trena…");handler.postDelayed(()->{
            stopScan();JSONArray list=new JSONArray();
            for(BluetoothDevice d:found.values()){
                try{JSONObject item=new JSONObject();item.put("name",d.getName()==null?"Dispositivo BLE":d.getName());item.put("address",d.getAddress());list.put(item);}catch(Exception ignored){}
            }
            status("Busca concluída: "+list.length()+" dispositivos");js("window.ArqueBleDevices("+JSONObject.quote(list.toString())+")");
        },7000);}catch(SecurityException e){status("Permissão Bluetooth negada");}
    }
    @SuppressLint("MissingPermission") private void stopScan(){if(scanning&&scanner!=null&&callback!=null){try{scanner.stopScan(callback);}catch(Exception ignored){}}scanning=false;}
    @SuppressLint("MissingPermission") private void connect(String address){
        if(!permissions())return;
        BluetoothDevice d=found.get(address);
        if(d==null){status("Dispositivo não encontrado nesta busca");return;}
        disconnect();status("Conectando à trena…");
        try{gatt=d.connectGatt(this,false,new BluetoothGattCallback(){
            @Override public void onConnectionStateChange(BluetoothGatt g,int st,int newState){
                if(st!=BluetoothGatt.GATT_SUCCESS){status("Erro GATT: "+st);return;}
                if(newState==BluetoothProfile.STATE_CONNECTED){status("Conectada; descobrindo serviços…");g.discoverServices();}
                else if(newState==BluetoothProfile.STATE_DISCONNECTED)status("Trena desconectada");
            }
            @Override public void onServicesDiscovered(BluetoothGatt g,int st){
                if(st!=BluetoothGatt.GATT_SUCCESS){status("Falha ao descobrir serviços");return;}
                characteristic=null;
                for(BluetoothGattService service:g.getServices()){
                    BluetoothGattCharacteristic candidate=service.getCharacteristic(BOSCH_CHAR);
                    if(candidate!=null){characteristic=candidate;break;}
                }
                if(characteristic==null){status("Protocolo Bosch não encontrado");return;}
                boolean ok=g.setCharacteristicNotification(characteristic,true);
                BluetoothGattDescriptor descriptor=characteristic.getDescriptor(CCCD);
                if(ok&&descriptor!=null){descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);g.writeDescriptor(descriptor);}
                else if(ok){sendEnable(g);}else status("Não foi possível habilitar notificações");
            }
            @Override public void onDescriptorWrite(BluetoothGatt g,BluetoothGattDescriptor d,int status){
                if(status==BluetoothGatt.GATT_SUCCESS)sendEnable(g);else status("Falha ao ativar notificações");
            }
            @Override public void onCharacteristicChanged(BluetoothGatt g,BluetoothGattCharacteristic c){decode(c.getValue());}
            @Override public void onCharacteristicWrite(BluetoothGatt g,BluetoothGattCharacteristic c,int status){
                MainActivity.this.status(status==BluetoothGatt.GATT_SUCCESS?"Trena conectada; pronta para medir":"Comando BLE não aceito");
            }
        },BluetoothDevice.TRANSPORT_LE);}catch(Exception e){status("Erro ao conectar: "+e.getMessage());}
    }
    @SuppressLint("MissingPermission") private void sendEnable(BluetoothGatt g){
        if(characteristic==null)return;
        characteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        characteristic.setValue(ENABLE);
        if(!g.writeCharacteristic(characteristic))status("Não foi possível ativar transmissão");
    }
    private void decode(byte[] bytes){
        if(bytes==null||bytes.length<11|| (bytes[0]&255)!=0xc0||(bytes[1]&255)!=0x55||(bytes[2]&255)!=0x10||(bytes[3]&255)!=0x06)return;
        float meters=ByteBuffer.wrap(bytes,7,4).order(ByteOrder.LITTLE_ENDIAN).getFloat();
        if(!Float.isFinite(meters)||meters<0.05f||meters>50f)return;
        int millimeters=Math.round(meters*1000);
        js("window.ArqueBleMeasure("+millimeters+")");
    }
    @SuppressLint("MissingPermission") private void disconnect(){stopScan();if(gatt!=null){try{gatt.disconnect();gatt.close();}catch(Exception ignored){}gatt=null;}characteristic=null;status("● Offline");}
    public final class Bridge{
        @JavascriptInterface public void linkStart(String json){handler.post(()->{try{String code=link.start(json);JSONObject info=new JSONObject();info.put("ip",ArqueLink.localIp());info.put("code",code);js("window.ArqueLinkReady("+JSONObject.quote(info.toString())+")");
                if(linkBlePermissions(true))discovery.advertise(info.optString("ip"));}catch(Exception e){js("window.ArqueLinkEvent(\"error\","+JSONObject.quote(e.getMessage())+")");}});}
        @JavascriptInterface public void linkStop(){handler.post(()->{link.stop();discovery.stopAdvertising();js("window.ArqueLinkEvent(\"status\",\"Compartilhamento encerrado\")");});}
        @JavascriptInterface public void linkReceive(String ip,String code){link.receive(ip,code);}
        @JavascriptInterface public void linkAdvertise(){handler.post(()->{if(linkBlePermissions(true))discovery.advertise(ArqueLink.localIp());});}
        @JavascriptInterface public void linkDiscover(){handler.post(()->{if(linkBlePermissions(false))discovery.scan();});}
        @JavascriptInterface public void linkStopDiscover(){handler.post(()->discovery.stopScan());}
        @JavascriptInterface public void checkDevice(){handler.post(()->{
            try{
                JSONObject result=new JSONObject();
                PackageManager pm=getPackageManager();
                result.put("platform","Android");
                result.put("sdk",Build.VERSION.SDK_INT);
                result.put("cameraHardware",pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY));
                result.put("bleHardware",pm.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE));
                boolean bleGranted=Build.VERSION.SDK_INT>=31?
                    checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN)==PackageManager.PERMISSION_GRANTED &&
                    checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)==PackageManager.PERMISSION_GRANTED:
                    checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)==PackageManager.PERMISSION_GRANTED;
                result.put("bluetoothPermission",bleGranted);
                // Avoid isEnabled() without BLUETOOTH_CONNECT permission on Android 12+.
                result.put("bluetoothEnabled",bluetooth!=null && bleGranted && bluetooth.isEnabled());
                result.put("freeMegabytes",getFilesDir().getUsableSpace()/1048576L);
                js("window.ArqueDiagnostics("+JSONObject.quote(result.toString())+")");
            }catch(Exception e){status("Falha no diagnóstico: "+e.getMessage());}
        });}
        @JavascriptInterface public void scanBle(){handler.post(()->startScan());}
        @JavascriptInterface public void connectBle(String address){handler.post(()->connect(address));}
        @JavascriptInterface public void disconnectBle(){handler.post(()->disconnect());}
        @JavascriptInterface public void exportBackup(String data){handler.post(()->{
            pendingBackup=data;
            Intent i=new Intent(Intent.ACTION_CREATE_DOCUMENT);i.setType("application/json");i.addCategory(Intent.CATEGORY_OPENABLE);
            i.putExtra(Intent.EXTRA_TITLE,"arque-measure-"+System.currentTimeMillis()+".arque");startActivityForResult(i,REQUEST_EXPORT);
        });}
        @JavascriptInterface public void importBackup(){handler.post(()->{
            Intent i=new Intent(Intent.ACTION_OPEN_DOCUMENT);i.setType("*/*");i.addCategory(Intent.CATEGORY_OPENABLE);startActivityForResult(i,REQUEST_IMPORT);
        });}
    }
    @Override protected void onActivityResult(int req,int res,Intent data){super.onActivityResult(req,res,data);
        if(req==REQUEST_PICK){
            Uri chosen=res==RESULT_OK?(data!=null&&data.getData()!=null?data.getData():cameraUri):null;
            if(fileCallback!=null){fileCallback.onReceiveValue(chosen==null?null:new Uri[]{chosen});fileCallback=null;}
            if(cameraUri!=null && (chosen==null || !cameraUri.equals(chosen)))try{getContentResolver().delete(cameraUri,null,null);}catch(Exception ignored){}
            cameraUri=null;return;
        }
        if(res!=RESULT_OK||data==null||data.getData()==null)return;
        Uri uri=data.getData();
        if(req==REQUEST_EXPORT&&pendingBackup!=null){try(OutputStream out=getContentResolver().openOutputStream(uri)){
            if(out==null)throw new Exception("Arquivo indisponível");out.write(pendingBackup.getBytes(StandardCharsets.UTF_8));status("Backup exportado");
        }catch(Exception e){status("Erro ao exportar: "+e.getMessage());}finally{pendingBackup=null;}}
        if(req==REQUEST_IMPORT){try(InputStream in=getContentResolver().openInputStream(uri)){
            if(in==null)throw new Exception("Arquivo indisponível");ByteArrayOutputStream out=new ByteArrayOutputStream();byte[] buf=new byte[8192];int n;
            while((n=in.read(buf))!=-1){out.write(buf,0,n);if(out.size()>60_000_000)throw new Exception("Backup maior que 60 MB nesta versão");}
            String content=out.toString("UTF-8");js("window.ArqueReceiveBackup("+JSONObject.quote(content)+")");
        }catch(Exception e){status("Erro ao importar: "+e.getMessage());}}
    }
    @Override public void onRequestPermissionsResult(int req,String[] permissions,int[] results){super.onRequestPermissionsResult(req,permissions,results);if(req==REQUEST_BLE){boolean ok=true;for(int x:results)if(x!=PackageManager.PERMISSION_GRANTED)ok=false;status(ok?"Permissão concedida; toque em Buscar trena":"Permissão Bluetooth negada");}}
    @Override public void onBackPressed(){
        if(web==null){super.onBackPressed();return;}
        web.evaluateJavascript("window.ArqueAppBack && window.ArqueAppBack()", result -> {
            if(!"true".equals(result)) moveTaskToBack(true);
        });
    }
    @Override protected void onDestroy(){if(link!=null)link.shutdown();if(discovery!=null)discovery.close();disconnect();if(web!=null){web.removeJavascriptInterface("ArqueNative");web.destroy();}super.onDestroy();}
}
