package com.nothflows

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.util.Log

class NothFlowsAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "NothFlowsA11y"
        private var instance: NothFlowsAccessibilityService? = null
        private var isServiceEnabled = false

        fun getInstance(): NothFlowsAccessibilityService? = instance
        
        fun isEnabled(): Boolean = isServiceEnabled && instance != null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        isServiceEnabled = true
        
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or 
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
        
        serviceInfo = info
        Log.d(TAG, "Accessibility Service connected and ready")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Log events for debugging
        event?.let {
            Log.d(TAG, "Event: ${it.eventType}, Package: ${it.packageName}")
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        isServiceEnabled = false
        Log.d(TAG, "Service destroyed")
    }

    fun readCurrentScreen(): String {
        val rootNode = rootInActiveWindow ?: return "Unable to access screen content"
        
        val contentBuilder = StringBuilder()
        extractTextFromNode(rootNode, contentBuilder)
        rootNode.recycle()
        
        return contentBuilder.toString().trim()
    }

    private fun extractTextFromNode(node: AccessibilityNodeInfo, builder: StringBuilder) {
        // Get text from this node
        node.text?.let { 
            if (it.isNotBlank()) {
                builder.append(it).append(". ")
            }
        }
        
        // Get content description
        node.contentDescription?.let {
            if (it.isNotBlank()) {
                builder.append(it).append(". ")
            }
        }
        
        // Recursively get text from children
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                extractTextFromNode(child, builder)
                child.recycle()
            }
        }
    }
}
