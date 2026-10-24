package com.voidai.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import android.os.Bundle
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.provider.Settings
import android.net.Uri
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.util.Locale
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

private data class ChatLine(val text: String, val fromUser: Boolean)

class MainActivity : ComponentActivity(), TextToSpeech.OnInitListener {
    private var tts: TextToSpeech? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private var speechCallback: ((String) -> Unit)? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        tts = TextToSpeech(this, this)
        if (android.os.Build.VERSION.SDK_INT >= 23 && checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) { requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 2401) }
        if (SpeechRecognizer.isRecognitionAvailable(this)) speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        setContent {
            VoidAiApp(
                onCommand = { runCommand(it) },
                onAskAI = { question, callback -> askGemini(question, callback) },
                onSaveApiKey = { key -> getSharedPreferences("void_ai", MODE_PRIVATE).edit().putString("gemini_api_key", key.trim()).apply() },
                hasApiKey = { !getSharedPreferences("void_ai", MODE_PRIVATE).getString("gemini_api_key", "").isNullOrBlank() },
                onListen = { callback -> startListening(callback) },
                onSpeak = { say(it) },
                onAccessibility = { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)) }
            )
        }
    }

    override fun onInit(status: Int) { if (status == TextToSpeech.SUCCESS) tts?.language = Locale("ar", "IQ") }

    private fun say(text: String) { tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "void-ai-response") }

    private fun startListening(callback: (String) -> Unit) {
        val recognizer = speechRecognizer
        if (recognizer == null) {
            Toast.makeText(this, "التعرف الصوتي غير متوفر بهذا الجهاز", Toast.LENGTH_LONG).show()
            return
        }
        speechCallback = callback
        recognizer.setRecognitionListener(object : android.speech.RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onError(error: Int) { runOnUiThread { Toast.makeText(this@MainActivity, "ما سمعت الأمر بوضوح، جرّب مرة ثانية", Toast.LENGTH_SHORT).show() } }
            override fun onResults(results: Bundle?) {
                val text = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                if (!text.isNullOrBlank()) runOnUiThread { speechCallback?.invoke(text) }
            }
            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ar-IQ")
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "ar-IQ")
            putExtra(RecognizerIntent.EXTRA_PROMPT, "احچي الأمر هسه")
        }
        recognizer.startListening(intent)
    }

    private fun askGemini(question: String, callback: (String) -> Unit) {
        val key = getSharedPreferences("void_ai", MODE_PRIVATE).getString("gemini_api_key", "").orEmpty()
        if (key.isBlank()) { callback("اضغط ربط AI وأضف مفتاح Gemini API أولاً."); return }
        Thread {
            val answer = try {
                val endpoint = URL("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + java.net.URLEncoder.encode(key, "UTF-8"))
                val connection = endpoint.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.connectTimeout = 20000
                connection.readTimeout = 30000
                connection.doOutput = true
                connection.setRequestProperty("Content-Type", "application/json; charset=utf-8")
                val body = JSONObject().put("contents", org.json.JSONArray().put(JSONObject().put("parts", org.json.JSONArray().put(JSONObject().put("text", "أنت VOID AI، مساعد عربي ودود. أجب باللهجة العراقية عند ملاءمتها، ولا تدّع تنفيذ أفعال على الجهاز. سؤال المستخدم: " + question)))))
                connection.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
                val code = connection.responseCode
                val stream = if (code in 200..299) connection.inputStream else connection.errorStream
                val raw = stream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                connection.disconnect()
                if (code !in 200..299) "Gemini رفض الطلب (HTTP $code). تأكد من المفتاح وتفعيله." else JSONObject(raw).optJSONArray("candidates")?.optJSONObject(0)?.optJSONObject("content")?.optJSONArray("parts")?.optJSONObject(0)?.optString("text")?.takeIf { it.isNotBlank() } ?: "ما وصلني رد واضح من Gemini."
            } catch (_: Exception) { "تعذر الاتصال بـ Gemini. تأكد من الإنترنت وصحة المفتاح." }
            runOnUiThread { callback(answer); say(answer) }
        }.start()
    }

    private fun runCommand(raw: String): String {
        val command = raw.trim().lowercase(Locale.ROOT)
        val result = when {
            command.contains("افتح يوتيوب") || command.contains("شغل يوتيوب") ->
                launchPackage("com.google.android.youtube", "ما لكيت يوتيوب مثبت")
            command.contains("افتح واتساب") || command.contains("شغل واتساب") ->
                launchPackage("com.whatsapp", "ما لكيت واتساب مثبت")
            command.contains("افتح تيليجرام") || command.contains("افتح تلغرام") ->
                launchPackage("org.telegram.messenger", "ما لكيت تيليجرام مثبت")
            command.contains("افتح كروم") || command.contains("افتح المتصفح") ->
                launchPackage("com.android.chrome", "ما لكيت كروم مثبت")
            command.contains("افتح الكاميرا") || command.contains("شغل الكاميرا") ->
                try { startActivity(Intent("android.media.action.IMAGE_CAPTURE")); "فتحت الكاميرا" } catch (_: Exception) { "تعذر فتح الكاميرا" }
            command.contains("افتح الإعدادات") || command.contains("افتح الاعدادات") ->
                try { startActivity(Intent(Settings.ACTION_SETTINGS)); "فتحت الإعدادات" } catch (_: Exception) { "تعذر فتح الإعدادات" }
            command.contains("الواي فاي") || command.contains("wifi") ->
                try { startActivity(Intent(Settings.ACTION_WIFI_SETTINGS)); "فتحت إعدادات الواي فاي. فعّل أو أوقفه بنفسك من هناك" } catch (_: Exception) { "تعذر فتح إعدادات الواي فاي" }
            command.contains("البلوتوث") ->
                try { startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS)); "فتحت إعدادات البلوتوث" } catch (_: Exception) { "تعذر فتح إعدادات البلوتوث" }
            command.contains("الصوت") && (command.contains("ارفع") || command.contains("خفض")) ->
                try { startActivity(Intent(Settings.ACTION_SOUND_SETTINGS)); "فتحت إعدادات الصوت حتى تغيّر المستوى" } catch (_: Exception) { "تعذر فتح إعدادات الصوت" }
            command.contains("تسهيلات الاستخدام") || command.contains("صلاحية التحكم") ->
                try { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)); "افتح خدمة VOID AI من القائمة وفعّلها بنفسك" } catch (_: Exception) { "تعذر فتح الإعدادات" }
            command.contains("ارجع") || command == "رجوع" ->
                if (VoidAccessibilityService.instance != null) { VoidAccessibilityService.instance?.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK); "رجعت للخلف" } else "فعّل خدمة VOID AI من تسهيلات الاستخدام أولاً"
            command.contains("الرئيسية") || command.contains("الشاشة الرئيسية") ->
                if (VoidAccessibilityService.instance != null) { VoidAccessibilityService.instance?.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_HOME); "رجعت للشاشة الرئيسية" } else "فعّل خدمة VOID AI من تسهيلات الاستخدام أولاً"
            command.contains("انزل") || command.contains("مرر للأسفل") ->
                if (VoidAccessibilityService.instance?.scroll(false) == true) "مررت الشاشة للأسفل" else "فعّل خدمة VOID AI أو افتح شاشة قابلة للتمرير"
            command.contains("اصعد") || command.contains("مرر للأعلى") ->
                if (VoidAccessibilityService.instance?.scroll(true) == true) "مررت الشاشة للأعلى" else "فعّل خدمة VOID AI أو افتح شاشة قابلة للتمرير"
            command.startsWith("اضغط ") || command.startsWith("انقر على ") ->
                if (VoidAccessibilityService.instance?.clickText(raw.substringAfter(" ").removePrefix("على ").trim()) == true) "نفذت النقر على العنصر المطلوب" else "ما لكيت العنصر. تأكد من تفعيل الخدمة وأن النص ظاهر بالشاشة"
            command.startsWith("اكتب ") ->
                if (VoidAccessibilityService.instance?.setFocusedText(raw.removePrefix("اكتب ").trim()) == true) "كتبت النص بالحقل المحدد" else "اضغط أولاً داخل حقل كتابة وفعّل خدمة VOID AI"
            else -> "أكدر أنفذ أوامر محددة حالياً: افتح يوتيوب، واتساب، تيليجرام، الكاميرا، الإعدادات، الواي فاي، أوامر رجوع/الرئيسية/تمرير، واضغط [اسم العنصر] أو اكتب [نص]. أوامر الذكاء الاصطناعي العامة تحتاج ربط محرك AI."
        }
        say(result)
        return result
    }

    private fun launchPackage(packageName: String, error: String): String = try {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        if (intent == null) error else { startActivity(intent); "تم فتح التطبيق" }
    } catch (_: Exception) { error }

    override fun onDestroy() {
        speechRecognizer?.destroy()
        tts?.shutdown()
        super.onDestroy()
    }
}

