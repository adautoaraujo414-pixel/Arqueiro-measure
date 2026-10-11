package com.arque.measure;

import android.Manifest;
import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Build;
import org.json.JSONArray;
import org.json.JSONObject;

/** Local, inexact Android reminders. No cloud account, server or calendar permission. */
public final class AgendaNotifications extends BroadcastReceiver {
    private static final String CHANNEL="arque_agenda_1";
    private static final String PREFS="arque_agenda_reminders";
    private static final String KEY="scheduled";
    private static final String ACTION_FIRE="com.arque.measure.AGENDA_FIRE";
    private static final String ACTION_RESTORE="android.intent.action.MY_PACKAGE_REPLACED";

    public static void ensureChannel(Context context) {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationManager nm=(NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);
            if(nm!=null) {
                NotificationChannel channel=new NotificationChannel(CHANNEL,"Agenda Arque",NotificationManager.IMPORTANCE_HIGH);
                channel.setDescription("Lembretes de entregas, medições e compromissos");
                nm.createNotificationChannel(channel);
            }
        }
    }
    private static int requestCode(String id,boolean early){return 31*id.hashCode()+(early?1:2);}
    private static PendingIntent pending(Context ctx,String id,boolean early,String title,String type,String notes,int flags) {
        Intent fire=new Intent(ctx,AgendaNotifications.class);
        fire.setAction(ACTION_FIRE);
        fire.putExtra("title",title);
        fire.putExtra("type",type);
        fire.putExtra("notes",notes);
        fire.putExtra("early",early);
        return PendingIntent.getBroadcast(ctx,requestCode(id,early),fire,flags|PendingIntent.FLAG_IMMUTABLE);
    }
    private static JSONArray read(Context ctx) {
        try {return new JSONArray(ctx.getSharedPreferences(PREFS,Context.MODE_PRIVATE).getString(KEY,"[]"));}
        catch(Exception ex){return new JSONArray();}
    }
    private static void cancel(Context ctx,JSONArray events) {
        AlarmManager am=(AlarmManager)ctx.getSystemService(Context.ALARM_SERVICE);
        if(am==null)return;
        for(int i=0;i<events.length();i++){
            JSONObject e=events.optJSONObject(i);if(e==null)continue;
            String id=e.optString("id");
            for(boolean early:new boolean[]{true,false}){
                PendingIntent pi=pending(ctx,id,early,"","","",PendingIntent.FLAG_NO_CREATE);
                if(pi!=null){am.cancel(pi);pi.cancel();}
            }
        }
    }
    private static void schedule(Context ctx,JSONArray events) {
        ensureChannel(ctx);
        AlarmManager am=(AlarmManager)ctx.getSystemService(Context.ALARM_SERVICE);
        if(am==null)return;
        long now=System.currentTimeMillis();
        for(int i=0;i<events.length();i++) {
            JSONObject e=events.optJSONObject(i);if(e==null)continue;
            String id=e.optString("id"),title=e.optString("title"),type=e.optString("type"),notes=e.optString("notes");
            long at=e.optLong("at",0),lead=Math.max(0,e.optInt("reminderMinutes",0))*60000L;
            if(id.isEmpty()||title.isEmpty()||at<=now)continue;
            for(boolean early:new boolean[]{true,false}){
                if(early&&lead==0)continue;
                long trigger=at-(early?lead:0);
                if(trigger<=now)continue;
                try {
                    PendingIntent pi=pending(ctx,id,early,title,type,notes,PendingIntent.FLAG_UPDATE_CURRENT);
                    // Android may delay inexact alarms under battery restrictions; no exact-alarm privilege needed.
                    am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,trigger,pi);
                }catch(Exception ignored){ /* App keeps the appointment even when an alarm cannot be registered. */ }
            }
        }
    }
    public static synchronized void sync(Context ctx,String json) throws Exception {
        JSONArray incoming=new JSONArray(json);
        if(incoming.length()>350)throw new IllegalArgumentException("Muitos compromissos para notificar.");
        JSONArray old=read(ctx);
        cancel(ctx,old);
        ctx.getSharedPreferences(PREFS,Context.MODE_PRIVATE).edit().putString(KEY,incoming.toString()).apply();
        schedule(ctx,incoming);
    }
    @Override public void onReceive(Context context,Intent intent){
        if(intent==null)return;
        String action=intent.getAction();
        if(Intent.ACTION_BOOT_COMPLETED.equals(action)||ACTION_RESTORE.equals(action)) {
            schedule(context,read(context));
            return;
        }
        if(!ACTION_FIRE.equals(action))return;
        if(Build.VERSION.SDK_INT>=33&&context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)return;
        ensureChannel(context);
        NotificationManager nm=(NotificationManager)context.getSystemService(Context.NOTIFICATION_SERVICE);
        if(nm==null)return;
        boolean early=intent.getBooleanExtra("early",false);
        String title=intent.getStringExtra("title");if(title==null||title.isEmpty())title="Compromisso Arque";
        String type=intent.getStringExtra("type");if(type==null)type="Agenda";
        String notes=intent.getStringExtra("notes");if(notes==null)notes="";
        String message=(early?"Em breve: ":"Agora: ")+type+(notes.isEmpty()?"":" · "+notes);
        Intent open=new Intent(context,MainActivity.class);
        open.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK|Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent openIntent=PendingIntent.getActivity(context,0,open,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
        Notification.Builder builder=Build.VERSION.SDK_INT>=26?new Notification.Builder(context,CHANNEL):new Notification.Builder(context);
        builder.setSmallIcon(android.R.drawable.ic_popup_reminder)
          .setContentTitle(title)
          .setContentText(message)
          .setStyle(new Notification.BigTextStyle().bigText(message))
          .setAutoCancel(true)
          .setWhen(System.currentTimeMillis())
          .setContentIntent(openIntent);
        if(Build.VERSION.SDK_INT<26)builder.setPriority(Notification.PRIORITY_HIGH);
        nm.notify((title+message+System.currentTimeMillis()/60000).hashCode(),builder.build());
    }
}
