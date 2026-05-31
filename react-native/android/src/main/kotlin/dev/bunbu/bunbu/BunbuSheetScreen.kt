package dev.bunbu.bunbu

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

enum class BunbuTab { FILES, CHAT }

@Composable
fun BunbuSheetScreen(
    messages: List<ChatMessage>,
    isStreaming: Boolean,
    fileList: List<String>,
    editedFiles: Set<String>,
    openFilePath: String?,
    openFileContent: String,
    openFileIsEdited: Boolean,
    onSend: (String) -> Unit,
    onStop: () -> Unit,
    onApplyCode: (String) -> Unit,
    onOpenFile: (String) -> Unit,
    onApplyFile: (String, String) -> Unit,
    onResetFile: (String) -> Unit,
    onCloseFile: () -> Unit,
    onDismissSheet: () -> Unit
) {
    var tab by remember { mutableStateOf(BunbuTab.FILES) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF1A1A2E))
    ) {
        // Header
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Bunbu",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                TextButton(onClick = onDismissSheet) {
                    Text("Close", color = Color(0xFF6C63FF), fontWeight = FontWeight.SemiBold)
                }
            }

            Spacer(Modifier.height(12.dp))

            // Tab selector
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFF2A2A3E), RoundedCornerShape(10.dp))
                    .padding(3.dp)
            ) {
                BunbuTab.values().forEach { t ->
                    val selected = tab == t
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .background(
                                if (selected) Color(0xFF6C63FF) else Color.Transparent,
                                RoundedCornerShape(8.dp)
                            )
                            .padding(vertical = 8.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        TextButton(onClick = { tab = t }) {
                            Text(
                                text = if (t == BunbuTab.FILES) "Files" else "Chat",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = if (selected) Color.White else Color(0xFF888888)
                            )
                        }
                    }
                }
            }
        }

        when (tab) {
            BunbuTab.FILES -> BunbuFileBrowserScreen(
                fileList = fileList,
                editedFiles = editedFiles,
                openFilePath = openFilePath,
                openFileContent = openFileContent,
                openFileIsEdited = openFileIsEdited,
                onOpenFile = onOpenFile,
                onApplyFile = onApplyFile,
                onResetFile = onResetFile,
                onCloseFile = onCloseFile
            )
            BunbuTab.CHAT -> BunbuChatScreen(
                messages = messages,
                isStreaming = isStreaming,
                onSend = onSend,
                onStop = onStop,
                onApplyCode = onApplyCode
            )
        }
    }
}
