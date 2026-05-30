package dev.bunbu.bunbu

import android.annotation.SuppressLint
import android.app.Activity
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
class BunbuFABView(
    private val activity: Activity,
    private val onTap: () -> Unit
) {
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
                    if (!hasMoved) onTap()
                    true
                }
                else -> false
            }
        }

        val decorView = activity.window.decorView as ViewGroup
        val contentView = decorView.findViewById<ViewGroup>(android.R.id.content)
        contentView.addView(button, params)
        fabView = button
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
