import java.net.URL
import java.security.cert.X509Certificate
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

object NoOpX509TrustManager : X509TrustManager {
    override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()

    override fun checkClientTrusted(certs: Array<X509Certificate>, authType: String) = Unit

    override fun checkServerTrusted(certs: Array<X509Certificate>, authType: String) = Unit
}

/**
 * Client which sends no cert and trusts any server
 */
fun main(args: Array<String>) {
    val trustAllCerts = arrayOf<TrustManager>(NoOpX509TrustManager)

    val sc = SSLContext.getInstance("SSL")
    sc.init(null, trustAllCerts, java.security.SecureRandom())
    HttpsURLConnection.setDefaultSSLSocketFactory(sc.socketFactory)

    val url = URL("https://localhost:8443/ping")
    println("URL: $url")

    val conn = url.openConnection();
    conn.getInputStream()
}


