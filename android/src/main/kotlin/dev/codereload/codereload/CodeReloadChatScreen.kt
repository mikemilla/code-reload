package dev.codereload.codereload

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

data class ChatMessage(
    val id: String = java.util.UUID.randomUUID().toString(),
    val isUser: Boolean,
    val text: String
)

@Composable
fun CodeReloadChatScreen(
    messages: List<ChatMessage>,
    isStreaming: Boolean,
    onSend: (String) -> Unit,
    onStop: () -> Unit,
    onApplyCode: (String) -> Unit
) {
    val listState = rememberLazyListState()
    var input by remember { mutableStateOf(TextFieldValue("")) }

    LaunchedEffect(messages.size, messages.lastOrNull()?.text) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF1A1A2E))
    ) {
        // Preset buttons
        LazyRow(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color(0xFF222226))
                .padding(vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(horizontal = 12.dp)
        ) {
            items(codereloadPresets) { preset ->
                Button(
                    onClick = { onApplyCode(preset.code) },
                    shape = RoundedCornerShape(20.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF6C63FF)),
                    contentPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp)
                ) {
                    Text(text = preset.label, fontSize = 13.sp, color = Color.White)
                }
            }
            item {
                Button(
                    onClick = { onApplyCode("") },
                    shape = RoundedCornerShape(20.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF3A3A3E)),
                    contentPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp)
                ) {
                    Text(text = "Reset", fontSize = 13.sp, color = Color.White)
                }
            }
        }

        // Messages
        LazyColumn(
            state = listState,
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(messages, key = { it.id }) { message ->
                ChatBubble(message)
            }
        }

        // Composer
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color(0xFF222226))
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            TextField(
                value = input,
                onValueChange = { input = it },
                modifier = Modifier.weight(1f),
                placeholder = { Text("Build me a...", color = Color(0xFF666666)) },
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = Color(0xFF2A2A2E),
                    unfocusedContainerColor = Color(0xFF2A2A2E),
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent
                ),
                shape = RoundedCornerShape(10.dp),
                singleLine = false,
                maxLines = 4
            )

            Spacer(Modifier.width(8.dp))

            IconButton(
                onClick = {
                    if (isStreaming) {
                        onStop()
                    } else {
                        val text = input.text.trim()
                        if (text.isNotEmpty()) {
                            input = TextFieldValue("")
                            onSend(text)
                        }
                    }
                },
                modifier = Modifier
                    .size(34.dp)
                    .background(
                        if (isStreaming) Color(0xFFCC3333) else Color(0xFF6C63FF),
                        CircleShape
                    ),
                enabled = isStreaming || input.text.trim().isNotEmpty()
            ) {
                Text(
                    text = if (isStreaming) "■" else "↑",
                    color = Color.White,
                    fontSize = if (isStreaming) 12.sp else 16.sp
                )
            }
        }
    }
}

@Composable
private fun ChatBubble(message: ChatMessage) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (message.isUser) Arrangement.End else Arrangement.Start
    ) {
        if (message.isUser) Spacer(Modifier.weight(0.2f))

        Box(
            modifier = Modifier
                .background(
                    if (message.isUser) Color(0xFF6C63FF) else Color(0xFF2A2A2E),
                    RoundedCornerShape(16.dp)
                )
                .padding(horizontal = 12.dp, vertical = 8.dp)
                .weight(0.8f, fill = false)
        ) {
            Text(
                text = if (message.text.isEmpty() && !message.isUser) "..." else message.text,
                color = if (message.text.isEmpty()) CodeReloadColors.TextMuted else Color.White,
                fontSize = 14.sp,
                lineHeight = 20.sp
            )
        }

        if (!message.isUser) Spacer(Modifier.weight(0.2f))
    }
}
