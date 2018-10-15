
import org.apache.http.client.methods.HttpGet
import org.apache.http.conn.ssl.SSLConnectionSocketFactory
import org.apache.http.impl.client.HttpClients
import org.apache.http.ssl.SSLContexts
import org.apache.http.util.EntityUtils
import java.io.FileInputStream
import java.security.KeyStore
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSession

const val JAVA_KEY_STORE = "JKS"
const val CLIENT_KEYSTORE_PATH = "../certificates/out/client.jks"
const val CLIENT_KEYSTORE_PASS = "123456"
const val TRUST_KEYSTORE_PATH = "../certificates/out/client_truststore.jks"
const val TRUST_KEYSTORE_PASS = "123456"

fun main(args: Array<String>) {
    val hostVerifier: (String, SSLSession) -> Boolean = { _, _ ->
        true
    }

    val csf = SSLConnectionSocketFactory(createSslCustomContext(),arrayOf("TLSv1.2", "TLSv1.1"), null, hostVerifier)

    HttpClients.custom().setSSLSocketFactory(csf).build().use { httpclient ->
        val req = HttpGet("https://localhost:8443/ping")
        println("*** SENDING REQUEST ***")
        httpclient.execute(req).use { response ->
            val entity = response.entity
            println("*** RESPONSE STATUS: ${response.statusLine} ***")
            EntityUtils.consume(entity)
            println("*** RESPONSE ENTITY: $entity ***")
        }
    }
}

fun createSslCustomContext(): SSLContext {
    val identityKeyStore = KeyStore.getInstance(JAVA_KEY_STORE)
    identityKeyStore.load(FileInputStream(CLIENT_KEYSTORE_PATH), CLIENT_KEYSTORE_PASS.toCharArray())

    val trustKeyStore = KeyStore.getInstance(JAVA_KEY_STORE)
    trustKeyStore.load(FileInputStream(TRUST_KEYSTORE_PATH), TRUST_KEYSTORE_PASS.toCharArray())

    return SSLContexts.custom()
            .loadTrustMaterial(trustKeyStore, null)
            .loadKeyMaterial(identityKeyStore, CLIENT_KEYSTORE_PASS.toCharArray())
            .build()
}