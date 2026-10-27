package br.com.arque.measure.license

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import br.com.arque.measure.i18n.tr
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams

/**
 * Assinatura mensal pelo Google Play Billing (biblioteca 8).
 * No Play Console: Monetizar › Assinaturas › ID [PRODUCT_ID], plano básico [BASE_PLAN] (mensal, renovação automática,
 * R$ 29,90) com a oferta de teste grátis [TRIAL_OFFER] (3 dias, só pra quem nunca assinou).
 * O desbloqueio vale enquanto a assinatura estiver ativa (inclusive no teste grátis).
 */
object StoreBilling {
    const val AVAILABLE = true
    const val PRODUCT_ID = "arquemestre_mensal"
    const val BASE_PLAN = "mensal"
    const val TRIAL_OFFER = "teste-3-dias"
    const val PACKAGE = "br.com.arque.measure"

    private var client: BillingClient? = null
    private var details: ProductDetails? = null
    private var appCtx: Context? = null
    private var onChange: () -> Unit = {}
    private var onMsg: (String) -> Unit = {}

    private fun handle(purchases: List<Purchase>?, notify: Boolean) {
        val ctx = appCtx ?: return
        purchases.orEmpty().filter { PRODUCT_ID in it.products }.forEach { p ->
            when (p.purchaseState) {
                Purchase.PurchaseState.PURCHASED -> {
                    License.grantStore(ctx)
                    if (!p.isAcknowledged) {
                        client?.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(p.purchaseToken).build()) {}
                    }
                    if (notify) onMsg(tr("Assinatura ativa. Obrigado!"))
                    onChange()
                }
                Purchase.PurchaseState.PENDING -> if (notify) onMsg(tr("Pagamento pendente. Assim que o Google confirmar, o app libera sozinho."))
                else -> {}
            }
        }
    }

    /** Liga no Google Play, busca o preço e confere se a assinatura está ativa (restaura sozinho). */
    fun start(ctx: Context, onChange: () -> Unit) {
        appCtx = ctx.applicationContext
        this.onChange = onChange
        val c = client ?: BillingClient.newBuilder(ctx.applicationContext)
            .setListener { r, list ->
                when (r.responseCode) {
                    BillingClient.BillingResponseCode.OK -> handle(list, true)
                    BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED -> query(true)
                    BillingClient.BillingResponseCode.USER_CANCELED -> {}
                    else -> onMsg(tr("Não deu certo a assinatura ({0}).", r.debugMessage))
                }
            }
            .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
            .build().also { client = it }
        if (c.isReady) { query(false); return }
        c.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(r: BillingResult) {
                if (r.responseCode == BillingClient.BillingResponseCode.OK) query(false)
            }
            override fun onBillingServiceDisconnected() {}
        })
    }

    private fun query(report: Boolean) {
        val c = client ?: return
        val ctx = appCtx ?: return
        val prod = QueryProductDetailsParams.Product.newBuilder().setProductId(PRODUCT_ID).setProductType(BillingClient.ProductType.SUBS).build()
        c.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(listOf(prod)).build()) { r, res ->
            if (r.responseCode == BillingClient.BillingResponseCode.OK) {
                details = res.productDetailsList.firstOrNull()
                onChange()
            }
        }
        c.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS).build()) { r, list ->
            if (r.responseCode != BillingClient.BillingResponseCode.OK) {
                if (report) onMsg(tr("Não consegui falar com o Google Play agora. Tente de novo com internet."))
                return@queryPurchasesAsync
            }
            val active = list.any { PRODUCT_ID in it.products && it.purchaseState == Purchase.PurchaseState.PURCHASED }
            if (active) handle(list, report) else {
                License.revokeStore(ctx)
                if (report) onMsg(tr("Não encontrei assinatura ativa nesta conta do Google. Confira se é a mesma conta usada na assinatura."))
                onChange()
            }
        }
    }

    private fun offers() = details?.subscriptionOfferDetails.orEmpty().filter { it.basePlanId == BASE_PLAN }.ifEmpty { details?.subscriptionOfferDetails.orEmpty() }

    /** Oferta com teste grátis (o Google só devolve se a pessoa tiver direito), senão o plano básico. */
    private fun bestOffer() = offers().firstOrNull { o -> o.pricingPhases.pricingPhaseList.any { it.priceAmountMicros == 0L } }
        ?: offers().firstOrNull { it.offerId == null } ?: offers().firstOrNull()

    /** Preço mensal que o Google Play mostra (ex.: "R$ 29,90"). */
    fun price(): String? = offers().firstOrNull { it.offerId == null }?.pricingPhases?.pricingPhaseList?.lastOrNull()?.formattedPrice
        ?: bestOffer()?.pricingPhases?.pricingPhaseList?.lastOrNull()?.formattedPrice

    /** Dias de teste grátis que esta conta ainda pode usar (0 se já usou ou se não houver teste). */
    fun trialDays(): Int {
        val ph = bestOffer()?.pricingPhases?.pricingPhaseList?.firstOrNull { it.priceAmountMicros == 0L } ?: return 0
        return isoDays(ph.billingPeriod)
    }

    /** "P3D" → 3, "P1W" → 7, "P1M" → 30. */
    fun isoDays(p: String): Int {
        val m = Regex("""P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?""").matchEntire(p) ?: return 0
        val (y, mo, w, d) = m.destructured
        return (y.toIntOrNull() ?: 0) * 365 + (mo.toIntOrNull() ?: 0) * 30 + (w.toIntOrNull() ?: 0) * 7 + (d.toIntOrNull() ?: 0)
    }

    fun buy(activity: Activity, onMsg: (String) -> Unit) {
        this.onMsg = onMsg
        val c = client
        val d = details
        val o = bestOffer()
        if (c == null || !c.isReady || d == null || o == null) {
            onMsg(tr("Conectando ao Google Play… tente de novo em alguns segundos."))
            start(activity, onChange)
            return
        }
        val pp = BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(d).setOfferToken(o.offerToken).build()
        c.launchBillingFlow(activity, BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(pp)).build())
    }

    /** "Já assino": confere a assinatura na conta do Google deste celular. */
    fun restore(ctx: Context, onMsg: (String) -> Unit) {
        this.onMsg = onMsg
        val c = client
        if (c == null || !c.isReady) { start(ctx, onChange); onMsg(tr("Conectando ao Google Play… toque de novo em alguns segundos.")); return }
        query(true)
    }

    /** Abre a tela de assinaturas do Google Play (cancelar, trocar o cartão). */
    fun manage(ctx: Context) {
        val u = Uri.parse("https://play.google.com/store/account/subscriptions?sku=$PRODUCT_ID&package=$PACKAGE")
        runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, u).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
    }
}
