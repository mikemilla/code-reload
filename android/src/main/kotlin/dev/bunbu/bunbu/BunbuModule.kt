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
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.bottomsheet.BottomSheetDialogFragment

class BunbuModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName() = "BunbuModule"

    private var fabView: BunbuFABView? = null
    private var sheetFragment: BunbuSheetFragment? = null

    private val messages = mutableStateListOf<ChatMessage>()
    private val isStreaming = mutableStateOf(false)
    private val fileList = mutableStateOf<List<String>>(emptyList())
    private val editedFiles = mutableStateOf<Set<String>>(emptySet())
    private val openFilePath = mutableStateOf<String?>(null)
    private val openFileContent = mutableStateOf("")
    private val openFileIsEdited = mutableStateOf(false)

    private fun emit(type: String, payload: Any? = null) {
        val data = Arguments.createMap().apply {
            putString("type", type)
            when (payload) {
                is String -> putString("payload", payload)
                is WritableMap -> putMap("payload", payload)
                null -> {}
                else -> putString("payload", payload.toString())
            }
        }
        reactApplicationContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit("BunbuEvent", data)
    }

    @ReactMethod
    fun initialize() {
        val act = currentActivity ?: return
        if (fabView != null) return
        act.runOnUiThread {
            fabView = BunbuFABView(act) {
                showSheet()
            }
            fabView?.show()
        }
    }

    @ReactMethod
    fun showSheet() {
        val fragmentActivity = currentActivity as? FragmentActivity ?: return
        fragmentActivity.runOnUiThread {
            val fragment = BunbuSheetFragment(
                messages = messages,
                isStreaming = isStreaming,
                fileList = fileList,
                editedFiles = editedFiles,
                openFilePath = openFilePath,
                openFileContent = openFileContent,
                openFileIsEdited = openFileIsEdited,
                onSend = { text ->
                    messages.add(ChatMessage(isUser = true, text = text))
                    messages.add(ChatMessage(isUser = false, text = ""))
                    isStreaming.value = true
                    emit("sendMessage", text)
                },
                onStop = {
                    emit("stopGeneration")
                },
                onApplyCode = { code ->
                    emit("applyCode", code)
                },
                onOpenFile = { path ->
                    emit("openFile", path)
                },
                onApplyFile = { path, content ->
                    val payload = Arguments.createMap().apply {
                        putString("path", path)
                        putString("content", content)
                    }
                    emit("applyFile", payload)
                },
                onResetFile = { path ->
                    emit("resetFile", path)
                },
                onDismiss = {
                    emit("onDismiss")
                }
            )
            fragment.show(fragmentActivity.supportFragmentManager, "bunbu_sheet")
            sheetFragment = fragment
        }
    }

    @ReactMethod
    fun hideSheet() {
        currentActivity?.runOnUiThread {
            sheetFragment?.dismiss()
            sheetFragment = null
        }
    }

    @ReactMethod
    fun onStreamChunk(chunk: String) {
        if (messages.isNotEmpty() && !messages.last().isUser) {
            val last = messages.last()
            messages[messages.size - 1] = last.copy(text = last.text + chunk)
        }
    }

    @ReactMethod
    fun onStreamDone() {
        isStreaming.value = false
    }

    @ReactMethod
    fun onStreamError(error: String) {
        isStreaming.value = false
        if (messages.isNotEmpty() && !messages.last().isUser) {
            val last = messages.last()
            messages[messages.size - 1] = last.copy(text = "Error: $error")
        }
    }

    @ReactMethod
    fun setFiles(files: ReadableArray) {
        val list = mutableListOf<String>()
        for (i in 0 until files.size()) {
            files.getString(i)?.let { list.add(it) }
        }
        fileList.value = list
    }

    @ReactMethod
    fun setFileContent(path: String, content: String, isEdited: Boolean) {
        openFilePath.value = path
        openFileContent.value = content
        openFileIsEdited.value = isEdited
    }

    @ReactMethod
    fun addListener(eventName: String) {}

    @ReactMethod
    fun removeListeners(count: Int) {}
}

class BunbuSheetFragment(
    private val messages: List<ChatMessage>,
    private val isStreaming: androidx.compose.runtime.MutableState<Boolean>,
    private val fileList: androidx.compose.runtime.MutableState<List<String>>,
    private val editedFiles: androidx.compose.runtime.MutableState<Set<String>>,
    private val openFilePath: androidx.compose.runtime.MutableState<String?>,
    private val openFileContent: androidx.compose.runtime.MutableState<String>,
    private val openFileIsEdited: androidx.compose.runtime.MutableState<Boolean>,
    private val onSend: (String) -> Unit,
    private val onStop: () -> Unit,
    private val onApplyCode: (String) -> Unit,
    private val onOpenFile: (String) -> Unit,
    private val onApplyFile: (String, String) -> Unit,
    private val onResetFile: (String) -> Unit,
    private val onDismiss: () -> Unit
) : BottomSheetDialogFragment() {

    override fun getTheme(): Int = com.google.android.material.R.style.ThemeOverlay_Material3_Dark

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return ComposeView(requireContext()).apply {
            setContent {
                BunbuTheme {
                    BunbuSheetScreen(
                        messages = messages,
                        isStreaming = isStreaming.value,
                        fileList = fileList.value,
                        editedFiles = editedFiles.value,
                        openFilePath = openFilePath.value,
                        openFileContent = openFileContent.value,
                        openFileIsEdited = openFileIsEdited.value,
                        onSend = onSend,
                        onStop = onStop,
                        onApplyCode = onApplyCode,
                        onOpenFile = onOpenFile,
                        onApplyFile = onApplyFile,
                        onResetFile = onResetFile,
                        onCloseFile = { openFilePath.value = null },
                        onDismissSheet = { dismiss() }
                    )
                }
            }
        }
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        (dialog as? BottomSheetDialog)?.setOnShowListener {
            val bottomSheet = (it as BottomSheetDialog)
                .findViewById<View>(com.google.android.material.R.id.design_bottom_sheet)
            bottomSheet?.setBackgroundColor(android.graphics.Color.parseColor("#1A1A2E"))
        }
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
