package dev.codereload.codereload

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import kotlin.math.roundToInt

@SuppressLint("ClickableViewAccessibility")
class CodeReloadFABView(
    private val activity: Activity,
    private val onTap: () -> Unit
) {
    companion object {
        private const val PREFS_NAME = "codereload"
        private const val POSITION_X_KEY = "fab.position.x"
        private const val POSITION_Y_KEY = "fab.position.y"
    }

    private var fabView: View? = null
    private var initialX = 0f
    private var initialY = 0f
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var hasMoved = false

    fun show() {
        if (fabView != null) {
            fabView?.visibility = View.VISIBLE
            return
        }

        val size = (56 * activity.resources.displayMetrics.density).roundToInt()
        val margin = (16 * activity.resources.displayMetrics.density).roundToInt()

        val button = FrameLayout(activity).apply {
            val gradient = GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                intArrayOf(Color.parseColor("#6C63FF"), Color.parseColor("#9B59B6"))
            )
            gradient.cornerRadius = size / 2f
            background = gradient
            elevation = 16f

            val icon = ImageView(activity).apply {
                setImageResource(android.R.drawable.btn_star_big_on)
                setColorFilter(Color.WHITE)
                val iconSize = (24 * activity.resources.displayMetrics.density).roundToInt()
                layoutParams = FrameLayout.LayoutParams(iconSize, iconSize, Gravity.CENTER)
            }
            addView(icon)
        }

        val params = FrameLayout.LayoutParams(size, size).apply {
            gravity = Gravity.BOTTOM or Gravity.END
            setMargins(margin, margin, margin, margin + (64 * activity.resources.displayMetrics.density).roundToInt())
        }

        button.setOnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = view.x
                    initialY = view.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    hasMoved = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - initialTouchX
                    val dy = event.rawY - initialTouchY
                    if (dx * dx + dy * dy > 100) hasMoved = true
                    view.x = initialX + dx
                    view.y = initialY + dy
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (hasMoved) {
                        savePosition(view)
                    } else {
                        onTap()
                    }
                    true
                }
                else -> false
            }
        }

        val decorView = activity.window.decorView as ViewGroup
        val contentView = decorView.findViewById<ViewGroup>(android.R.id.content)
        contentView.addView(button, params)
        button.post { restorePosition(button, size, contentView) }
        fabView = button
    }

    private fun restorePosition(view: View, size: Int, parent: ViewGroup) {
        val prefs = activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (!prefs.contains(POSITION_X_KEY)) return

        val maxX = (parent.width - size).coerceAtLeast(0).toFloat()
        val maxY = (parent.height - size).coerceAtLeast(0).toFloat()
        view.x = prefs.getFloat(POSITION_X_KEY, 0f).coerceIn(0f, maxX)
        view.y = prefs.getFloat(POSITION_Y_KEY, 0f).coerceIn(0f, maxY)
    }

    private fun savePosition(view: View) {
        activity.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putFloat(POSITION_X_KEY, view.x)
            .putFloat(POSITION_Y_KEY, view.y)
            .apply()
    }

    fun hide() {
        fabView?.visibility = View.GONE
    }

    fun remove() {
        fabView?.let { view ->
            (view.parent as? ViewGroup)?.removeView(view)
        }
        fabView = null
    }
}
