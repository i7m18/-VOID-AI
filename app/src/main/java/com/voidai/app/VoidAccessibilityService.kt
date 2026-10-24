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

    fun clickText(text: String): Boolean {
        if (text.isBlank()) return false
        val roots = listOfNotNull(rootInActiveWindow)
        for (root in roots) {
            val nodes = root.findAccessibilityNodeInfosByText(text)
            for (node in nodes) {
                var target: AccessibilityNodeInfo? = node
                while (target != null && !target.isClickable) target = target.parent
                if (target?.performAction(AccessibilityNodeInfo.ACTION_CLICK) == true) return true
            }
        }
        return false
    }
    fun setFocusedText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val node = findFocused(root) ?: return false
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
        if (node.isScrollable) return node.performAction(if (up) AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD else AccessibilityNodeInfo.ACTION_SCROLL_FORWARD)
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            if (scrollNode(child, up)) return true
        }
        return false
    }
}