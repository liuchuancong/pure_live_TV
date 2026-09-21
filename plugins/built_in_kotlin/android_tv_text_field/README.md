# Native TextField TV

A Flutter plugin that provides native Android EditText component as a solution for Android TV remote control issues with Flutter's default TextField.

## 🚨 Problem Statement

According to [Flutter issue #154924](https://github.com/flutter/flutter/issues/154924) and [Flutter issue #147772](https://github.com/flutter/flutter/issues/147772), Flutter's default `TextField` has multiple issues with TV remotes on Android TV devices:

- **Issue #154924**: The keyboard appears but arrow key navigation through letters doesn't work because the Flutter app keeps focus
- **Issue #147772**: D-pad navigation is broken after closing the keyboard, preventing focus changes between TextFields

**This plugin provides a native Android solution** that bypasses these limitations by using Android's native `EditText` component through PlatformView.

## ✨ Features

- **Android TV Remote Compatible**: Works perfectly with TV remote controls
- **Native Android EditText**: Uses Android's native text input component
- **Full TextEditingController Compatibility**: Inherits from TextEditingController for seamless integration
- **Focus Management**: Complete focus control with FocusNode support
- **Real-time Text Access**: Get and set text content in real-time
- **Customizable**: Support for hints, initial text, and styling
- **Platform Support**: Currently supports Android (TV and mobile)

## 🎯 Use Cases

- **Android TV Apps**: Perfect for apps that need text input on Android TV
- **Chromecast Apps**: Solves the remote control input issue on Chromecast devices
- **TV Remote Navigation**: Full compatibility with TV remote arrow keys and selection
- **Legacy Flutter Apps**: Drop-in replacement for problematic TextField instances

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  native_textfield_tv: ^0.0.2
```

## 🚀 Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_textfield_tv/native_textfield_tv.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _textContent = '';
  
  final ScrollController _scrollController = ScrollController();
  
  final FocusNode _firstTextFieldFocus = FocusNode();
  final FocusNode _secondTextFieldFocus = FocusNode();
  
  final NativeTextFieldController _firstController = NativeTextFieldController();
  final NativeTextFieldController _secondController = NativeTextFieldController(text: 'Initial text');

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await NativeTextfieldTv().getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native TextField TV Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Native TextField TV Demo'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform Info',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Platform Version: $_platformVersion'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Native TextField Demo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _secondController.setText('New text from button');
                              setState(() {
                                _textContent = _secondController.text;
                              });
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Set Text'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              _secondController.clear();
                              setState(() {
                                _textContent = _secondController.text;
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear Text'),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      DpadNativeTextField(
                        focusNode: _firstTextFieldFocus, 
                        controller: _firstController,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      DpadNativeTextField(
                        focusNode: _secondTextFieldFocus, 
                        controller: _secondController,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      ElevatedButton.icon(
                        onPressed: () {
                          _firstTextFieldFocus.requestFocus();
                        },
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Focus to First TextField'),
                      ),
                      
                      const SizedBox(height: 16),
                      Text('Current text content: $_textContent'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstTextFieldFocus.dispose();
    _secondTextFieldFocus.dispose();
    _firstController.dispose();
    _secondController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
```

## 📚 API Reference

### NativeTextField

| Parameter | Type | Description |
|-----------|------|-------------|
| `hint` | `String?` | Hint text |
| `initialText` | `String?` | Initial text |
| `focusNode` | `FocusNode?` | Focus node for TV remote navigation |
| `onChanged` | `ValueChanged<String>?` | Text change callback |
| `onFocusChanged` | `ValueChanged<bool>?` | Focus change callback |
| `enabled` | `bool` | Whether the field is enabled, defaults to true |
| `width` | `double?` | Width of the field |
| `height` | `double?` | Height of the field |

### NativeTextFieldController

**Inherits from TextEditingController, providing all TextEditingController functionality:**

| Property/Method | Type | Description |
|-----------------|------|-------------|
| `text` | `String` | Text content (inherited from TextEditingController) |
| `selection` | `TextSelection` | Text selection (inherited from TextEditingController) |
| `addListener(VoidCallback listener)` | `void` | Add listener (inherited from TextEditingController) |
| `removeListener(VoidCallback listener)` | `void` | Remove listener (inherited from TextEditingController) |
| `clear()` | `void` | Clear text (inherited from TextEditingController) |
| `setText(String text)` | `Future<void>` | Set text content |
| `getText()` | `Future<String>` | Get text content |
| `requestFocus()` | `Future<void>` | Request focus |
| `clearFocus()` | `Future<void>` | Clear focus |
| `setEnabled(bool enabled)` | `Future<void>` | Set enabled state |
| `setHint(String hint)` | `Future<void>` | Set hint text |
| `onFocusChanged` | `ValueChanged<bool>?` | Focus change callback |

## 🌐 Platform Support

- ✅ **Android** (TV and Mobile) - Uses PlatformView with native EditText
- ❌ iOS (Not implemented yet)
- ❌ Web (Not implemented yet)

## 🔧 Development Notes

This plugin uses Flutter's PlatformView mechanism to create native EditText components on Android. Communication between Flutter and native code is achieved through MethodChannel.

**Key Update:** NativeTextFieldController now inherits from TextEditingController, which means:

1. **Full Compatibility**: Can be used anywhere a TextEditingController is expected
2. **Synchronous Operations**: Supports synchronous text operations (e.g., `controller.text = 'new text'`)
3. **Listener Support**: Supports `addListener` and `removeListener`
4. **Auto-Sync**: Text changes automatically sync to native side
5. **Bidirectional Binding**: Native text changes also sync to Flutter side

### Why This Solution?

The [Flutter issue #154924](https://github.com/flutter/flutter/issues/154924) describes a problem where Flutter's default TextField doesn't work properly with TV remotes on Android TV devices. The keyboard appears but arrow key navigation through letters doesn't work because the Flutter app keeps focus.

This plugin provides a native Android solution that bypasses this limitation by using Android's native `EditText` component, which handles TV remote input correctly.

### Project Structure

```
lib/
├── native_textfield_tv.dart              # Main API
├── native_textfield_tv_platform_interface.dart
└── native_textfield_tv_method_channel.dart     

android/src/main/kotlin/com/example/native_textfield_tv/
├── NativeTextfieldTvPlugin.kt            # Plugin main class
└── NativeTextfieldTvView.kt              # PlatformView implementation
```


