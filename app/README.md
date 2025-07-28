# Medical Assistant Flutter App

A Flutter application that runs your fine-tuned `ericrisco/medical-gemma-3n` model **directly on-device** using the `flutter_gemma` package.

## Features

- **On-Device AI**: Your medical model runs completely on the device
- **Offline Capability**: No internet connection required after model download
- **Privacy First**: All data stays on your device
- **Medical Chat Interface**: Clean, intuitive chat UI for medical questions
- **Model Download**: Automatic download of your fine-tuned model
- **Real-time Responses**: Streaming responses with typing indicators
- **Error Handling**: Robust error handling and user feedback
- **Markdown Support**: Formatted medical responses

## Prerequisites

### 1. Install Flutter
```bash
# macOS
brew install flutter

# Or download from https://flutter.dev/docs/get-started/install
```

### 2. Add Your Pre-trained Model (Recommended)
1. Download your model from HuggingFace:
   ```bash
   curl -L "https://huggingface.co/ericrisco/medical-gemma-3n/resolve/main/model.task" -o medical-gemma-3n.task
   ```
2. Place it in `app/assets/models/medical-gemma-3n.task`
3. The app will automatically load it on startup

### 3. Alternative: Download on First Use
If you prefer users to download the model:
1. Get a HuggingFace token from https://huggingface.co/settings/tokens
2. Edit `lib/services/gemma_model_service.dart`:
   ```dart
   static const String _huggingFaceToken = 'YOUR_HUGGING_FACE_TOKEN_HERE';
   ```

## Setup and Running

### 1. Install Dependencies
```bash
cd app
flutter pub get
```

### 2. Run the App
```bash
# For development
flutter run

# For specific device
flutter run -d chrome    # Web
flutter run -d macos     # macOS
flutter run -d ios       # iOS Simulator
flutter run -d android   # Android device
```

## Usage

### First Time Setup

**Option A: Pre-bundled Model (Recommended)**
1. **Launch the App**: Open the Flutter app
2. **Model Loading**: App automatically loads your pre-bundled model
3. **Start Chatting**: Immediately start asking medical questions

**Option B: Download on First Use**
1. **Launch the App**: Open the Flutter app
2. **Download Model**: Tap "Download Medical Model" 
3. **Wait for Download**: The app will download your fine-tuned model (~2GB)
4. **Start Chatting**: Once downloaded, start asking medical questions

### Chat Interface
- **Status Indicator**: Shows model download/loading status
- **Message Input**: Type medical questions in the text field
- **Streaming Responses**: See responses appear in real-time
- **Clear Chat**: Use menu to clear conversation history

### Example Conversations
- "Hello" → Get a medical greeting
- "What should I do for a burn?" → First aid instructions
- "How to treat a sprained ankle?" → Treatment guidelines
- "What are the signs of a heart attack?" → Emergency symptoms

## Architecture

### Core Components

- **GemmaModelService**: Manages on-device model lifecycle
- **MedicalChatScreen**: Main chat interface
- **ChatMessage**: Message data structure

### On-Device AI Integration

The app uses `flutter_gemma` to run AI completely on-device:
- **Model Download**: Downloads from HuggingFace to device storage
- **Local Inference**: All AI processing happens on-device
- **No Server Calls**: No external API calls after model download

### Model Configuration

```dart
static const String _modelUrl = 'https://huggingface.co/ericrisco/medical-gemma-3n/resolve/main/model.task';
static const String _modelFilename = 'medical-gemma-3n.task';
```

## Customization

### Model Parameters
Edit `lib/services/gemma_model_service.dart` to adjust:
- **Temperature**: Response randomness (0.7 default)
- **Top-K**: Token sampling (40 default)
- **Top-P**: Nucleus sampling (0.9 default)
- **Max Tokens**: Response length (2048 default)

### UI Theming
Edit `lib/main.dart` to customize:
- Colors and themes
- App name and branding
- Material Design 3 styling

## Troubleshooting

### Common Issues

1. **Model Download Fails**
   - Check your HuggingFace token is valid
   - Ensure you have internet connection
   - Verify you have ~2GB free storage

2. **Model Not Loading**
   - Restart the app
   - Check device has sufficient RAM
   - Try clearing app data

3. **Slow Responses**
   - First response may be slow (model loading)
   - Consider reducing max_tokens parameter
   - Ensure device isn't overheating

### Debug Mode
Run with verbose logging:
```bash
flutter run --verbose
```

## Device Requirements

### Minimum Requirements
- **iOS**: iPhone 12 or newer, iOS 14+
- **Android**: 4GB RAM, Android 7.0+
- **Storage**: 3GB free space for model
- **Performance**: Better with newer devices

### Recommended
- **iOS**: iPhone 14 Pro or newer
- **Android**: 8GB RAM, flagship device
- **Storage**: 5GB free space

## Production Deployment

### Build for Release
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release

# macOS
flutter build macos --release
```

### Production Considerations
- Embed HuggingFace token securely
- Consider model compression
- Add crash reporting
- Implement usage analytics

## Medical Disclaimer

⚠️ **Important**: This app is for educational and informational purposes only. It should not be used as a substitute for professional medical advice, diagnosis, or treatment. Always consult qualified healthcare professionals for medical decisions.

## Development

### Project Structure
```
app/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── screens/
│   │   └── medical_chat_screen.dart   # Main chat interface
│   └── services/
│       └── gemma_model_service.dart   # On-device AI management
├── pubspec.yaml                       # Dependencies
└── README.md                          # This file
```

### Key Dependencies
- `flutter_gemma: ^0.9.0` - On-device AI inference
- `provider: ^6.0.5` - State management
- `flutter_markdown: ^0.6.17` - Formatted responses
- `path_provider: ^2.1.1` - File system access

### Adding Features
- **Voice Input**: Add speech-to-text capability
- **Conversation History**: Persistent chat storage
- **Medical Specialties**: Mode switching for different medical domains
- **Offline Indicators**: Show when running offline
- **Model Updates**: Handle model version updates

## Privacy & Security

### Data Privacy
- ✅ **All processing on-device**
- ✅ **No data sent to servers**
- ✅ **No user tracking**
- ✅ **Conversations stay local**

### Security Features
- Model integrity verification
- Secure token storage
- Local data encryption (optional)

---

Built with Flutter and powered by your fine-tuned Gemma3N medical model running completely on-device.