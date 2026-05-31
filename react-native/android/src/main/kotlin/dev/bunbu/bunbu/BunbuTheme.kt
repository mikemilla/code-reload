package dev.bunbu.bunbu

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

object BunbuColors {
    val Background = Color(0xFF1A1A2E)
    val Surface = Color(0xFF2A2A3E)
    val SurfaceElevated = Color(0xFF222226)
    val Border = Color(0xFF3A3A3E)
    val Accent = Color(0xFF6C63FF)
    val TextPrimary = Color(0xFFE0E0E0)
    val TextSecondary = Color(0xFF888888)
    val TextMuted = Color(0xFF666666)
    val TextDisabled = Color(0xFF555555)
}

private val BunbuDarkColorScheme = darkColorScheme(
    primary = BunbuColors.Accent,
    background = BunbuColors.Background,
    surface = BunbuColors.Surface,
    onPrimary = Color.White,
    onBackground = BunbuColors.TextPrimary,
    onSurface = BunbuColors.TextPrimary,
    outline = BunbuColors.Border,
)

@Composable
fun BunbuTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = BunbuDarkColorScheme,
        content = content,
    )
}
