package br.com.arque.securitylab;

import android.app.Activity;
import android.app.KeyguardManager;
import android.app.admin.DevicePolicyManager;
import android.content.ComponentName;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class MainActivity extends Activity {
    private static final int BG = Color.rgb(11, 19, 32);
    private static final int SURFACE = Color.rgb(23, 36, 55);
    private static final int WHITE = Color.rgb(239, 244, 250);
    private static final int MUTED = Color.rgb(164, 184, 205);
    private static final int BLUE = Color.rgb(81, 192, 232);
    private static final int YELLOW = Color.rgb(255, 190, 90);
    private static final int GREEN = Color.rgb(117, 214, 165);
    private static final int INFO = 0;
    private static final int ATTENTION = 1;
    private static final int GOOD = 2;

    private final List<Finding> findings = new ArrayList<>();
    private LinearLayout resultsHolder;
    private TextView summary;
    private String report = "";

    private static final class Finding {
        final String title;
        final String detail;
        final String advice;
        final int level;

        Finding(String title, String detail, String advice, int level) {
            this.title = title;
            this.detail = detail;
            this.advice = advice;
            this.level = level;
        }
    }

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().setStatusBarColor(BG);
        getWindow().setNavigationBarColor(BG);
        buildScreen();
        runScan();
    }

    private int dp(int n) {
        return Math.round(n * getResources().getDisplayMetrics().density);
    }

    private GradientDrawable background(int color, int radius) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color);
        d.setCornerRadius(dp(radius));
        return d;
    }

    private TextView text(String value, int sp, int color, boolean bold) {
        TextView v = new TextView(this);
        v.setText(value);
        v.setTextSize(sp);
        v.setTextColor(color);
        if (bold) v.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        return v;
    }

    private void buildScreen() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setBackgroundColor(BG);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(20), dp(28), dp(20), dp(28));
        scroll.addView(root);

        TextView label = text("ARQUE  /  SECURITY LAB", 12, BLUE, true);
        label.setLetterSpacing(.14f);
        root.addView(label);

        TextView title = text("Diagnóstico de segurança", 29, WHITE, true);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(-1, -2);
        titleParams.topMargin = dp(16);
        root.addView(title, titleParams);

        TextView intro = text("Inspeção local do Android. Nenhum dado é enviado e nenhuma proteção é modificada.", 15, MUTED, false);
        LinearLayout.LayoutParams introParams = new LinearLayout.LayoutParams(-1, -2);
        introParams.topMargin = dp(8);
        root.addView(intro, introParams);

        LinearLayout actions = new LinearLayout(this);
        actions.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams actParams = new LinearLayout.LayoutParams(-1, dp(50));
        actParams.topMargin = dp(22);
        root.addView(actions, actParams);

        Button scanButton = button("Analisar", BLUE, BG);
        actions.addView(scanButton, new LinearLayout.LayoutParams(0, -1, 1));
        scanButton.setOnClickListener(v -> runScan());

        Button shareButton = button("Compartilhar", SURFACE, WHITE);
        LinearLayout.LayoutParams shareParams = new LinearLayout.LayoutParams(0, -1, 1);
        shareParams.leftMargin = dp(10);
        actions.addView(shareButton, shareParams);
        shareButton.setOnClickListener(v -> shareReport());

        summary = text("", 15, WHITE, true);
        LinearLayout.LayoutParams sumParams = new LinearLayout.LayoutParams(-1, -2);
        sumParams.topMargin = dp(24);
        root.addView(summary, sumParams);

        resultsHolder = new LinearLayout(this);
        resultsHolder.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams resultsParams = new LinearLayout.LayoutParams(-1, -2);
        resultsParams.topMargin = dp(10);
        root.addView(resultsHolder, resultsParams);

        Button settingsButton = button("Abrir configurações de segurança", SURFACE, WHITE);
        LinearLayout.LayoutParams settingsParams = new LinearLayout.LayoutParams(-1, dp(48));
        settingsParams.topMargin = dp(14);
        root.addView(settingsButton, settingsParams);
        settingsButton.setOnClickListener(v -> {
            try {
                startActivity(new Intent(Settings.ACTION_SECURITY_SETTINGS));
            } catch (Exception ignored) {
                startActivity(new Intent(Settings.ACTION_SETTINGS));
            }
        });

        TextView disclaimer = text("Aviso: este relatório mostra sinais e configurações que merecem revisão, não confirma exploração de vulnerabilidades. Apps gerenciadores podem ter controles não visíveis a aplicativos comuns.", 12, MUTED, false);
        LinearLayout.LayoutParams noticeParams = new LinearLayout.LayoutParams(-1, -2);
        noticeParams.topMargin = dp(23);
        root.addView(disclaimer, noticeParams);

        setContentView(scroll);
    }

    private Button button(String label, int bg, int foreground) {
        Button b = new Button(this);
        b.setText(label);
        b.setTextSize(13);
        b.setAllCaps(false);
        b.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        b.setTextColor(foreground);
        b.setBackground(background(bg, 12));
        return b;
    }

    private void add(String title, String detail, String advice, int level) {
        findings.add(new Finding(title, detail, advice, level));
    }

    private void runScan() {
        findings.clear();
        collectSystem();
        collectLock();
        collectDebug();
        collectPolicy();
        collectAccessibility();
        showResults();
    }

    private void collectSystem() {
        add("Sistema Android", "Android " + Build.VERSION.RELEASE + " • API " + Build.VERSION.SDK_INT,
                "Confira atualizações do fabricante em Configurações.", INFO);

        String patch = Build.VERSION.SECURITY_PATCH;
        if (patch == null || patch.trim().isEmpty()) {
            add("Patch de segurança", "Data não disponível.",
                    "Consulte a atualização de segurança nas configurações do sistema.", INFO);
            return;
        }
        try {
            long days = ChronoUnit.DAYS.between(LocalDate.parse(patch), LocalDate.now());
            if (days > 120) {
                add("Patch de segurança", patch + " • " + days + " dias desde o patch",
                        "Verifique atualizações disponíveis. Patch antigo não prova uma falha explorável.", ATTENTION);
            } else {
                add("Patch de segurança", patch,
                        "Mantenha o sistema atualizado. A data isoladamente não garante ausência de falhas.", GOOD);
            }
        } catch (Exception ignored) {
            add("Patch de segurança", patch, "Confira a data no menu de atualizações.", INFO);
        }
    }

    private void collectLock() {
        try {
            KeyguardManager keyguard = (KeyguardManager) getSystemService(KEYGUARD_SERVICE);
            boolean secure = keyguard != null && keyguard.isDeviceSecure();
            add("Bloqueio de tela",
                    secure ? "PIN, senha ou padrão seguro configurado." : "Sem bloqueio seguro detectado.",
                    secure ? "Evite compartilhar o PIN." : "Ative um PIN ou senha forte em Configurações.",
                    secure ? GOOD : ATTENTION);
        } catch (Exception e) {
            add("Bloqueio de tela", "Não foi possível verificar.", "Consulte as configurações do aparelho.", INFO);
        }
    }

    private void collectDebug() {
        try {
            boolean adb = Settings.Global.getInt(getContentResolver(), Settings.Global.ADB_ENABLED, 0) == 1;
            add("Depuração USB (ADB)",
                    adb ? "Ativada." : "Desativada.",
                    adb ? "Desative se não estiver usando ferramentas de desenvolvimento." : "Nenhuma ação necessária.",
                    adb ? ATTENTION : GOOD);
        } catch (Exception e) {
            add("Depuração USB (ADB)", "Status não disponível.", "Verifique as opções do desenvolvedor.", INFO);
        }

        try {
            boolean developer = Settings.Global.getInt(getContentResolver(),
                    Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1;
            add("Opções do desenvolvedor", developer ? "Ativadas." : "Desativadas.",
                    developer ? "Revise opções que você não utiliza." : "Nenhuma ação necessária.",
                    developer ? INFO : GOOD);
        } catch (Exception e) {
            add("Opções do desenvolvedor", "Status não disponível.", "Verifique manualmente.", INFO);
        }
    }

    private void collectPolicy() {
        try {
            DevicePolicyManager policy = (DevicePolicyManager) getSystemService(DEVICE_POLICY_SERVICE);
            if (policy == null) {
                add("Administração do aparelho", "Serviço indisponível.", "Consulte Configurações.", INFO);
                return;
            }

            List<ComponentName> admins = policy.getActiveAdmins();
            if (admins == null || admins.isEmpty()) {
                add("Administradores ativos", "Nenhum administrador legado visível ao app.",
                        "Esta consulta não detecta necessariamente todos os controles de gerenciamento.", INFO);
            } else {
                StringBuilder names = new StringBuilder();
                for (ComponentName name : admins) {
                    if (names.length() > 0) names.append("\n");
                    names.append("• ").append(name.getPackageName());
                }
                add("Administradores ativos", admins.size() + " componente(s):\n" + names,
                        "Confira se reconhece os aplicativos. Não remova políticas sem autorização.", INFO);
            }

            try {
                int encryption = policy.getStorageEncryptionStatus();
                boolean enabled =
                        encryption == DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE ||
                        encryption == DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE_DEFAULT_KEY ||
                        encryption == DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE_PER_USER;
                add("Criptografia de armazenamento",
                        enabled ? "Criptografia ativa." : "Status: " + encryption + " (não confirmado como ativo).",
                        enabled ? "Protege dados locais quando o dispositivo está bloqueado." :
                                "Confirme a criptografia nas configurações do aparelho.",
                        enabled ? GOOD : INFO);
            } catch (Exception ignored) {
                add("Criptografia de armazenamento", "Não foi possível confirmar.",
                        "Consulte as configurações de segurança.", INFO);
            }
        } catch (Exception ignored) {
            add("Administradores ativos", "Consulta limitada pelo Android.",
                    "Revise os administradores e aplicativos de gerenciamento nas configurações.", INFO);
        }
    }

    private void collectAccessibility() {
        try {
            String enabled = Settings.Secure.getString(getContentResolver(),
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
            if (enabled == null || enabled.trim().isEmpty()) {
                add("Serviços de acessibilidade", "Nenhum serviço ativo retornado pela consulta.",
                        "Alguns fabricantes podem restringir esta informação.", INFO);
                return;
            }
            String[] services = enabled.split(":");
            StringBuilder names = new StringBuilder();
            for (String service : services) {
                String pkg = service.split("/")[0];
                if (pkg.isEmpty()) continue;
                if (names.length() > 0) names.append("\n");
                names.append("• ").append(pkg);
            }
            add("Serviços de acessibilidade", names.toString(),
                    "Verifique se foram ativados por você. Serviços legítimos também usam esse recurso.", INFO);
        } catch (Exception ignored) {
            add("Serviços de acessibilidade", "Informação não acessível.",
                    "Veja Configurações > Acessibilidade.", INFO);
        }
    }

    private void showResults() {
        resultsHolder.removeAllViews();
        int warnings = 0;
        for (Finding finding : findings) {
            if (finding.level == ATTENTION) warnings++;
            makeCard(finding);
        }
        summary.setText(findings.size() + " verificações  •  " + warnings + " pontos para revisar");
        String now = new SimpleDateFormat("dd/MM/yyyy HH:mm", new Locale("pt", "BR")).format(new Date());
        StringBuilder b = new StringBuilder("ARQUE SECURITY LAB\nRelatório local: ").append(now)
                .append("\n\n");
        for (Finding finding : findings) {
            String status = finding.level == ATTENTION ? "REVISAR" : finding.level == GOOD ? "OK" : "INFORMATIVO";
            b.append("[").append(status).append("] ").append(finding.title).append("\n")
                    .append(finding.detail).append("\n")
                    .append("Orientação: ").append(finding.advice).append("\n\n");
        }
        b.append("Diagnóstico informativo, sem exploração, modificação de políticas ou envio automático de dados.");
        report = b.toString();
    }

    private void makeCard(Finding finding) {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(17), dp(15), dp(17), dp(16));
        card.setBackground(background(SURFACE, 14));
        LinearLayout.LayoutParams cardParams = new LinearLayout.LayoutParams(-1, -2);
        cardParams.bottomMargin = dp(11);
        resultsHolder.addView(card, cardParams);

        int color = finding.level == ATTENTION ? YELLOW : finding.level == GOOD ? GREEN : BLUE;
        String status = finding.level == ATTENTION ? "REVISAR" : finding.level == GOOD ? "OK" : "INFORMATIVO";
        TextView tag = text(status, 11, color, true);
        tag.setLetterSpacing(.07f);
        card.addView(tag);

        TextView title = text(finding.title, 17, WHITE, true);
        LinearLayout.LayoutParams tp = new LinearLayout.LayoutParams(-1, -2);
        tp.topMargin = dp(5);
        card.addView(title, tp);

        TextView detail = text(finding.detail, 14, WHITE, false);
        LinearLayout.LayoutParams dp1 = new LinearLayout.LayoutParams(-1, -2);
        dp1.topMargin = dp(7);
        card.addView(detail, dp1);

        TextView advice = text(finding.advice, 13, MUTED, false);
        LinearLayout.LayoutParams ap = new LinearLayout.LayoutParams(-1, -2);
        ap.topMargin = dp(8);
        card.addView(advice, ap);
    }

    private void shareReport() {
        if (report.isEmpty()) return;
        Intent send = new Intent(Intent.ACTION_SEND);
        send.setType("text/plain");
        send.putExtra(Intent.EXTRA_SUBJECT, "Relatório Arque Security Lab");
        send.putExtra(Intent.EXTRA_TEXT, report);
        startActivity(Intent.createChooser(send, "Compartilhar relatório"));
    }
}
