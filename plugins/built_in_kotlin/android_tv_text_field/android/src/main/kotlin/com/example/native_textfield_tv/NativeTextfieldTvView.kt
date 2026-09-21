package com.example.native_textfield_tv
import android.util.Log

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.util.TypedValue
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.EditText
import android.widget.TextView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class NativeTextfieldTvView(
    private val context: Context,
    private val viewId: Int,
    private val creationParams: Map<String?, Any?>?,
    private val messenger: BinaryMessenger
) : PlatformView {

    private val editText: EditText
    private val methodChannel: MethodChannel

    init {
        editText = EditText(context).apply {
            // Initial text & hint
            val initialText = creationParams?.get("initialText") as? String
            if (initialText != null) setText(initialText)

            hint = creationParams?.get("hint") as? String ?: ""

            val textColor = creationParams.color("textColor", Color.WHITE)
            setTextColor(textColor)
            // The hint carries its own colour: reusing the text colour makes the
            // placeholder read as typed content.
            setHintTextColor(creationParams.color("hintColor", withAlpha(textColor, 0.4f)))

            // Transparent by default. The Flutter frame behind this platform view
            // owns the fill, and setBackgroundColor is also what strips the
            // underline the platform theme would otherwise draw under the field.
            setBackgroundColor(creationParams.color("backgroundColor", Color.TRANSPARENT))

            // The platform default is 14sp, far below the surrounding TV type.
            val fontSize = (creationParams?.get("fontSize") as? Number)?.toFloat() ?: 0f
            if (fontSize > 0f) setTextSize(TypedValue.COMPLEX_UNIT_DIP, fontSize)

            tintCaret(creationParams.color("cursorColor", textColor))

            // No inset of its own - the Flutter frame already pads the content -
            // and no extra font padding, which otherwise pushes text off centre.
            setPadding(0, 0, 0, 0)
            includeFontPadding = false
            gravity = Gravity.CENTER_VERTICAL or gravityFor(creationParams?.get("textAlign") as? String)

            // Input type
            inputType = InputType.TYPE_CLASS_TEXT
            val obscureText = creationParams?.get("obscureText") as? Boolean ?: false
            if (obscureText) {
                inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
            }

            // Max lines
            val maxLines = creationParams?.get("maxLines") as? Int ?: 1
            if (maxLines <= 1) setSingleLine(true) else setMaxLines(maxLines)

            imeOptions = EditorInfo.IME_ACTION_DONE

            // onSubmitted callback
            setOnEditorActionListener { _: TextView, actionId: Int, _: KeyEvent? ->
                if (actionId == EditorInfo.IME_ACTION_DONE) {
                    val instanceId = creationParams?.get("instanceId") as? Int
                    methodChannel.invokeMethod("onSubmitted", mapOf(
                        "instanceId" to instanceId,
                        "text" to this.text.toString()
                    ))
                    true
                } else {
                    false
                }
            }
        }

        methodChannel = MethodChannel(messenger, "native_textfield_tv")

        // TextWatcher
        editText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                val instanceId = creationParams?.get("instanceId") as? Int
                methodChannel.invokeMethod("onTextChanged", mapOf(
                    "instanceId" to instanceId,
                    "text" to s.toString()
                ))
            }
        })

        // Focus listener
        editText.setOnFocusChangeListener { _, hasFocus ->
            val instanceId = creationParams?.get("instanceId") as? Int
            methodChannel.invokeMethod("onFocusChanged", mapOf(
                "instanceId" to instanceId,
                "hasFocus" to hasFocus
            ))
        }
    }

    override fun getView(): View = editText

    override fun dispose() {}

    // Flutter calls
    fun setText(text: String) { editText.setText(text) }
    fun getText(): String = editText.text.toString()
    fun requestFocus() { editText.requestFocus() }
    fun clearFocus() { editText.clearFocus() }
    fun setEnabled(enabled: Boolean) { editText.isEnabled = enabled }
    fun setHint(hint: String?) { editText.hint = hint }

    fun setTextColorFlutter(color: Int) { editText.setTextColor(color) }
    fun setHintTextColorFlutter(color: Int) { editText.setHintTextColor(color) }
    fun setBackgroundColorFlutter(color: Int) { editText.setBackgroundColor(color) }

 fun setObscureText(obscure: Boolean) {
    Log.d("NativeTextfieldTvView", "Updating obscureText=$obscure")
    editText.post {
        val cursorPos = editText.selectionStart

        editText.transformationMethod = if (obscure) 
            android.text.method.PasswordTransformationMethod.getInstance()
        else 
            null

        val inputTypeClass = android.text.InputType.TYPE_CLASS_TEXT
        val variation = if (obscure) android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD else 0
        editText.inputType = inputTypeClass or variation

        editText.setSelection(cursorPos)
        Log.d("NativeTextfieldTvView", "ObscureText update applied, cursorPos=$cursorPos")
    }
}



    fun moveCursor(direction: String) {
        val pos = editText.selectionStart
        when (direction) {
            "left" -> if (pos > 0) editText.setSelection(pos - 1)
            "right" -> if (pos < editText.text.length) editText.setSelection(pos + 1)
        }
    }
}

/// Reads a colour argument. Flutter sends ARGB over the standard codec, where
/// it arrives as an Int (a Long on some platforms).
private fun Map<String?, Any?>?.color(key: String, fallback: Int): Int {
    return when (val value = this?.get(key)) {
        is Int -> value
        is Long -> value.toInt()
        else -> fallback
    }
}

private fun withAlpha(color: Int, alpha: Float): Int {
    val a = (alpha.coerceIn(0f, 1f) * 255f).toInt()
    return (color and 0x00FFFFFF) or (a shl 24)
}

private fun gravityFor(align: String?): Int = when (align) {
    "center" -> Gravity.CENTER_HORIZONTAL
    "right", "end" -> Gravity.END
    else -> Gravity.START
}

/// Tints the caret. Q is the first release exposing this publicly; older
/// devices keep the platform colour rather than being patched through private
/// fields.
private fun EditText.tintCaret(color: Int) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
    try {
        val width = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, 2f, resources.displayMetrics
        ).toInt()
        textCursorDrawable = GradientDrawable().apply {
            setColor(color)
            // The platform stretches this to the line height; only width matters.
            setSize(width, 0)
        }
    } catch (_: Throwable) {
        // Decoration only - a failure keeps the platform caret.
    }
}
