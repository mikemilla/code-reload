package dev.bunbu.bunbu

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun BunbuFileBrowserScreen(
    fileList: List<String>,
    editedFiles: Set<String>,
    openFilePath: String?,
    openFileContent: String,
    openFileIsEdited: Boolean,
    onOpenFile: (String) -> Unit,
    onApplyFile: (String, String) -> Unit,
    onResetFile: (String) -> Unit,
    onCloseFile: () -> Unit
) {
    if (openFilePath != null) {
        BunbuCodeEditorScreen(
            path = openFilePath,
            content = openFileContent,
            isEdited = openFileIsEdited,
            onApply = { content -> onApplyFile(openFilePath, content) },
            onReset = { onResetFile(openFilePath) },
            onBack = onCloseFile
        )
    } else {
        FileList(
            files = fileList,
            editedFiles = editedFiles,
            onSelect = onOpenFile
        )
    }
}

@Composable
private fun FileList(
    files: List<String>,
    editedFiles: Set<String>,
    onSelect: (String) -> Unit
) {
    LazyColumn(
        contentPadding = PaddingValues(12.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        items(files) { path ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFF2A2A3E), RoundedCornerShape(10.dp))
                    .clickable { onSelect(path) }
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("📄", fontSize = 18.sp)
                Spacer(Modifier.width(10.dp))
                Text(
                    text = path,
                    fontSize = 14.sp,
                    fontFamily = FontFamily.Monospace,
                    color = Color(0xFFE0E0E0),
                    modifier = Modifier.weight(1f)
                )
                if (editedFiles.contains(path)) {
                    Spacer(Modifier.width(8.dp))
                    Text(
                        "edited",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFF6C63FF)
                    )
                }
                Spacer(Modifier.width(4.dp))
                Text("›", fontSize = 20.sp, color = Color(0xFF555555))
            }
        }
    }
}

@Composable
private fun BunbuCodeEditorScreen(
    path: String,
    content: String,
    isEdited: Boolean,
    onApply: (String) -> Unit,
    onReset: () -> Unit,
    onBack: () -> Unit
) {
    var editedContent by remember(path) { mutableStateOf(content) }
    var hasLocalChanges by remember(path) { mutableStateOf(false) }

    LaunchedEffect(content) {
        if (!hasLocalChanges) {
            editedContent = content
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF1A1A2E))
    ) {
        // Toolbar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            TextButton(onClick = onBack) {
                Text("‹ Back", color = Color(0xFF6C63FF), fontWeight = FontWeight.SemiBold)
            }
            Text(
                text = path,
                fontSize = 13.sp,
                fontFamily = FontFamily.Monospace,
                color = Color(0xFF888888),
                modifier = Modifier.weight(1f),
                maxLines = 1
            )
            if (isEdited) {
                TextButton(onClick = {
                    onReset()
                    hasLocalChanges = false
                }) {
                    Text(
                        "Reset",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFFFF6B6B)
                    )
                }
            }
        }

        Divider(color = Color(0xFF2A2A3E))

        // Editor area
        Row(
            modifier = Modifier
                .weight(1f)
                .horizontalScroll(rememberScrollState())
                .verticalScroll(rememberScrollState())
                .padding(vertical = 8.dp)
        ) {
            val lines = editedContent.split("\n")
            Column(
                modifier = Modifier.padding(horizontal = 8.dp),
                horizontalAlignment = Alignment.End
            ) {
                lines.forEachIndexed { index, _ ->
                    Text(
                        text = "${index + 1}",
                        fontSize = 13.sp,
                        fontFamily = FontFamily.Monospace,
                        color = Color(0xFF555555),
                        lineHeight = 20.sp
                    )
                }
            }

            TextField(
                value = editedContent,
                onValueChange = {
                    editedContent = it
                    hasLocalChanges = (it != content)
                },
                modifier = Modifier.widthIn(min = 600.dp),
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = Color.Transparent,
                    unfocusedContainerColor = Color.Transparent,
                    focusedTextColor = Color(0xFFE0E0E0),
                    unfocusedTextColor = Color(0xFFE0E0E0),
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent
                ),
                textStyle = LocalTextStyle.current.copy(
                    fontSize = 13.sp,
                    fontFamily = FontFamily.Monospace,
                    lineHeight = 20.sp
                )
            )
        }

        Divider(color = Color(0xFF2A2A3E))

        // Apply button
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp)
                .padding(bottom = 18.dp)
        ) {
            Button(
                onClick = {
                    onApply(editedContent)
                    hasLocalChanges = false
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = hasLocalChanges,
                shape = RoundedCornerShape(10.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF6C63FF),
                    disabledContainerColor = Color(0xFF6C63FF).copy(alpha = 0.4f)
                )
            ) {
                Text(
                    "Apply",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(vertical = 6.dp)
                )
            }
        }
    }
}
