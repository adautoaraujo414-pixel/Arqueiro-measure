package com.arque.measure;

import android.annotation.SuppressLint;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanSettings;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.os.ParcelUuid;
import org.json.JSONArray;
import org.json.JSONObject;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/** BLE only advertises a local IPv4 address; project bytes travel through ArqueLink Wi-Fi.
 * Sender must visibly activate sharing and receiver must enter the out-of-band 128-bit code.
 * Peer advertisements are untrusted: never auto-download/import a project. */
public final class ArqueLinkDiscovery {
    public interface Listener { void event(String event, String value); }
    public static final ParcelUuid SERVICE = new ParcelUuid(UUID.fromString("04e1b4a6-2615-4fa7-9e53-cc7c07bb67ba"));
    private final BluetoothAdapter adapter;
    private final Listener listener;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private BluetoothLeAdvertiser advertiser;
    private AdvertiseCallback adCallback;
    private BluetoothLeScanner scanner;
    private ScanCallback scanCallback;
    private final Map<String,String> peers = new LinkedHashMap<>();
    private int scanGeneration = 0;
    public ArqueLinkDiscovery(Context ctx,Listener listener){
        BluetoothManager bm=(BluetoothManager)ctx.getSystemService(Context.BLUETOOTH_SERVICE);
        adapter=bm==null?null:bm.getAdapter();this.listener=listener;
    }
    public boolean available(){return adapter!=null;}
    @SuppressLint("MissingPermission") public void advertise(String ipv4){
        stopAdvertising();
        try{
            if(adapter==null||!adapter.isEnabled())throw new IllegalStateException("Bluetooth desligado ou indisponível");
            byte[] address=InetAddress.getByName(ipv4).getAddress();
            if(address.length!=4 || !(InetAddress.getByName(ipv4) instanceof Inet4Address))throw new IllegalArgumentException("Wi-Fi local sem IPv4 válido");
            advertiser=adapter.getBluetoothLeAdvertiser();
            if(advertiser==null)throw new IllegalStateException("Este dispositivo não permite anúncio BLE");
            AdvertiseSettings settings=new AdvertiseSettings.Builder().setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM).setConnectable(false).build();
            AdvertiseData data=new AdvertiseData.Builder().setIncludeDeviceName(false)
                .addServiceData(SERVICE,address).build();
            adCallback=new AdvertiseCallback(){
                @Override public void onStartSuccess(AdvertiseSettings s){listener.event("discovery_status","Aparelho visível por Bluetooth; código continua obrigatório");}
                @Override public void onStartFailure(int error){listener.event("discovery_error","Anúncio Bluetooth falhou (código "+error+")");}
            };
            advertiser.startAdvertising(settings,data,adCallback);
        }catch(Exception e){listener.event("discovery_error",e.getMessage());}
    }
    @SuppressLint("MissingPermission") public void stopAdvertising(){
        if(advertiser!=null&&adCallback!=null)try{advertiser.stopAdvertising(adCallback);}catch(Exception ignored){}
        advertiser=null;adCallback=null;
    }
    @SuppressLint("MissingPermission") public void scan(){
        stopScan();peers.clear();
        try{
            if(adapter==null||!adapter.isEnabled())throw new IllegalStateException("Ative o Bluetooth para localizar aparelhos");
            scanner=adapter.getBluetoothLeScanner();if(scanner==null)throw new IllegalStateException("Busca BLE indisponível");
            scanCallback=new ScanCallback(){
                @Override public void onScanResult(int callbackType,ScanResult result){
                    if(result==null||result.getScanRecord()==null)return;
                    byte[] bytes=result.getScanRecord().getServiceData(SERVICE);
                    if(bytes==null||bytes.length!=4)return;
                    int[] oct=new int[4];for(int i=0;i<4;i++)oct[i]=bytes[i]&255;
                    String ip=oct[0]+"."+oct[1]+"."+oct[2]+"."+oct[3];
                    if(oct[0]==0||oct[0]>=224||"255.255.255.255".equals(ip))return;
                    String key=result.getDevice().getAddress();peers.put(key,ip);
                }
                @Override public void onScanFailed(int code){listener.event("discovery_error","Busca BLE falhou (código "+code+")");stopScan();}
            };
            scanner.startScan(null,new ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build(),scanCallback);
            listener.event("discovery_status","Buscando aparelhos com Arque Link ativo…");
            final int generation=++scanGeneration;
            handler.postDelayed(()->{
                if(generation!=scanGeneration)return;
                stopScan();JSONArray items=new JSONArray();
                for(Map.Entry<String,String> entry:peers.entrySet())try{
                    JSONObject item=new JSONObject();item.put("id",entry.getKey());item.put("ip",entry.getValue());items.put(item);
                }catch(Exception ignored){}
                listener.event("discovery_peers",items.toString());
            },8000);
        }catch(Exception e){listener.event("discovery_error",e.getMessage());}
    }
    @SuppressLint("MissingPermission") public void stopScan(){
        scanGeneration++;
        if(scanner!=null&&scanCallback!=null)try{scanner.stopScan(scanCallback);}catch(Exception ignored){}
        scanner=null;scanCallback=null;
    }
    public void close(){stopScan();stopAdvertising();}
}
