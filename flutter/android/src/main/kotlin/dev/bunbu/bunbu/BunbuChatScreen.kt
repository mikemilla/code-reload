package dev.bunbu.bunbu

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
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch

data class ChatMessage(
    val id: String = java.util.UUID.randomUUID().toString(),
    val isUser: Boolean,
    val text: String
)

data class BunbuPreset(
    val label: String,
    val code: String
)

val bunbuPresets = listOf(
    BunbuPreset(
        label = "Todo List",
        code = """
import 'package:flutter/material.dart';

class Main extends StatefulWidget {
  Main();

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  bool _d0 = false;
  bool _d1 = false;
  bool _d2 = false;
  bool _d3 = false;
  bool _d4 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Tasks'),
        backgroundColor: Color(0xFF6C63FF),
      ),
      body: ListView(
        children: [
          GestureDetector(
            onTap: () { setState(() { _d0 = _d0 == false; }); },
            child: ListTile(
              leading: Icon(_d0 ? Icons.check_circle : Icons.radio_button_unchecked, color: _d0 ? Color(0xFF6C63FF) : Colors.grey),
              title: Text('Buy groceries', style: TextStyle(color: _d0 ? Colors.grey : Colors.black)),
            ),
          ),
          GestureDetector(
            onTap: () { setState(() { _d1 = _d1 == false; }); },
            child: ListTile(
              leading: Icon(_d1 ? Icons.check_circle : Icons.radio_button_unchecked, color: _d1 ? Color(0xFF6C63FF) : Colors.grey),
              title: Text('Walk the dog', style: TextStyle(color: _d1 ? Colors.grey : Colors.black)),
            ),
          ),
          GestureDetector(
            onTap: () { setState(() { _d2 = _d2 == false; }); },
            child: ListTile(
              leading: Icon(_d2 ? Icons.check_circle : Icons.radio_button_unchecked, color: _d2 ? Color(0xFF6C63FF) : Colors.grey),
              title: Text('Read a book', style: TextStyle(color: _d2 ? Colors.grey : Colors.black)),
            ),
          ),
          GestureDetector(
            onTap: () { setState(() { _d3 = _d3 == false; }); },
            child: ListTile(
              leading: Icon(_d3 ? Icons.check_circle : Icons.radio_button_unchecked, color: _d3 ? Color(0xFF6C63FF) : Colors.grey),
              title: Text('Write Flutter code', style: TextStyle(color: _d3 ? Colors.grey : Colors.black)),
            ),
          ),
          GestureDetector(
            onTap: () { setState(() { _d4 = _d4 == false; }); },
            child: ListTile(
              leading: Icon(_d4 ? Icons.check_circle : Icons.radio_button_unchecked, color: _d4 ? Color(0xFF6C63FF) : Colors.grey),
              title: Text('Go to the gym', style: TextStyle(color: _d4 ? Colors.grey : Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}
"""
    ),
    BunbuPreset(
        label = "Profile",
        code = """
import 'package:flutter/material.dart';

class Main extends StatelessWidget {
  Main();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Color(0xFF2196F3),
      ),
      body: ListView(
        children: [
            SizedBox(height: 32),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3),
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
                child: Center(
                  child: Text('JD', style: TextStyle(fontSize: 36, color: Colors.white)),
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(child: Text('Jane Doe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            SizedBox(height: 4),
            Center(child: Text('Flutter Developer', style: TextStyle(fontSize: 16, color: Colors.grey))),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('142', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Posts', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('1.2k', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Followers', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('89', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Following', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Container(height: 1, color: Colors.grey),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.email, color: Color(0xFF2196F3)),
              title: Text('jane.doe@email.com'),
            ),
            ListTile(
              leading: Icon(Icons.location_on, color: Color(0xFF2196F3)),
              title: Text('San Francisco, CA'),
            ),
            ListTile(
              leading: Icon(Icons.web, color: Color(0xFF2196F3)),
              title: Text('github.com/janedoe'),
            ),
          ],
        ),
    );
  }
}
"""
    ),
    BunbuPreset(
        label = "Weather",
        code = """
import 'package:flutter/material.dart';

class Main extends StatelessWidget {
  Main();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather'),
        backgroundColor: Color(0xFF1565C0),
      ),
      body: Container(
        color: Color(0xFF1565C0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Icon(Icons.wb_sunny, size: 80, color: Colors.amber),
            SizedBox(height: 16),
            Text('San Francisco', style: TextStyle(fontSize: 28, color: Colors.white)),
            SizedBox(height: 8),
            Text('72 F', style: TextStyle(fontSize: 64, fontWeight: FontWeight.normal, color: Colors.white)),
            Text('Sunny', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(Icons.water_drop, color: Colors.white),
                      SizedBox(height: 4),
                      Text('45%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Humidity', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.air, color: Colors.white),
                      SizedBox(height: 4),
                      Text('12 mph', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Wind', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.visibility, color: Colors.white),
                      SizedBox(height: 4),
                      Text('10 mi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Visibility', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('Mon', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Icon(Icons.wb_sunny, color: Colors.amber, size: 28),
                      SizedBox(height: 4),
                      Text('74', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Tue', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Icon(Icons.cloud, color: Colors.grey, size: 28),
                      SizedBox(height: 4),
                      Text('68', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Wed', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Icon(Icons.cloud, color: Colors.grey, size: 28),
                      SizedBox(height: 4),
                      Text('65', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Thu', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Icon(Icons.wb_sunny, color: Colors.amber, size: 28),
                      SizedBox(height: 4),
                      Text('71', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Fri', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Icon(Icons.wb_sunny, color: Colors.amber, size: 28),
                      SizedBox(height: 4),
                      Text('75', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
"""
    ),
)

@Composable
fun BunbuChatScreen(
    messages: List<ChatMessage>,
    isStreaming: Boolean,
    onSend: (String) -> Unit,
    onStop: () -> Unit,
    onApplyCode: (String) -> Unit
) {
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()
    var input by remember { mutableStateOf(TextFieldValue("")) }

    LaunchedEffect(messages.size, messages.lastOrNull()?.text) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF1A1A1E))
    ) {
        // Header
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color(0xFF222226))
                .padding(horizontal = 16.dp, vertical = 12.dp)
        ) {
            Text(
                text = "bunbu",
                color = Color.White,
                fontSize = 16.sp,
                fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
            )
        }

        // Preset buttons
        LazyRow(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color(0xFF222226))
                .padding(vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(horizontal = 12.dp)
        ) {
            items(bunbuPresets) { preset ->
                Button(
                    onClick = { onApplyCode(preset.code) },
                    shape = RoundedCornerShape(20.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF6C63FF)),
                    contentPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp)
                ) {
                    Text(
                        text = preset.label,
                        fontSize = 13.sp,
                        color = Color.White
                    )
                }
            }
            item {
                Button(
                    onClick = { onApplyCode("") },
                    shape = RoundedCornerShape(20.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF3A3A3E)),
                    contentPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp)
                ) {
                    Text(
                        text = "Reset",
                        fontSize = 13.sp,
                        color = Color.White
                    )
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
                color = if (message.text.isEmpty()) Color.Gray else Color.White,
                fontSize = 14.sp,
                lineHeight = 20.sp
            )
        }

        if (!message.isUser) Spacer(Modifier.weight(0.2f))
    }
}
