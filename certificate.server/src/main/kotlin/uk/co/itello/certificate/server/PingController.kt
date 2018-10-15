package uk.co.itello.certificate.server

import org.slf4j.LoggerFactory
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.security.cert.X509Certificate
import javax.servlet.http.HttpServletRequest

@RestController
class PingController {
    companion object {
        val LOG = LoggerFactory.getLogger(PingController::class.java)!!
    }
    @RequestMapping("/ping")
    fun ping(req: HttpServletRequest): String {


        LOG.info("Requesting client cert")
        Thread.sleep(500) // time for logging
        val cert = extractCertificate(req)
        LOG.info("Client cert name: [{}]", cert.subjectDN)

        return "pong"
    }

    @Suppress("UNCHECKED_CAST")
    protected fun extractCertificate(req: HttpServletRequest): X509Certificate {
        val certs = req.getAttribute("javax.servlet.request.X509Certificate") as Array<X509Certificate>
        if (certs.isNotEmpty()) {
            return certs[0]
        }
        throw RuntimeException("No X509 client certificate found in request")
    }
}