@Composable
private fun VoidAiApp(
    onCommand: (String) -> String,
    onAskAI: (String, (String) -> Unit) -> Unit,
    onSaveApiKey: (String) -> Unit,
    hasApiKey: () -> Boolean,
    onListen: ((String) -> Unit) -> Unit,
    onSpeak: (String) -> Unit,
    onAccessibility: () -> Unit
) {
    val bg = Color(0xFF080B12)
    val panel = Color(0xFF131A27)
    val cyan = Color(0xFF47E6D2)
    var input by remember { mutableStateOf("") }
    var listening by remember { mutableStateOf(false) }
    var apiDialog by remember { mutableStateOf(false) }
    var apiKeyInput by remember { mutableStateOf("") }
    var thinking by remember { mutableStateOf(false) }
    var messages by remember { mutableStateOf(listOf(ChatLine("أهلاً بيك، أني VOID AI. أگدر أفتح تطبيقات وأتعامل ويا أوامر محددة. للتحكم بالشاشة فعّل خدمة تسهيلات الاستخدام من الزر أدناه.", false))) }
    fun submit(text: String) {
        if (text.isBlank()) return
        messages = messages + ChatLine(text, true)
        input = ""
        val response = onCommand(text)
        if (response.startsWith("أكدر أنفذ أوامر محددة حالياً")) {
            thinking = true
            onAskAI(text) { aiResponse -> messages = messages + ChatLine(aiResponse, false); thinking = false }
        } else messages = messages + ChatLine(response, false)
    }
    MaterialTheme(colorScheme = darkColorScheme(background = bg, surface = panel, primary = cyan)) {
        Column(Modifier.fillMaxSize().background(bg).padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(44.dp).background(cyan, RoundedCornerShape(14.dp)), contentAlignment = Alignment.Center) {
                    Text("V", color = bg, fontSize = 25.sp, fontWeight = FontWeight.Black)
                }
                Spacer(Modifier.width(12.dp))
                Column {
                    Text("VOID AI", fontSize = 23.sp, fontWeight = FontWeight.Bold, color = Color.White)
                    Text("تحكم بالصوت والكتابة", fontSize = 13.sp, color = cyan)
                }
            }
            Spacer(Modifier.height(12.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(onClick = onAccessibility, modifier = Modifier.weight(1f)) { Text("التحكم بالشاشة") }
                OutlinedButton(onClick = { apiKeyInput = ""; apiDialog = true }) { Text(if (hasApiKey()) "ربط AI ✓" else "ربط AI 🔑") }
            }
            if (thinking) Text("VOID AI يفكر...", color = cyan, fontSize = 13.sp)
            Spacer(Modifier.height(12.dp))
            Surface(color = panel, shape = RoundedCornerShape(18.dp), modifier = Modifier.fillMaxWidth().weight(1f)) {
                LazyColumn(Modifier.fillMaxSize().padding(12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(messages) { msg ->
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = if (msg.fromUser) Arrangement.Start else Arrangement.End) {
                            Surface(color = if (msg.fromUser) Color(0xFF173A42) else Color(0xFF20293A), shape = RoundedCornerShape(16.dp), modifier = Modifier.widthIn(max = 300.dp)) {
                                Text(msg.text, Modifier.padding(12.dp), color = Color.White, textAlign = TextAlign.Right, fontSize = 15.sp)
                            }
                        }
                    }
                }
            }
            Spacer(Modifier.height(12.dp))
            Row(Modifier.fillMaxWidth().background(panel, RoundedCornerShape(18.dp)).padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
                BasicTextField(value = input, onValueChange = { input = it }, modifier = Modifier.weight(1f).padding(horizontal = 8.dp, vertical = 12.dp), textStyle = androidx.compose.ui.text.TextStyle(color = Color.White, fontSize = 15.sp), cursorBrush = androidx.compose.ui.graphics.SolidColor(cyan), decorationBox = { inner ->
                    Box { if (input.isEmpty()) Text("مثال: افتح يوتيوب...", color = Color.Gray); inner() }
                })
                IconButton(onClick = { onListen { spoken -> input = spoken; submit(spoken) } }) {
                    Icon(Icons.Default.Mic, contentDescription = "تحدث", tint = cyan)
                }
                IconButton(onClick = { submit(input) }) { Icon(Icons.Default.Send, contentDescription = "إرسال", tint = cyan) }
            }
            Spacer(Modifier.height(5.dp))
            Text("الذكاء الاصطناعي يحتاج إنترنت ومفتاح Gemini • VOID AI", Modifier.fillMaxWidth(), color = Color.Gray, fontSize = 10.sp, textAlign = TextAlign.Center)
        }
        if (apiDialog) {
            AlertDialog(
                onDismissRequest = { apiDialog = false },
                title = { Text("ربط VOID AI مع Gemini") },
                text = {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("الصق مفتاح API. يُحفظ على هذا الجهاز داخل بيانات التطبيق، لكنه غير مشفّر؛ لا تشاركه.")
                        OutlinedTextField(value = apiKeyInput, onValueChange = { apiKeyInput = it }, label = { Text("Gemini API key") }, singleLine = true, visualTransformation = androidx.compose.ui.text.input.PasswordVisualTransformation())
                    }
                },
                confirmButton = { TextButton(onClick = { if (apiKeyInput.isNotBlank()) { onSaveApiKey(apiKeyInput); apiDialog = false; apiKeyInput = "" } }) { Text("حفظ المفتاح") } },
                dismissButton = { TextButton(onClick = { apiDialog = false }) { Text("إلغاء") } }
            )
        }
    }
}
