package br.com.arque.measure

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** PDF do orçamento: o que sai nos detalhes, nas especificações e nas observações vem só do que está no orçamento. */
class QuotePdfTest {
    private val notas = "Material: MDF 15 mm · caixa Branco · por fora Canela · fundo 6 mm · puxador cava usinada · dobradiças com amortecimento · corrediças telescópicas.\n" +
        "Móveis do projeto (4) · largura × altura × profundidade:\nParede do fundo:\n• 1 × Aéreo · 1640 × 320 × 275 mm · 3 portas\n• 2 × Balcão · 800 × 870 × 550 mm · 2 portas\n" +
        "Parede da esquerda:\n• 1 × Torre · 600 × 2200 × 580 mm · 2 portas, forno\nCores do projeto: Canela · Branco\n" +
        "Entrega em 30 dias depois da medição final.\n• Instalação incluída"

    @Test fun linhasDoEditorViramDetalhesEOQueAPessoaDigitouFicaEmObservacoes() {
        val (linhas, livre) = QuotePdf.parseNotes(notas)
        assertEquals(listOf("Material", "Móveis do projeto", "Cores do projeto"), linhas.map { it.label })
        assertEquals(1, linhas[0].lines.size)
        assertEquals(listOf("(4) · largura × altura × profundidade:", "Parede do fundo:", "• 1 × Aéreo · 1640 × 320 × 275 mm · 3 portas", "• 2 × Balcão · 800 × 870 × 550 mm · 2 portas",
            "Parede da esquerda:", "• 1 × Torre · 600 × 2200 × 580 mm · 2 portas, forno"), linhas[1].lines)
        assertEquals(listOf("Canela · Branco"), linhas[2].lines)
        assertEquals(listOf("Entrega em 30 dias depois da medição final.", "• Instalação incluída"), livre)
        assertEquals(listOf("MDF 15 mm", "Caixa Branco", "Por fora Canela", "Fundo 6 mm", "Puxador cava usinada", "Dobradiças com amortecimento", "Corrediças telescópicas"), QuotePdf.specParts(linhas))
    }

    @Test fun textoDigitadoNuncaViraDetalheNemEspecificacao() {
        val (linhas, livre) = QuotePdf.parseNotes("Pagamento: 3 vezes, sem juros.\nFrete por conta do cliente\n• 2 × por semana eu passo na obra\nObs: medir de novo")
        assertTrue(linhas.isEmpty())
        assertEquals(listOf("Pagamento: 3 vezes, sem juros.", "Frete por conta do cliente", "• 2 × por semana eu passo na obra", "Obs: medir de novo"), livre)
        assertTrue(QuotePdf.specParts(linhas).isEmpty())
        val (vazio, nada) = QuotePdf.parseNotes("")
        assertTrue(vazio.isEmpty()); assertTrue(nada.isEmpty())
    }

    @Test fun todaFotoEntraNumaLinhaSemSumirNemRepetir() {
        for (n in 0..40) {
            val g = QuotePdf.photoGroups(n)
            assertEquals(n, g.sum())
            assertTrue(g.all { it in 1..3 })
        }
        assertEquals(listOf(2, 3), QuotePdf.photoGroups(5))
        assertEquals(listOf(2, 2, 3), QuotePdf.photoGroups(7))
    }
}
