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
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
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
import androidx.compose.ui.graphics.Brush
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
                val models = listOf("gemini-3.8-flash", "gemini-3.6-flash", "gemini-3.5-flash-lite")
                var finalAnswer = ""
                var completed = false
                var lastBusyMessage = "خدمة Gemini مشغولة حالياً."
                for (model in models) {
                    var attempt = 0
                    val maxAttempts = if (model == models.first()) 2 else 1
                    while (attempt < maxAttempts && !completed) {
                        attempt += 1
                        var connection: HttpURLConnection? = null
                        try {
                            val endpoint = URL("https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent?key=" + java.net.URLEncoder.encode(key, "UTF-8"))
                            connection = endpoint.openConnection() as HttpURLConnection
                            connection.requestMethod = "POST"
                            connection.connectTimeout = 12000
                            connection.readTimeout = 25000
                            connection.doOutput = true
                            connection.setRequestProperty("Content-Type", "application/json; charset=utf-8")
                            val requestText = if (agentPrompt) question else "أنت VOID AI، مساعد عربي ودود. أجب باللهجة العراقية عند ملاءمتها، ولا تدّع تنفيذ أفعال على الجهاز. سؤال المستخدم: " + question
                            val body = JSONObject()
                                .put("contents", org.json.JSONArray().put(JSONObject().put("parts", org.json.JSONArray().put(JSONObject().put("text", requestText)))))
                            if (agentPrompt) body.put("generationConfig", JSONObject().put("responseMimeType", "application/json"))
                            connection.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
                            val code = connection.responseCode
                            val stream = if (code in 200..299) connection.inputStream else connection.errorStream
                            val raw = stream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }.orEmpty()
                            if (code in 200..299) {
                                val parts = JSONObject(raw).optJSONArray("candidates")?.optJSONObject(0)?.optJSONObject("content")?.optJSONArray("parts")
                                finalAnswer = (0 until (parts?.length() ?: 0))
                                    .mapNotNull { i -> parts?.optJSONObject(i)?.optString("text")?.takeIf { !it.isNullOrBlank() } }
                                    .joinToString("\n")
                                    .ifBlank { "ما وصلني رد واضح من Gemini." }
                                completed = true
                            } else {
                                val detail = try { JSONObject(raw).optJSONObject("error")?.optString("message").orEmpty() } catch (_: Exception) { "" }
                                val reason = detail.ifBlank { raw.take(240) }
                                if (code == 503 || code == 429) {
                                    lastBusyMessage = if (code == 503) "Gemini عليه ضغط مؤقت (503)." else "Gemini وصل حد الطلبات أو الحصة (429)."
                                    if (attempt < 3) {
                                        Thread.sleep(450L * attempt)
                                    } else {
                                        lastBusyMessage += " التفاصيل: " + reason + " — جرّبت إعادة الاتصال تلقائياً، وراح أجرب نموذج احتياطي."
                                        break
                                    }
                                } else {
                                    finalAnswer = when (code) {
                                        400 -> "Gemini رفض صيغة الطلب (400): " + reason
                                        401 -> "مفتاح Gemini غير صحيح أو منتهي (401). افتح ربط AI واحفظ مفتاحاً صالحاً. التفاصيل: " + reason
                                        403 -> "المفتاح أو مشروع Google لا يملك صلاحية Gemini API (403). التفاصيل: " + reason
                                        404 -> "نموذج Gemini غير موجود أو غير متاح لهذا المشروع (404). التفاصيل: " + reason
                                        else -> "Gemini رفض الطلب (HTTP " + code + "): " + reason
                                    }
                                    completed = true
                                }
                            }
                        } catch (e: Exception) {
                            if (attempt < 3) {
                                try { Thread.sleep(400L * attempt) } catch (_: InterruptedException) {}
                            } else {
                                lastBusyMessage = "تعذر الاتصال بـ Gemini بعد عدة محاولات: " + (e.message ?: "تأكد من الإنترنت.")
                                break
                            }
                        } finally {
                            connection?.disconnect()
                        }
                    }
                    if (completed) break
                }
                if (completed) finalAnswer else lastBusyMessage + " جرّب بعد قليل أو اختبر اتصال الشبكة والمفتاح."
            } catch (e: Exception) {
                "تعذر الاتصال بـ Gemini. تأكد من الإنترنت. التفاصيل: " + (e.message ?: "خطأ غير معروف")
            }
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
        val cleaned = name.trim().lowercase(Locale.ROOT).replace(" ", "")
        if (cleaned.isBlank()) return false
        val aliases = mapOf(
            "capcut" to "com.lemon.lvoverseas",
            "كابكات" to "com.lemon.lvoverseas",
            "كابكت" to "com.lemon.lvoverseas",
            "كابكوت" to "com.lemon.lvoverseas",
            "يوتيوب" to "com.google.android.youtube",
            "واتساب" to "com.whatsapp",
            "تيليجرام" to "org.telegram.messenger"
        )
        val directPackage = aliases[cleaned]
        if (directPackage != null) {
            val directIntent = packageManager.getLaunchIntentForPackage(directPackage)
            if (directIntent != null) return try { startActivity(directIntent); true } catch (_: Exception) { false }
        }
        val match = installedAppLabels().firstOrNull { (label, _) ->
            val candidate = label.lowercase(Locale.ROOT).replace(" ", "")
            candidate == cleaned || candidate.contains(cleaned) || (cleaned.length > 3 && cleaned.contains(candidate) && candidate.length > 3)
        } ?: return false
        val intent = packageManager.getLaunchIntentForPackage(match.second) ?: return false
        return try { startActivity(intent); true } catch (_: Exception) { false }
    }

    private fun runAgentTask(goal: String, callback: (String) -> Unit) {
        val history = mutableListOf<String>()
        var consecutiveFailures = 0
        val handler = Handler(Looper.getMainLooper())
        fun step(index: Int) {
            if (index >= 16) {
                callback("وصلت حد خطوات التنفيذ الآمنة. اللي تم لحد الآن: " +
                    if (history.isEmpty()) "ما نفّذت خطوة." else history.takeLast(5).joinToString("، ") +
                    ". گدر تكلي أكمل من الشاشة الحالية.")
                return
            }
            val service = VoidAccessibilityService.instance
            val screen = (service?.visibleText() ?: "خدمة التحكم بالشاشة غير مفعلة. يمكن فتح تطبيق فقط، لكن قراءة الشاشة والنقر والكتابة تحتاج تفعيل خدمة VOID AI من تسهيلات الاستخدام.").take(2600)
            val apps = installedAppLabels().joinToString(", ") { it.first }.take(1400)
            val prompt = listOf(
                "أنت وكيل تحكم محلي داخل VOID AI على أندرويد. المطلوب من المستخدم: " + goal,
                if (goal.contains("فيديو", true) || goal.contains("مونتاج", true) || goal.contains("CapCut", true)) "مهمة تحرير/تصميم فيديو: لا تعتبر فتح CapCut إنجازاً. افحص الشاشة، أنشئ مشروعاً عند توفر زر واضح، اختر الوسائط التي حدّدها المستخدم فقط، ونفّذ التحرير خطوة بخطوة. لا تخترع وسائط أو تدّع تصدير فيديو إذا لم يحدث فعلاً. إذا احتجت ملفاً أو اختياراً من المستخدم، اطلبه بوضوح." else "نفّذ المهمة المطلوبة قدر الإمكان على الشاشة الحالية، ولا تكتفِ بوصف ما ستفعله.",
                "الخطوات المنفذة سابقاً: " + history.joinToString(" | ").ifBlank { "لا توجد" },
                "الشاشة الحالية:\n" + screen,
                "التطبيقات المثبتة التي يمكن فتحها:\n" + apps,
                """قرر خطوة واحدة فقط حسب الشاشة والمطلوب، ثم أعد JSON صالحاً فقط بالشكل:
{"action":"open_app|click|type|scroll_down|scroll_up|back|home|wait|done|needs_confirmation","target":"","text":"","message":"","wait_ms":1500}
القواعد:
- إذا كان المطلوب سؤالاً أو دردشة وليس تحكماً بالجهاز، أجب عبر action=done و message.
- نفذ خطوة واحدة كل مرة؛ بعد كل خطوة ستصلك حالة الشاشة الجديدة. استخدم wait عند تحميل واجهة أو مشروع، وحدد wait_ms بين 700 و5000 حسب الحاجة.
- في مهام التصميم، ابدأ بإنشاء مشروع/اختيار ملف فقط إذا ظهر المسار بوضوح. لا تدّع اكتمال التصدير دون دليل مرئي.
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
                    consecutiveFailures += 1
                    history.add("تعذر تنفيذ " + action + if (target.isNotBlank()) " على «" + target + "»" else "")
                    if (consecutiveFailures >= 3 || index >= 15) {
                        callback("توقفت بعد عدة محاولات غير ناجحة. آخر خطوة تعذرت: «" + (if (target.isNotBlank()) target else action) + "». تأكد من صلاحية التحكم وأن العنصر ظاهر، ثم أعد المحاولة.")
                    } else {
                        handler.postDelayed({ step(index + 1) }, 1000L)
                    }
                    return@askGemini
                }
                consecutiveFailures = 0
                history.add(action + if (target.isNotBlank()) "(" + target + ")" else if (textValue.isNotBlank()) "(نص)" else "")
                val delayMs = when (action) {
                    "open_app" -> 1800L
                    "click" -> 950L
                    "type" -> 700L
                    "wait" -> parsed.optInt("wait_ms", 1500).coerceIn(700, 5000).toLong()
                    else -> 800L
                }
                handler.postDelayed({ step(index + 1) }, delayMs)
            }, speakAnswer = false, agentPrompt = true)
        }
        if (VoidAccessibilityService.instance == null) {
            callback("حتى أنفّذ مهمة متعددة الخطوات، فعّل خدمة VOID AI من زر «تحكم الشاشة» داخل تسهيلات الاستخدام ثم ارجع للتطبيق.")
            return
        }
        if (getSharedPreferences("void_ai", MODE_PRIVATE).getString("gemini_api_key", "").isNullOrBlank()) {
            callback("اربط Gemini API أولاً من زر «ربط AI» حتى أقدر أخطط للخطوات.")
            return
        }
        handler.postDelayed({ step(0) }, 700L)
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
            command.startsWith("افتح ") || command.startsWith("شغل ") || command.startsWith("شغّل ") -> {
                val appName = raw.substringAfter(" ").trim()
                    .removePrefix("تطبيق ").removePrefix("برنامج ")
                    .removePrefix("الـ").trim()
                if (launchAppByLabel(appName)) "فتحت " + appName
                else "ما لكيت تطبيق باسم «" + appName + "» بين التطبيقات المثبتة. جرّب اسمه الظاهر بالجهاز."
            }
            else -> "أكدر أنفذ أوامر مباشرة وأفتح التطبيقات المثبتة، وللمهام متعددة الخطوات فعّل خدمة التحكم واربط Gemini AI."
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
    val bg = Color(0xFF050812)
    val panel = Color(0xFF10182A)
    val panel2 = Color(0xFF141F35)
    val cyan = Color(0xFF50F5E1)
    val violet = Color(0xFF9A72FF)
    var input by remember { mutableStateOf("") }
    var listening by remember { mutableStateOf(false) }
    var apiDialog by remember { mutableStateOf(false) }
    var apiKeyInput by remember { mutableStateOf("") }
    var thinking by remember { mutableStateOf(false) }
    var showSettings by remember { mutableStateOf(false) }
    var testStatus by remember { mutableStateOf("جاهز لاستقبال أوامرك") }
    var messages by remember { mutableStateOf(listOf(ChatLine("أهلاً، أني VOID AI. احچيلي شتريد أسوي أو اكتب الأمر. للسيطرة على عناصر التطبيقات فعّل خدمة التحكم من الإعدادات.", false))) }

    fun submit(text: String) {
        if (text.isBlank() || thinking) return
        messages = messages + ChatLine(text, true)
        input = ""
        testStatus = "جاري تنفيذ الأمر..."
        val normalized = text.lowercase(Locale.ROOT)
        val isDesignTask = listOf("صمم فيديو", "صمّم فيديو", "صمملي فيديو", "صمّملي فيديو", "سوي فيديو", "سوّي فيديو", "سويلي فيديو", "سويلي مونتاج", "مونتاج", "منتاج", "عدّل فيديو", "عدل فيديو", "ركب فيديو", "اصنع فيديو", "أنشئ فيديو", "انشئ فيديو", "حرر فيديو", "تعديل الفيديو", "كاب كات", "capcut").any { normalized.contains(it) }
        val response = if (isDesignTask) onCommand("افتح CapCut") else onCommand(text)
        if (response.startsWith("أكدر أنفذ أوامر مباشرة") || isDesignTask) {
            thinking = true
            testStatus = if (isDesignTask) "أفتح CapCut وأبدأ خطوات التصميم..." else "جاري تنفيذ الأمر..."
            if (isDesignTask && !response.startsWith("فتحت")) {
                messages = messages + ChatLine("ما قدرت أفتح CapCut تلقائياً: " + response + " تأكد أنه مثبت على الجهاز.", false)
                thinking = false
                return
            }
            onRunAgent(text) { aiResponse ->
                messages = messages + ChatLine(aiResponse, false)
                thinking = false
                testStatus = "انتهت محاولة التنفيذ"
                onSpeak(aiResponse)
            }
        } else {
            messages = messages + ChatLine(response, false)
            testStatus = "تمت معالجة الأمر"
        }
    }

    MaterialTheme(colorScheme = darkColorScheme(background = bg, surface = panel, primary = cyan, secondary = violet)) {
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Color(0xFF050812), Color(0xFF0B1023), Color(0xFF060915))))) {
            Column(
                Modifier.fillMaxSize().padding(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        Modifier.size(48.dp).shadow(15.dp, RoundedCornerShape(16.dp))
                            .background(Brush.linearGradient(listOf(cyan, violet)), RoundedCornerShape(16.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("V", fontSize = 29.sp, color = bg, fontWeight = FontWeight.Black)
                    }
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text("VOID AI", fontSize = 25.sp, color = Color.White, fontWeight = FontWeight.Black, letterSpacing = 1.6.sp)
                        Text("NEURAL CONTROL  •  الإصدار 1.3", fontSize = 9.sp, color = cyan, letterSpacing = 1.sp)
                    }
                    Surface(color = Color(0xFF12312F), shape = RoundedCornerShape(30.dp), border = androidx.compose.foundation.BorderStroke(1.dp, cyan.copy(alpha = 0.35f))) {
                        Row(Modifier.padding(horizontal = 9.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                            Box(Modifier.size(6.dp).background(if (hasApiKey()) cyan else Color(0xFFFFC66D), RoundedCornerShape(10.dp)))
                            Spacer(Modifier.width(6.dp))
                            Text(if (hasApiKey()) "AI LINKED" else "LOCAL", fontSize = 9.sp, color = if (hasApiKey()) cyan else Color(0xFFFFC66D), fontWeight = FontWeight.Bold)
                        }
                    }
                    IconButton(onClick = { showSettings = !showSettings }) {
                        Text("⋮", color = Color.White, fontSize = 26.sp, fontWeight = FontWeight.Bold)
                    }
                }

                Spacer(Modifier.height(8.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                    StatusPill("الصوت", "جاهز للضغط", cyan, Modifier.weight(1f))
                    StatusPill("الشاشة", if (VoidAccessibilityService.instance != null) "متصلة" else "تحتاج تفعيل", if (VoidAccessibilityService.instance != null) cyan else Color(0xFFFFC66D), Modifier.weight(1.25f))
                    StatusPill("المهام", if (thinking) "قيد التنفيذ" else "متاحة", if (thinking) violet else cyan, Modifier.weight(1f))
                }

                Spacer(Modifier.height(2.dp))
                Box(Modifier.fillMaxWidth().height(215.dp), contentAlignment = Alignment.Center) {
                    OrbitalCore(listening = listening, thinking = thinking, cyan = cyan, violet = violet)
                }
                Text(
                    when {
                        listening -> "أني أسمعك هسه..."
                        thinking -> "أحلّل الأمر وأرتّب الخطوات"
                        else -> "احچي. أني حاضر."
                    },
                    color = Color.White, fontSize = 19.sp, fontWeight = FontWeight.Bold
                )
                Text(
                    when {
                        listening -> "احچي الأمر بوضوح، وبعدين راح أبدأ"
                        thinking -> "قد تتطلب بعض الإجراءات موافقتك داخل التطبيق"
                        else -> testStatus
                    },
                    color = Color(0xFF91A4C2), fontSize = 11.sp, textAlign = TextAlign.Center
                )

                Spacer(Modifier.height(9.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(
                        onClick = {
                            if (!hasApiKey()) {
                                messages = messages + ChatLine("اربط مفتاح Gemini من زر ربط AI أولاً.", false)
                                apiKeyInput = ""
                                apiDialog = true
                            } else {
                                thinking = true
                                testStatus = "أختبر اتصال Gemini..."
                                onAskAI("أجب بكلمة تم فقط. هذا اختبار اتصال Gemini داخل تطبيق VOID AI.") { answer ->
                                    val failed = listOf("Gemini رفض", "تعذر الاتصال", "مفتاح Gemini", "المفتاح أو مشروع", "نموذج Gemini", "تم تجاوز حصة", "طلب Gemini", "اربط Gemini", "HTTP 503", "HTTP 429", "عليه ضغط", "وصل حد الطلبات").any { answer.contains(it, ignoreCase = true) }
                                    val line = if (failed) "فشل اختبار Gemini: " + answer else "نجح الاتصال بـ Gemini. الرد: " + answer
                                    messages = messages + ChatLine(line, false)
                                    thinking = false
                                    testStatus = if (failed) "الاتصال يحتاج مراجعة" else "اتصال Gemini شغّال"
                                }
                            }
                        },
                        modifier = Modifier.weight(1f).height(42.dp),
                        contentPadding = PaddingValues(horizontal = 6.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF153C45), contentColor = cyan)
                    ) { Text("اختبار AI", fontSize = 12.sp, fontWeight = FontWeight.Bold) }
                    OutlinedButton(
                        onClick = { apiKeyInput = ""; apiDialog = true },
                        modifier = Modifier.weight(1f).height(42.dp),
                        contentPadding = PaddingValues(horizontal = 6.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, violet.copy(alpha = 0.75f))
                    ) { Text(if (hasApiKey()) "تغيير مفتاح AI" else "ربط AI", fontSize = 12.sp, color = Color.White) }
                    OutlinedButton(
                        onClick = onAccessibility,
                        modifier = Modifier.weight(1f).height(42.dp),
                        contentPadding = PaddingValues(horizontal = 6.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, cyan.copy(alpha = 0.6f))
                    ) { Text("تحكم الشاشة", fontSize = 12.sp, color = cyan) }
                }

                Spacer(Modifier.height(7.dp))
                Row(
                    Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(7.dp)
                ) {
                    AssistChip(onClick = { submit("افتح يوتيوب") }, label = { Text("▶ يوتيوب", fontSize = 11.sp) })
                    AssistChip(onClick = { submit("افتح واتساب") }, label = { Text("◉ واتساب", fontSize = 11.sp) })
                    AssistChip(onClick = { submit("افتح الكاميرا") }, label = { Text("◎ الكاميرا", fontSize = 11.sp) })
                    AssistChip(onClick = { submit("افتح CapCut") }, label = { Text("✦ CapCut", fontSize = 11.sp) })
                    AssistChip(onClick = { submit("افتح الإعدادات") }, label = { Text("⚙ الإعدادات", fontSize = 11.sp) })
                }

                Spacer(Modifier.height(6.dp))
                Surface(
                    modifier = Modifier.fillMaxWidth().weight(1f).defaultMinSize(minHeight = 110.dp),
                    color = panel.copy(alpha = 0.96f),
                    shape = RoundedCornerShape(22.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF2D3D5B))
                ) {
                    Column(Modifier.fillMaxSize().padding(horizontal = 11.dp, vertical = 9.dp)) {
                        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                            Text("سجل المحادثة", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                            Spacer(Modifier.weight(1f))
                            Text(if (thinking) "● جارٍ العمل" else "● مباشر", color = if (thinking) violet else cyan, fontSize = 10.sp)
                            TextButton(onClick = { messages = listOf(ChatLine("تم مسح سجل المحادثة من الشاشة. هذا لا يمسح سجلات النظام أو التطبيقات الأخرى.", false)) }) {
                                Text("مسح", fontSize = 10.sp, color = Color(0xFF91A4C2))
                            }
                        }
                        HorizontalDivider(color = Color(0xFF26344F))
                        LazyColumn(
                            Modifier.fillMaxSize().padding(top = 8.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            items(messages) { msg ->
                                Row(
                                    Modifier.fillMaxWidth(),
                                    horizontalArrangement = if (msg.fromUser) Arrangement.Start else Arrangement.End
                                ) {
                                    Surface(
                                        color = if (msg.fromUser) Color(0xFF183846) else Color(0xFF1A2237),
                                        shape = RoundedCornerShape(
                                            topStart = 16.dp, topEnd = 16.dp,
                                            bottomStart = if (msg.fromUser) 4.dp else 16.dp,
                                            bottomEnd = if (msg.fromUser) 16.dp else 4.dp
                                        ),
                                        border = androidx.compose.foundation.BorderStroke(1.dp, if (msg.fromUser) cyan.copy(alpha = 0.19f) else violet.copy(alpha = 0.16f)),
                                        modifier = Modifier.widthIn(max = 310.dp)
                                    ) {
                                        Text(msg.text, Modifier.padding(horizontal = 12.dp, vertical = 9.dp), color = Color(0xFFF3F6FF), textAlign = TextAlign.Right, fontSize = 13.sp, lineHeight = 19.sp)
                                    }
                                }
                            }
                            if (thinking) {
                                item { Text("VOID AI يحلّل وينفّذ...", color = cyan, fontSize = 11.sp) }
                            }
                        }
                    }
                }

                Spacer(Modifier.height(8.dp))
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = Color(0xFF111A2D),
                    shape = RoundedCornerShape(20.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, if (listening) cyan else Color(0xFF324260))
                ) {
                    Row(Modifier.padding(horizontal = 7.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.weight(1f).padding(start = 9.dp, end = 6.dp, top = 8.dp, bottom = 8.dp)) {
                            if (input.isEmpty()) Text("اكتب أمرك هنا...", color = Color(0xFF7588A8), fontSize = 13.sp)
                            BasicTextField(
                                value = input,
                                onValueChange = { input = it },
                                modifier = Modifier.fillMaxWidth(),
                                textStyle = androidx.compose.ui.text.TextStyle(color = Color.White, fontSize = 14.sp),
                                cursorBrush = androidx.compose.ui.graphics.SolidColor(cyan),
                                maxLines = 4
                            )
                        }
                        IconButton(
                            onClick = {
                                listening = true
                                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({ listening = false }, 12000L)
                                onListen { spoken ->
                                    listening = false
                                    input = spoken
                                    submit(spoken)
                                }
                            }
                        ) {
                            Icon(Icons.Default.Mic, contentDescription = "تحدث", tint = if (listening) Color(0xFFFF7197) else cyan)
                        }
                        IconButton(onClick = { submit(input) }, enabled = input.isNotBlank() && !thinking) {
                            Icon(Icons.Default.Send, contentDescription = "إرسال", tint = if (input.isNotBlank()) cyan else Color.Gray)
                        }
                    }
                }
                Spacer(Modifier.height(4.dp))
                Text(
                    if (hasApiKey()) "المفتاح محفوظ على الجهاز  •  الأوامر الصوتية تبدأ عند الضغط على المايك" else "اربط Gemini كي تفعّل تخطيط المهام بالذكاء الاصطناعي",
                    Modifier.fillMaxWidth(), color = Color(0xFF657895), fontSize = 9.sp, textAlign = TextAlign.Center
                )
            }

            if (showSettings) {
                Surface(
                    Modifier.align(Alignment.TopEnd).padding(top = 64.dp, end = 6.dp).widthIn(max = 260.dp),
                    color = Color(0xFF18233B), shape = RoundedCornerShape(18.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, cyan.copy(alpha = 0.35f)),
                    shadowElevation = 18.dp
                ) {
                    Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("لوحة النظام", color = cyan, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                        Text("الصوت: " + if (listening) "يستمع" else "جاهز", color = Color.White, fontSize = 12.sp)
                        Text("Gemini: " + if (hasApiKey()) "مربوط" else "غير مربوط", color = Color.White, fontSize = 12.sp)
                        Text("خدمة الشاشة: " + if (VoidAccessibilityService.instance != null) "مفعلة" else "غير مفعلة", color = Color.White, fontSize = 12.sp)
                        TextButton(onClick = { showSettings = false; onAccessibility() }) { Text("إعدادات التحكم") }
                        TextButton(onClick = { showSettings = false; apiKeyInput = ""; apiDialog = true }) { Text("إعدادات الذكاء الاصطناعي") }
                        TextButton(onClick = { showSettings = false }) { Text("إغلاق") }
                    }
                }
            }

            if (apiDialog) {
                AlertDialog(
                    onDismissRequest = { apiDialog = false },
                    title = { Text("ربط VOID AI مع Gemini") },
                    text = {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text("الصق مفتاح API. يُحفظ داخل بيانات التطبيق على هذا الجهاز؛ لا ترسله لأي شخص ولا تضعه في مستودع عام.")
                            OutlinedTextField(
                                value = apiKeyInput, onValueChange = { apiKeyInput = it },
                                label = { Text("Gemini API key") }, singleLine = true,
                                visualTransformation = androidx.compose.ui.text.input.PasswordVisualTransformation()
                            )
                        }
                    },
                    confirmButton = {
                        TextButton(onClick = {
                            if (apiKeyInput.isNotBlank()) {
                                onSaveApiKey(apiKeyInput)
                                apiDialog = false
                                apiKeyInput = ""
                                testStatus = "تم حفظ مفتاح Gemini؛ اختبر الاتصال"
                            }
                        }) { Text("حفظ المفتاح") }
                    },
                    dismissButton = { TextButton(onClick = { apiDialog = false }) { Text("إلغاء") } }
                )
            }
        }
    }
}

@Composable
private fun StatusPill(label: String, value: String, accent: Color, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier,
        color = Color(0xFF0E1728),
        shape = RoundedCornerShape(12.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, accent.copy(alpha = 0.25f))
    ) {
        Column(Modifier.padding(horizontal = 8.dp, vertical = 7.dp)) {
            Text(label, fontSize = 9.sp, color = Color(0xFF8193B2))
            Text(value, fontSize = 10.sp, color = accent, fontWeight = FontWeight.SemiBold, maxLines = 1)
        }
    }
}

@Composable
private fun OrbitalCore(listening: Boolean, thinking: Boolean, cyan: Color, violet: Color) {
    val motion = rememberInfiniteTransition(label = "void-orbit-motion")
    val ringRotation by motion.animateFloat(
        initialValue = 0f, targetValue = 360f,
        animationSpec = infiniteRepeatable(animation = tween(9500, easing = LinearEasing), repeatMode = RepeatMode.Restart),
        label = "ring-rotation"
    )
    val reverseRotation by motion.animateFloat(
        initialValue = 360f, targetValue = 0f,
        animationSpec = infiniteRepeatable(animation = tween(12500, easing = LinearEasing), repeatMode = RepeatMode.Restart),
        label = "reverse-ring-rotation"
    )
    val pulse by motion.animateFloat(
        initialValue = 0.94f, targetValue = 1.04f,
        animationSpec = infiniteRepeatable(animation = tween(if (listening) 700 else 1900, easing = LinearEasing), repeatMode = RepeatMode.Reverse),
        label = "core-pulse"
    )
    Box(Modifier.size(210.dp), contentAlignment = Alignment.Center) {
        Canvas(Modifier.size(206.dp).graphicsLayer { rotationZ = ringRotation }) {
            val c = androidx.compose.ui.geometry.Offset(size.width / 2f, size.height / 2f)
            val r = size.minDimension * 0.44f
            drawCircle(color = cyan.copy(alpha = 0.20f), radius = r, center = c, style = Stroke(width = 1.3.dp.toPx()))
            drawArc(color = cyan.copy(alpha = 0.9f), startAngle = 205f, sweepAngle = 74f, useCenter = false,
                topLeft = androidx.compose.ui.geometry.Offset(c.x - r, c.y - r), size = androidx.compose.ui.geometry.Size(r * 2f, r * 2f),
                style = Stroke(width = 3.dp.toPx(), cap = androidx.compose.ui.graphics.StrokeCap.Round))
            drawArc(color = violet.copy(alpha = 0.9f), startAngle = 15f, sweepAngle = 48f, useCenter = false,
                topLeft = androidx.compose.ui.geometry.Offset(c.x - r, c.y - r), size = androidx.compose.ui.geometry.Size(r * 2f, r * 2f),
                style = Stroke(width = 3.dp.toPx(), cap = androidx.compose.ui.graphics.StrokeCap.Round))
            drawCircle(color = cyan.copy(alpha = 0.95f), radius = 3.8.dp.toPx(), center = androidx.compose.ui.geometry.Offset(c.x + r, c.y))
            drawCircle(color = violet.copy(alpha = 0.95f), radius = 3.5.dp.toPx(), center = androidx.compose.ui.geometry.Offset(c.x - r * 0.74f, c.y - r * 0.68f))
        }
        Canvas(Modifier.size(176.dp).graphicsLayer { rotationZ = reverseRotation }) {
            val c = androidx.compose.ui.geometry.Offset(size.width / 2f, size.height / 2f)
            val rx = size.width * 0.47f
            val ry = size.height * 0.28f
            drawOval(color = violet.copy(alpha = 0.55f), topLeft = androidx.compose.ui.geometry.Offset(c.x - rx, c.y - ry), size = androidx.compose.ui.geometry.Size(rx * 2f, ry * 2f), style = Stroke(width = 1.2.dp.toPx()))
            drawCircle(color = Color.White.copy(alpha = 0.9f), radius = 2.4.dp.toPx(), center = androidx.compose.ui.geometry.Offset(c.x + rx * 0.55f, c.y - ry * 0.83f))
        }
        Box(
            Modifier.size(124.dp).graphicsLayer { scaleX = pulse; scaleY = pulse }
                .shadow(30.dp, RoundedCornerShape(100.dp), clip = false)
                .background(
                    Brush.radialGradient(
                        colors = if (listening) listOf(Color(0xFFECFFFF), Color(0xFF55EDE1), Color(0xFF166D93), Color(0xFF101B45))
                        else listOf(Color(0xFFD5FFFF), Color(0xFF56CDE8), Color(0xFF6154CB), Color(0xFF10162D)),
                        center = androidx.compose.ui.geometry.Offset(36f, 30f),
                        radius = 180f
                    ),
                    RoundedCornerShape(100.dp)
                )
                .border(1.4.dp, Color(0xFFD5FFFF).copy(alpha = 0.85f), RoundedCornerShape(100.dp)),
            contentAlignment = Alignment.Center
        ) {
            Canvas(Modifier.fillMaxSize()) {
                drawCircle(color = Color.White.copy(alpha = 0.38f), radius = size.minDimension * 0.12f, center = androidx.compose.ui.geometry.Offset(size.width * 0.28f, size.height * 0.22f))
                drawCircle(color = Color.White.copy(alpha = 0.12f), radius = size.minDimension * 0.32f, center = androidx.compose.ui.geometry.Offset(size.width * 0.65f, size.height * 0.72f))
            }
            Text(if (thinking) "···" else "V", color = Color.White, fontSize = 53.sp, fontWeight = FontWeight.Black, letterSpacing = (-3).sp)
        }
        if (listening) {
            Surface(
                Modifier.align(Alignment.BottomCenter).padding(bottom = 3.dp),
                color = Color(0xFF38172B), shape = RoundedCornerShape(30.dp),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFFF7197).copy(alpha = 0.8f))
            ) {
                Text("● REC", Modifier.padding(horizontal = 11.dp, vertical = 5.dp), color = Color(0xFFFF9DB8), fontSize = 9.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

