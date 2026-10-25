package com.voidai.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.os.Bundle

class VoidAccessibilityService : AccessibilityService() {
    companion object { @Volatile var instance: VoidAccessibilityService? = null }
    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        serviceInfo = serviceInfo.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
    }
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}
    override fun onDestroy() { if (instance === this) instance = null; super.onDestroy() }

    fun visibleText(): String {
        val root = rootInActiveWindow ?: return "ماكو شاشة قابلة للقراءة حالياً"
        val out = StringBuilder()
        var count = 0
        fun walk(node: AccessibilityNodeInfo, depth: Int) {
            if (count >= 100 || out.length >= 6000 || depth > 18) return
            val text = node.text?.toString()?.trim().orEmpty()
            val desc = node.contentDescription?.toString()?.trim().orEmpty()
            if (text.isNotBlank() || desc.isNotBlank()) {
                val label = (if (text.isNotBlank()) text else desc).replace("\n", " ")
                out.append("- ").append(label.take(180))
                    .append(" [clickable=").append(node.isClickable)
                    .append(", editable=").append(node.isEditable)
                    .append(", password=").append(node.isPassword)
                    .append(", scrollable=").append(node.isScrollable).append("]\n")
                count++
            }
            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                walk(child, depth + 1)
                if (count >= 100 || out.length >= 6000) break
            }
        }
        walk(root, 0)
        return if (out.isBlank()) "الشاشة الحالية لا تعرض نصوصاً يمكن قراءتها." else out.toString()
    }

    fun clickText(text: String): Boolean {
        if (text.isBlank()) return false
        val root = rootInActiveWindow ?: return false
        val wanted = normalizeLabel(text)
        val candidates = mutableListOf<AccessibilityNodeInfo>()
        fun walk(node: AccessibilityNodeInfo, depth: Int) {
            if (depth > 20 || candidates.size > 350) return
            val label = normalizeLabel(
                listOfNotNull(node.text?.toString(), node.contentDescription?.toString())
                    .joinToString(" ")
            )
            if (label.isNotBlank() && (label == wanted || label.contains(wanted) || wanted.contains(label) && label.length >= 3)) {
                candidates.add(node)
            }
            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                walk(child, depth + 1)
            }
        }
        walk(root, 0)
        for (node in candidates) {
            var target: AccessibilityNodeInfo? = node
            while (target != null && !target.isClickable) target = target.parent
            if (target?.performAction(AccessibilityNodeInfo.ACTION_CLICK) == true) return true
        }
        return false
    }

    private fun normalizeLabel(value: String): String = value
        .lowercase(java.util.Locale.ROOT)
        .replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
        .replace("ى", "ي").replace("ة", "ه")
        .replace(Regex("[\\s\\p{Punct}،؛:!؟]+"), "")

    fun clickSkipAdIfVisible(): Boolean {
        val root = rootInActiveWindow ?: return false
        val adLabels = listOf(
            "تخطي الإعلان", "تخطي الاعلان", "تخطي الإعلانات", "تخطي الاعلانات",
            "skip ad", "skip ads", "close ad", "close advertisement",
            "إغلاق الإعلان", "اغلاق الإعلان", "إغلاق الاعلان", "اغلاق الاعلان"
        )
        val matches = mutableListOf<AccessibilityNodeInfo>()
        fun walk(node: AccessibilityNodeInfo, depth: Int) {
            if (depth > 20 || matches.size > 250) return
            val label = listOfNotNull(node.text?.toString(), node.contentDescription?.toString())
                .joinToString(" ").lowercase(java.util.Locale.ROOT)
                .replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
            if (adLabels.any { label.contains(it.lowercase(java.util.Locale.ROOT)) }) matches.add(node)
            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                walk(child, depth + 1)
            }
        }
        walk(root, 0)
        for (node in matches) {
            var target: AccessibilityNodeInfo? = node
            while (target != null && !target.isClickable) target = target.parent
            if (target?.performAction(AccessibilityNodeInfo.ACTION_CLICK) == true) return true
        }
        return false
    }

    fun setFocusedText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val node = findFocused(root) ?: return false
        if (node.isPassword || !node.isEditable || text.length > 12000) return false
        val args = Bundle().apply { putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text) }
        return node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }
    private fun findFocused(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isFocused && node.isEditable) return node
        for (i in 0 until node.childCount) {
            val found = node.getChild(i)?.let { findFocused(it) }
            if (found != null) return found
        }
        return null
    }
    fun scroll(up: Boolean): Boolean {
        val root = rootInActiveWindow ?: return false
        return scrollNode(root, up)
    }
    private fun scrollNode(node: AccessibilityNodeInfo, up: Boolean): Boolean {
        if (node.isScrollable && node.performAction(if (up) AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD else AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)) return true
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            if (scrollNode(child, up)) return true
        }
        return false
    }
}