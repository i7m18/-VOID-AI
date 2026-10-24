package com.voidai.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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
                onRunAgent = { goal, callback -> runAgentTask(goal, callback) },
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

    private fun askGemini(question: String, callback: (String) -> Unit, speakAnswer: Boolean = true, agentPrompt: Boolean = false) {
        val key = getSharedPreferences("void_ai", MODE_PRIVATE).getString("gemini_api_key", "").orEmpty()
        if (key.isBlank()) { callback("اضغط ربط AI وأضف مفتاح Gemini API أولاً."); return }
        Thread {
            val answer = try {
                val endpoint = URL("https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent?key=" + java.net.URLEncoder.encode(key, "UTF-8"))
                val connection = endpoint.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.connectTimeout = 20000
                connection.readTimeout = 30000
                connection.doOutput = true
                connection.setRequestProperty("Content-Type", "application/json; charset=utf-8")
                val requestText = if (agentPrompt) question else "أنت VOID AI، مساعد عربي ودود. أجب باللهجة العراقية عند ملاءمتها، ولا تدّع تنفيذ أفعال على الجهاز. سؤال المستخدم: " + question
                val body = JSONObject()
                    .put("contents", org.json.JSONArray().put(JSONObject().put("parts", org.json.JSONArray().put(JSONObject().put("text", requestText)))))
                if (agentPrompt) body.put("generationConfig", JSONObject().put("responseMimeType", "application/json"))
                connection.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
                val code = connection.responseCode
                val stream = if (code in 200..299) connection.inputStream else connection.errorStream
                val raw = stream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                connection.disconnect()
                if (code !in 200..299) {
                    val detail = try { JSONObject(raw).optJSONObject("error")?.optString("message").orEmpty() } catch (_: Exception) { "" }
                    val reason = detail.ifBlank { raw.take(240) }
                    when (code) {
                        400 -> "Gemini رفض صيغة الطلب (400): $reason"
                        401 -> "مفتاح Gemini غير صحيح أو منتهي (401). افتح ربط AI واحفظ مفتاحاً صالحاً. التفاصيل: $reason"
                        403 -> "المفتاح أو مشروع Google لا يملك صلاحية Gemini API (403). راجع صلاحيات المفتاح وحالة المشروع. التفاصيل: $reason"
                        404 -> "نموذج Gemini غير موجود أو غير متاح لهذا المشروع (404). حدّث التطبيق أو تحقق من دعم النموذج للمفتاح. التفاصيل: $reason"
                        429 -> "تم تجاوز حصة الاستخدام أو عدد الطلبات (429). جرّب لاحقاً أو راجع الحصة. التفاصيل: $reason"
                        else -> "Gemini رفض الطلب (HTTP $code): $reason"
                    }
                } else {
                    val parts = JSONObject(raw).optJSONArray("candidates")?.optJSONObject(0)?.optJSONObject("content")?.optJSONArray("parts")
                    (0 until (parts?.length() ?: 0)).mapNotNull { i -> parts?.optJSONObject(i)?.optString("text")?.takeIf { !it.isNullOrBlank() } }.joinToString("\n").ifBlank { "ما وصلني رد واضح من Gemini." }
                }
            } catch (_: Exception) { "تعذر الاتصال بـ Gemini. تأكد من الإنترنت وصحة المفتاح." }
            runOnUiThread { callback(answer); if (speakAnswer) say(answer) }
        }.start()
    }

    private fun installedAppLabels(): List<Pair<String, String>> {
        return try {
            val launchIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
            packageManager.queryIntentActivities(launchIntent, 0)
                .map { info -> info.loadLabel(packageManager).toString() to info.activityInfo.packageName }
                .distinctBy { it.second }
                .sortedBy { it.first.lowercase(Locale.ROOT) }
                .take(120)
        } catch (_: Exception) { emptyList() }
    }

    private fun launchAppByLabel(name: String): Boolean {
        val wanted = name.trim().lowercase(Locale.ROOT).replace(" ", "")
        if (wanted.isBlank()) return false
        val match = installedAppLabels().firstOrNull { (label, _) ->
            val candidate = label.lowercase(Locale.ROOT).replace(" ", "")
            candidate == wanted || candidate.contains(wanted) || (wanted.length > 3 && wanted.contains(candidate) && candidate.length > 3)
        } ?: return false
        val intent = packageManager.getLaunchIntentForPackage(match.second) ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try { startActivity(intent); true } catch (_: Exception) { false }
    }

    private fun runAgentTask(goal: String, callback: (String) -> Unit) {
        val history = mutableListOf<String>()
        val handler = Handler(Looper.getMainLooper())
        fun step(index: Int) {
            if (index >= 14) {
                callback("وصلت حد خطوات التنفيذ الآمنة. اللي تم لحد الآن: " +
                    if (history.isEmpty()) "ما نفّذت خطوة." else history.takeLast(5).joinToString("، ") +
                    ". گدر تكلي أكمل من الشاشة الحالية.")
                return
            }
            val service = VoidAccessibilityService.instance
            val screen = service?.visibleText() ?: "خدمة التحكم بالشاشة غير مفعلة. يمكن فتح تطبيق فقط، لكن قراءة الشاشة والنقر والكتابة تحتاج تفعيل خدمة VOID AI من تسهيلات الاستخدام."
            val apps = installedAppLabels().joinToString(", ") { it.first }.take(4500)
            val prompt = listOf(
                "أنت وكيل تحكم محلي داخل VOID AI على أندرويد. المطلوب من المستخدم: " + goal,
                "الخطوات المنفذة سابقاً: " + history.joinToString(" | ").ifBlank { "لا توجد" },
                "الشاشة الحالية:\n" + screen,
                "التطبيقات المثبتة التي يمكن فتحها:\n" + apps,
                """قرر خطوة واحدة فقط حسب الشاشة والمطلوب، ثم أعد JSON صالحاً فقط بالشكل:
{"action":"open_app|click|type|scroll_down|scroll_up|back|home|wait|done|needs_confirmation","target":"","text":"","message":""}
القواعد:
- إذا كان المطلوب سؤالاً أو دردشة وليس تحكماً بالجهاز، أجب عبر action=done و message.
- نفذ خطوة واحدة كل مرة؛ بعد كل خطوة ستصلك حالة الشاشة الجديدة.
- open_app: target اسم التطبيق المثبت كما يظهر بالقائمة.
- click: target نص زر أو تبويب ظاهر حرفياً أو قريب جداً منه.
- type: text النص الذي طلب المستخدم كتابته، فقط بعد وجود حقل تحرير مناسب ومحدد. لا تكتب كلمات مرور أو رموز تحقق أو مفاتيح API أو بيانات بطاقة أو معلومات مالية حساسة.
- scroll_down / scroll_up / back / home / wait لا تحتاج target أو text.
- لا تدّع نجاح خطوة إذا لم تظهر علامة نجاح.
- لا ترسل رسائل، ولا تنشر، ولا تحذف ملفات أو حسابات، ولا تشتري أو تدفع، ولا تغيّر إعدادات أمنية؛ استخدم needs_confirmation واطلب من المستخدم تنفيذ التأكيد بنفسه.
- لا تتجاوز شاشة تسجيل دخول أو حماية، ولا تحاول تخطي قيود التطبيقات.
- إذا الخدمة غير مفعلة، أو التطبيق لا يوفر عناصر مقروءة، أو لا تستطيع تحديد الخطوة بثقة، أوقف المهمة برسالة واضحة action=done.
- عند اكتمال المهمة أعد action=done ورسالة عربية قصيرة وصادقة.
- لا تستخدم Markdown أو code fences؛ أعد كائن JSON واحداً فقط."""
            ).joinToString("\n\n")
            askGemini(prompt, { raw ->
                val parsed = try {
                    val start = raw.indexOf('{')
                    val end = raw.lastIndexOf('}')
                    if (start >= 0 && end > start) JSONObject(raw.substring(start, end + 1)) else null
                } catch (_: Exception) { null }
                if (parsed == null) {
                    callback(raw)
                    return@askGemini
                }
                val action = parsed.optString("action", "done").lowercase(Locale.ROOT)
                val target = parsed.optString("target", "")
                val textValue = parsed.optString("text", "")
                val message = parsed.optString("message", "")
                if (action == "done") {
                    callback(message.ifBlank { "وقفت هنا حتى ما أنفذ خطوة غير مؤكدة." })
                    return@askGemini
                }
                if (action == "needs_confirmation") {
                    callback(message.ifBlank { "هذي الخطوة تحتاج تأكيد منك داخل التطبيق؛ ما نفذتها." })
                    return@askGemini
                }
                val success = when (action) {
                    "open_app" -> launchAppByLabel(target)
                    "click" -> VoidAccessibilityService.instance?.clickText(target) == true
                    "type" -> VoidAccessibilityService.instance?.setFocusedText(textValue) == true
                    "scroll_down" -> VoidAccessibilityService.instance?.scroll(false) == true
                    "scroll_up" -> VoidAccessibilityService.instance?.scroll(true) == true
                    "back" -> VoidAccessibilityService.instance?.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK) == true
                    "home" -> VoidAccessibilityService.instance?.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_HOME) == true
                    "wait" -> true
                    else -> false
                }
                if (!success) {
                    callback("ما قدرت أنفذ الخطوة «" + (if (target.isNotBlank()) target else action) + "». تأكد من تفعيل خدمة التحكم وأن العنصر ظاهر بالشاشة، أو نفّذ هالخطوة يدوياً.")
                    return@askGemini
                }
                history.add(action + if (target.isNotBlank()) "(" + target + ")" else if (textValue.isNotBlank()) "(نص)" else "")
                handler.postDelayed({ step(index + 1) }, if (action == "wait") 1300L else 900L)
            }, speakAnswer = false, agentPrompt = true)
        }
        if (getSharedPreferences("void_ai", MODE_PRIVATE).getString("gemini_api_key", "").isNullOrBlank()) {
            callback("اربط Gemini API أولاً من زر «ربط AI» حتى أقدر أخطط للخطوات.")
            return
        }
        step(0)
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
        if (!result.startsWith("أكدر أنفذ أوامر محددة حالياً")) say(result)
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
    onRunAgent: (String, (String) -> Unit) -> Unit,
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
            onRunAgent(text) { aiResponse ->
                messages = messages + ChatLine(aiResponse, false)
                thinking = false
                onSpeak(aiResponse)
            }
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
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                Button(onClick = onAccessibility, modifier = Modifier.weight(1.15f), contentPadding = PaddingValues(horizontal = 8.dp, vertical = 10.dp)) { Text("التحكم", fontSize = 12.sp) }
                OutlinedButton(onClick = { apiKeyInput = ""; apiDialog = true }, modifier = Modifier.weight(1f), contentPadding = PaddingValues(horizontal = 8.dp, vertical = 10.dp)) { Text(if (hasApiKey()) "ربط AI ✓" else "ربط AI 🔑", fontSize = 12.sp) }
                OutlinedButton(
                    onClick = {
                        if (!hasApiKey()) {
                            messages = messages + ChatLine("اربط مفتاح Gemini أولاً من زر ربط AI.", false)
                        } else {
                            thinking = true
                            onAskAI("أجب بكلمة تم فقط. هذا اختبار اتصال Gemini داخل تطبيق VOID AI.") { answer ->
                                messages = messages + ChatLine(
                                    if (listOf("Gemini رفض", "تعذر الاتصال", "مفتاح Gemini", "المفتاح أو مشروع", "نموذج Gemini", "تم تجاوز حصة", "طلب Gemini", "اربط Gemini").any { answer.startsWith(it) }) "فشل اختبار Gemini: $answer" else "نجح الاتصال بـ Gemini. الرد: $answer",
                                    false
                                )
                                thinking = false
                            }
                        }
                    },
                    modifier = Modifier.weight(0.9f),
                    contentPadding = PaddingValues(horizontal = 6.dp, vertical = 10.dp)
                ) { Text("اختبار", fontSize = 12.sp) }
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
