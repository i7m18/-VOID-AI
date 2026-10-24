package com.voidai.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private data class ChatLine(val text: String, val fromUser: Boolean)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { VoidAiApp() }
    }
}

@Composable
private fun VoidAiApp() {
    val bg = Color(0xFF080B12)
    val panel = Color(0xFF131A27)
    val cyan = Color(0xFF47E6D2)
    var input by remember { mutableStateOf("") }
    var messages by remember {
        mutableStateOf(listOf(ChatLine("أهلاً بيك، أني VOID AI. هذه واجهة أولية؛ لم يتم ربط محرك ذكاء اصطناعي بعد.", false)))
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
                    Text("مساعدك الذكي", fontSize = 13.sp, color = cyan)
                }
            }
            Spacer(Modifier.height(18.dp))
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
            Row(Modifier.fillMaxWidth().background(panel, RoundedCornerShape(18.dp)).padding(10.dp), verticalAlignment = Alignment.CenterVertically) {
                BasicTextField(value = input, onValueChange = { input = it }, modifier = Modifier.weight(1f).padding(horizontal = 8.dp, vertical = 12.dp), textStyle = androidx.compose.ui.text.TextStyle(color = Color.White, fontSize = 15.sp), cursorBrush = androidx.compose.ui.graphics.SolidColor(cyan), decorationBox = { inner ->
                    Box { if (input.isEmpty()) Text("اكتب رسالتك هنا...", color = Color.Gray); inner() }
                })
                IconButton(onClick = {
                    val text = input.trim()
                    if (text.isNotEmpty()) {
                        messages = messages + ChatLine(text, true) + ChatLine("وصلت رسالتك. هذه نسخة واجهة أولية وليست متصلة بخدمة AI.", false)
                        input = ""
                    }
                }) { Icon(Icons.Default.Send, contentDescription = "إرسال", tint = cyan) }
            }
            Spacer(Modifier.height(6.dp))
            Text("نسخة أولية • VOID AI", Modifier.fillMaxWidth(), color = Color.Gray, fontSize = 11.sp, textAlign = TextAlign.Center)
        }
    }
}
