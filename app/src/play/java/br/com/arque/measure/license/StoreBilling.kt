package br.com.arque.measure.license

import android.app.Activity
import android.content.Context
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
 * Compra única pelo Google Play Billing (biblioteca 8).
 * Produto no Play Console: tipo "produto único", ID [PRODUCT_ID].
 */
object StoreBilling {
    const val AVAILABLE = true
    const val PRODUCT_ID = "arquemestre_acesso_completo"

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
                    if (notify) onMsg("Compra confirmada. App desbloqueado. Obrigado!")
                    onChange()
                }
                Purchase.PurchaseState.PENDING -> if (notify) onMsg("Pagamento pendente. Assim que o Google confirmar, o app desbloqueia sozinho.")
                else -> {}
            }
        }
    }

    /** Liga no Google Play, busca o preço e confere se já comprou (restaura sozinho). */
    fun start(ctx: Context, onChange: () -> Unit) {
        appCtx = ctx.applicationContext
        this.onChange = onChange
        val c = client ?: BillingClient.newBuilder(ctx.applicationContext)
            .setListener { r, list -> if (r.responseCode == BillingClient.BillingResponseCode.OK) handle(list, true) else if (r.responseCode == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED) query(true) else if (r.responseCode != BillingClient.BillingResponseCode.USER_CANCELED) onMsg("Não deu certo a compra (${r.debugMessage}).") }
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
        val prod = QueryProductDetailsParams.Product.newBuilder().setProductId(PRODUCT_ID).setProductType(BillingClient.ProductType.INAPP).build()
        c.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(listOf(prod)).build()) { r, res ->
            if (r.responseCode == BillingClient.BillingResponseCode.OK) {
                details = res.productDetailsList.firstOrNull()
                onChange()
            }
        }
        c.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build()) { r, list ->
            if (r.responseCode != BillingClient.BillingResponseCode.OK) {
                if (report) onMsg("Não consegui falar com o Google Play agora. Tente de novo com internet.")
                return@queryPurchasesAsync
            }
            val owned = list.any { PRODUCT_ID in it.products && it.purchaseState == Purchase.PurchaseState.PURCHASED }
            if (owned) handle(list, report) else {
                License.revokeStore(ctx)
                if (report) onMsg("Não encontrei compra nesta conta do Google. Confira se é a mesma conta usada na compra.")
                onChange()
            }
        }
    }

    /** Preço que o Google Play mostra (ex.: "R$ 149,90"). */
    fun price(): String? = details?.oneTimePurchaseOfferDetails?.formattedPrice

    fun buy(activity: Activity, onMsg: (String) -> Unit) {
        this.onMsg = onMsg
        val c = client
        val d = details
        if (c == null || !c.isReady || d == null) {
            onMsg("Conectando ao Google Play… tente de novo em alguns segundos.")
            start(activity, onChange)
            return
        }
        val pp = BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(d).build()
        c.launchBillingFlow(activity, BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(pp)).build())
    }

    /** "Já comprei": confere a compra na conta do Google deste celular. */
    fun restore(ctx: Context, onMsg: (String) -> Unit) {
        this.onMsg = onMsg
        val c = client
        if (c == null || !c.isReady) { start(ctx, onChange); onMsg("Conectando ao Google Play… toque de novo em alguns segundos."); return }
        query(true)
    }
}
