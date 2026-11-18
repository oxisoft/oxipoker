package io.oxisoft.oxipoker

import android.os.CancellationSignal
import androidx.credentials.CreateCredentialResponse
import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.PublicKeyCredential
import androidx.credentials.exceptions.CreateCredentialCancellationException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Passkeys through Android Credential Manager. Requests and responses are the
 * WebAuthn JSON the server speaks (publicKey options in, credential JSON out),
 * so Dart passes strings through unchanged.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "io.oxisoft.oxipoker/passkeys")
            .setMethodCallHandler { call, result ->
                val json = call.argument<String>("options")
                if (json == null) {
                    result.error("bad_args", "options missing", null)
                    return@setMethodCallHandler
                }
                val cm = CredentialManager.create(this)
                when (call.method) {
                    "create" -> cm.createCredentialAsync(
                        this, CreatePublicKeyCredentialRequest(json), CancellationSignal(), mainExecutor,
                        object : CredentialManagerCallback<CreateCredentialResponse, CreateCredentialException> {
                            override fun onResult(res: CreateCredentialResponse) {
                                if (res is CreatePublicKeyCredentialResponse) {
                                    result.success(res.registrationResponseJson)
                                } else {
                                    result.error("failed", "not a passkey", null)
                                }
                            }

                            override fun onError(e: CreateCredentialException) {
                                val code = if (e is CreateCredentialCancellationException) "cancelled" else "failed"
                                result.error(code, "${e.type}: ${e.message}", null)
                            }
                        },
                    )
                    "get" -> cm.getCredentialAsync(
                        this, GetCredentialRequest(listOf(GetPublicKeyCredentialOption(json))), CancellationSignal(),
                        mainExecutor,
                        object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                            override fun onResult(res: GetCredentialResponse) {
                                val cred = res.credential
                                if (cred is PublicKeyCredential) {
                                    result.success(cred.authenticationResponseJson)
                                } else {
                                    result.error("failed", "not a passkey", null)
                                }
                            }

                            override fun onError(e: GetCredentialException) {
                                val code = if (e is GetCredentialCancellationException || e is NoCredentialException) "cancelled" else "failed"
                                result.error(code, "${e.type}: ${e.message}", null)
                            }
                        },
                    )
                    else -> result.notImplemented()
                }
            }
    }
}
