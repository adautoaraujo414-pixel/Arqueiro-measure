package com.arque.measure;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
public class ArqueLinkSmoke {
 public static void main(String[] args) throws Exception {
  String code=ArqueLink.freshSecret();
  if(!code.matches("[0-9A-F]{32}"))throw new AssertionError("Código incorreto");
  byte[] data="{\"format\":\"arque-measure\",\"version\":1,\"state\":{\"clients\":[],\"projects\":[]}}".getBytes(StandardCharsets.UTF_8);
  byte[] encrypted=ArqueLink.seal(data,code);
  if(Arrays.equals(data,encrypted)||!Arrays.equals(data,ArqueLink.open(encrypted,code)))throw new AssertionError("Falha de criptografia");
  try{ArqueLink.open(encrypted,ArqueLink.freshSecret());throw new AssertionError("Chave errada foi aceita");}
  catch(javax.crypto.AEADBadTagException expected){}
  encrypted[encrypted.length-1]^=1;
  try{ArqueLink.open(encrypted,code);throw new AssertionError("Pacote adulterado foi aceito");}
  catch(javax.crypto.AEADBadTagException expected){}
  CountDownLatch arrived=new CountDownLatch(1);
  AtomicReference<String> received=new AtomicReference<>(),error=new AtomicReference<>();
  ArqueLink sender=new ArqueLink((kind,val)->{});
  ArqueLink receiver=new ArqueLink((kind,val)->{if(kind.equals("received")){received.set(val);arrived.countDown();}else if(kind.equals("error")){error.set(val);arrived.countDown();}});
  try{
   String session=sender.start(new String(data,StandardCharsets.UTF_8));
   receiver.receive("127.0.0.1",session);
   if(!arrived.await(12,TimeUnit.SECONDS))throw new AssertionError("Timeout transferência local");
   if(error.get()!=null)throw new AssertionError("Erro no link: "+error.get());
   if(!new String(data,StandardCharsets.UTF_8).equals(received.get()))throw new AssertionError("Dados recebidos diferentes");
   System.out.println("ARQUE LINK OK: AES-GCM, chave errada, adulteração e transferência localhost.");
  }finally{sender.shutdown();receiver.shutdown();}
 }
}
