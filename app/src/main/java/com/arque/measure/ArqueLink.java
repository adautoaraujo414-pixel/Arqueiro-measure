package com.arque.measure;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.util.*;
import java.util.concurrent.*;
import javax.crypto.*;
import javax.crypto.spec.*;

/** One-time, mutually user-approved encrypted project export over an existing local Wi-Fi network.
 * No cloud. Origin user must open sharing; receiver enters address + 128-bit secret shown on origin.
 * Never put secrets in HTTP URL/headers. The secret is used only to decrypt AES-GCM ciphertext.
 */
public final class ArqueLink {
    public interface Listener { void event(String event, String value); }
    public static final int PORT = 38741;
    public static final int MAX_BYTES = 24 * 1024 * 1024;
    private final ExecutorService io=Executors.newSingleThreadExecutor();
    private final Listener listener;
    private volatile ServerSocket server;
    private volatile String secret;
    private volatile byte[] packageBytes;
    private volatile boolean used;
    public ArqueLink(Listener listener){this.listener=listener;}

    public static String freshSecret(){byte[] b=new byte[16];new SecureRandom().nextBytes(b);StringBuilder out=new StringBuilder();for(byte x:b)out.append(String.format(Locale.ROOT,"%02X",x&255));return out.toString();}
    private static byte[] key(String secret)throws Exception{return MessageDigest.getInstance("SHA-256").digest(secret.getBytes(StandardCharsets.US_ASCII));}
    public static byte[] seal(byte[] source,String secret)throws Exception{
        byte[] nonce=new byte[12];new SecureRandom().nextBytes(nonce);
        Cipher cipher=Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE,new SecretKeySpec(key(secret),"AES"),new GCMParameterSpec(128,nonce));
        byte[] crypt=cipher.doFinal(source);byte[] result=new byte[nonce.length+crypt.length];
        System.arraycopy(nonce,0,result,0,12);System.arraycopy(crypt,0,result,12,crypt.length);return result;
    }
    public static byte[] open(byte[] encrypted,String secret)throws Exception{
        if(encrypted.length<29)throw new IOException("Pacote incompleto");
        Cipher cipher=Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE,new SecretKeySpec(key(secret),"AES"),new GCMParameterSpec(128,Arrays.copyOfRange(encrypted,0,12)));
        return cipher.doFinal(encrypted,12,encrypted.length-12);
    }
    public synchronized String start(String json)throws Exception{
        stop();byte[] bytes=json.getBytes(StandardCharsets.UTF_8);
        if(bytes.length>MAX_BYTES)throw new IOException("Projeto excede 24 MB; use backup por arquivo nesta versão");
        secret=freshSecret();packageBytes=seal(bytes,secret);used=false;
        server=new ServerSocket();server.setReuseAddress(true);server.bind(new InetSocketAddress(PORT));
        final ServerSocket active=server;
        io.execute(()->{
            listener.event("status","Compartilhamento ativo");
            try{
                while(!active.isClosed()&&!used){
                    Socket client=active.accept();client.setSoTimeout(6000);
                    try{
                        BufferedReader reader=new BufferedReader(new InputStreamReader(client.getInputStream(),StandardCharsets.US_ASCII));
                        String request=reader.readLine();
                        for(int n=0;n<30;n++){String line=reader.readLine();if(line==null||line.isEmpty())break;}
                        OutputStream out=client.getOutputStream();
                        if(!"GET /arque-link/v1 HTTP/1.1".equals(request)){
                            out.write("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".getBytes(StandardCharsets.US_ASCII));
                        }else{
                            byte[] payload=packageBytes;
                            String headers="HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nCache-Control: no-store\r\nContent-Length: "+payload.length+"\r\nConnection: close\r\n\r\n";
                            out.write(headers.getBytes(StandardCharsets.US_ASCII));out.write(payload);out.flush();
                            used=true;listener.event("status","Transferência enviada; compartilhamento encerrado");
                        }
                    }catch(Exception error){listener.event("status","Conexão interrompida: "+error.getMessage());}
                    finally{try{client.close();}catch(Exception ignored){}}
                }
            }catch(IOException e){if(!active.isClosed())listener.event("error",e.getMessage());}
            finally{try{active.close();}catch(IOException ignored){} if(server==active)server=null;packageBytes=null;}
        });
        return secret;
    }
    public synchronized void stop(){if(server!=null)try{server.close();}catch(IOException ignored){}server=null;packageBytes=null;used=true;}
    public void receive(String address,String code){
        io.execute(()->{
            HttpURLConnection conn=null;
            try{
                if(!address.matches("(?:[0-9]{1,3}\\.){3}[0-9]{1,3}"))throw new IOException("Use o IP local informado pelo aparelho de origem");
                for(String octet:address.split("\\."))if(Integer.parseInt(octet)>255)throw new IOException("Endereço IP inválido");
                if(!code.matches("[0-9A-Fa-f]{32}"))throw new IOException("Código deve ter 32 caracteres hexadecimais");
                conn=(HttpURLConnection)new URL("http://"+address+":"+PORT+"/arque-link/v1").openConnection();
                conn.setConnectTimeout(8000);conn.setReadTimeout(15000);conn.setUseCaches(false);
                if(conn.getResponseCode()!=200)throw new IOException("O outro aparelho não está compartilhando");
                int size=conn.getContentLength();if(size>MAX_BYTES+64)throw new IOException("Transferência muito grande");
                ByteArrayOutputStream out=new ByteArrayOutputStream();try(InputStream in=conn.getInputStream()){
                    byte[] buf=new byte[8192];int n;while((n=in.read(buf))!=-1){out.write(buf,0,n);if(out.size()>MAX_BYTES+64)throw new IOException("Limite de dados excedido");}
                }
                byte[] clear=open(out.toByteArray(),code.toUpperCase(Locale.ROOT));
                listener.event("received",new String(clear,StandardCharsets.UTF_8));
            }catch(Exception error){listener.event("error",error.getClass().getSimpleName()+": "+error.getMessage());}
            finally{if(conn!=null)conn.disconnect();}
        });
    }
    public static String localIp(){
        try{Enumeration<NetworkInterface> nets=NetworkInterface.getNetworkInterfaces();
            while(nets.hasMoreElements()){NetworkInterface net=nets.nextElement();if(!net.isUp()||net.isLoopback())continue;
                Enumeration<InetAddress> addrs=net.getInetAddresses();while(addrs.hasMoreElements()){
                    InetAddress a=addrs.nextElement();if(a instanceof Inet4Address&&a.isSiteLocalAddress())return a.getHostAddress();
                }
            }
        }catch(Exception ignored){}return "indisponível";
    }
    public void shutdown(){stop();io.shutdownNow();}
}
