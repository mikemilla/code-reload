package dev.bunbu.bunbu

import android.app.Activity
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.platform.ComposeView
import androidx.fragment.app.FragmentActivity
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class BunbuPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var fabView: BunbuFABView? = null
    private var sheetFragment: BunbuSheetFragment? = null

    private val messages = mutableStateListOf<ChatMessage>()
    private val isStreaming = mutableStateOf(false)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "bunbu/agent_manager")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                setupFAB()
                result.success(null)
            }
            "show" -> showSheet(result)
            "hide" -> hideSheet(result)
            "onStreamChunk" -> {
                val chunk = call.arguments as? String ?: ""
                handleStreamChunk(chunk)
                result.success(null)
            }
            "onStreamDone" -> {
                isStreaming.value = false
                result.success(null)
            }
            "onStreamError" -> {
                val error = call.arguments as? String ?: "Unknown error"
                handleStreamError(error)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleStreamChunk(chunk: String) {
        if (messages.isNotEmpty() && !messages.last().isUser) {
            val last = messages.last()
            messages[messages.size - 1] = last.copy(text = last.text + chunk)
        }
    }

    private fun handleStreamError(error: String) {
        isStreaming.value = false
        if (messages.isNotEmpty() && !messages.last().isUser) {
            val last = messages.last()
            messages[messages.size - 1] = last.copy(text = "Error: $error")
        }
    }

    private fun setupFAB() {
        val act = activity ?: return
        if (fabView != null) return
        act.runOnUiThread {
            fabView = BunbuFABView(act) { showSheet(object : Result {
                override fun success(r: Any?) {}
                override fun error(code: String, msg: String?, details: Any?) {}
                override fun notImplemented() {}
            }) }
            fabView?.show()
        }
    }

    private fun showSheet(result: Result) {
        val fragmentActivity = activity as? FragmentActivity
        if (fragmentActivity == null) {
            result.error("NO_ACTIVITY", "No FragmentActivity available", null)
            return
        }

        val fragment = BunbuSheetFragment(
            messages = messages,
            isStreaming = isStreaming,
            onSend = { text ->
                messages.add(ChatMessage(isUser = true, text = text))
                messages.add(ChatMessage(isUser = false, text = ""))
                isStreaming.value = true
                channel.invokeMethod("sendMessage", text)
            },
            onStop = {
                channel.invokeMethod("stopGeneration", null)
            },
            onDismiss = {
                channel.invokeMethod("onDismiss", null)
            }
        )
        fragment.show(fragmentActivity.supportFragmentManager, "bunbu_sheet")
        sheetFragment = fragment
        result.success(null)
    }

    private fun hideSheet(result: Result) {
        sheetFragment?.dismiss()
        sheetFragment = null
        result.success(null)
    }

    // ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        fabView?.remove()
        fabView = null
        activity = null
    }
}

class BunbuSheetFragment(
    private val messages: List<ChatMessage>,
    private val isStreaming: androidx.compose.runtime.MutableState<Boolean>,
    private val onSend: (String) -> Unit,
    private val onStop: () -> Unit,
    private val onDismiss: () -> Unit
) : BottomSheetDialogFragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return ComposeView(requireContext()).apply {
            setContent {
                BunbuChatScreen(
                    messages = messages,
                    isStreaming = isStreaming.value,
                    onSend = onSend,
                    onStop = onStop
                )
            }
        }
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        (dialog as? BottomSheetDialog)?.behavior?.apply {
            state = BottomSheetBehavior.STATE_EXPANDED
            skipCollapsed = true
            isDraggable = true
            isFitToContents = false
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        onDismiss()
    }
}
