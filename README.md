# 📸 LangTake Mobile

**LangTake** is a premium, AI-powered language learning application that turns your camera into a personal language tutor. Simply point, capture, and learn the names of objects in your target language with instant translations and native pronunciation.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Flutter](https://img.shields.io/badge/flutter-v3.10+-02569B.svg?logo=flutter)
![AI](https://img.shields.io/badge/AI-Gemini-orange.svg)

---

## ✨ Key Features

- **💎 Premium Glassmorphism UI**: A stunning, modern interface with interactive "liquid glass" elements and smooth animations.
- **🤖 AI Object Identification**: Powered by Google Gemini AI to accurately identify objects from your camera or gallery.
- **🗣️ Native Pronunciation**: Integrated Text-to-Speech (TTS) to help you master the pronunciation of every new word.
- **🇹🇭 Multi-Language Support**: Full UI support for **English** and **Thai**, with easy extensibility for more languages.
- **🖼️ Integrated Album**: A beautiful collection view to manage and review your learning history.
- **🚀 Seamless Onboarding**: A personalized first-time setup experience to tailor the app to your native and target languages.
- **🖋️ Modern Typography**: Uses the elegant **Kanit** font with an ultra-light aesthetic (Weight 200).

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **AI Engine**: [Google Generative AI (Gemini)](https://ai.google.dev/)
- **Local Database**: [Hive](https://docs.hivedb.dev/) (High-performance NoSQL)
- **Persistence**: [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Typography**: [Google Fonts (Kanit)](https://fonts.google.com/specimen/Kanit)

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.10 or higher)
- A Google Gemini API Key ([Get one here](https://aistudio.google.com/app/apikey))

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/lang-take.git
   cd lang-take
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configuration**:
   Create a `config.json` file in the root directory of the project:
   ```json
   {
     "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY_HERE",
     "SHOW_RESET_ONBOARDING": false
   }
   ```
   *Note: `SHOW_RESET_ONBOARDING` defaults to `false`. Set it to `true` if you want to see the "Reset Onboarding" button in the settings menu for debugging.*

### Running the App

Run the application using the configuration file:

```bash
flutter run -d linux --dart-define-from-file=config.json
```
*(Replace `linux` with `android`, `ios`, or your desired device ID)*

---

## ⚙️ Configuration Flags

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `GEMINI_API_KEY` | String | N/A | Your Google Gemini API Key (Required). |
| `SHOW_RESET_ONBOARDING` | Boolean | `false` | Toggles the visibility of the "Reset Onboarding" button in Settings. |

---

## 🌍 Supported Languages

Currently, the UI supports:
- 🇺🇸 English
- 🇹🇭 Thai (ภาษาไทย)

The AI can identify objects and translate them into dozens of languages supported by the Gemini engine.

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Developed with ❤️ by the LangTake Team.*
