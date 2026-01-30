# LangTake Mobile

**LangTake** is a cross-platform mobile application designed to facilitate vocabulary acquisition through visual object recognition. By integrating the Google Gemini API with mobile camera hardware, the application analyzes real-world objects and provides immediate translations and pronunciation guides in the user's target language.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Flutter](https://img.shields.io/badge/flutter-v3.10+-02569B.svg?logo=flutter)

---

## Project Overview

This application serves as a technical demonstration of integrating Generative AI with mobile frontend frameworks. The core functionality allows users to capture images or upload files from their gallery, which are then processed to identify the primary subject. The system returns the object's name in the selected target language, accompanied by audio playback for pronunciation verification.

### Core Functionality

* **Object Recognition:** Utilizes Google Gemini (Generative AI) to analyze image data and extract semantic meaning.
* **User Interface:** Implements a glassmorphism design system, utilizing custom shaders and animations for a responsive user experience.
* **Text-to-Speech (TTS):** Integrated audio synthesis to provide phonetic references for identified vocabulary.
* **Data Persistence:** Uses a local NoSQL database to store user history and image metadata.
* **Localization:** Built with an adaptable internationalization (i18n) architecture; currently supports English and Thai.

---

## Technical Specifications

The application is built using the Flutter framework, prioritizing strict state management and modular architecture.

* **Framework:** Flutter (Dart)
* **State Management:** Riverpod
* **AI Service:** Google Generative AI SDK (Gemini)
* **Local Storage:** Hive (NoSQL)
* **Key-Value Store:** Shared Preferences
* **Typography:** Kanit (Google Fonts)

---

## Installation and Setup

Follow the instructions below to set up the development environment.

### Prerequisites

* **Flutter SDK:** Version 3.10 or higher.
* **API Credentials:** A valid Google Gemini API Key.

### Build Instructions

1.  **Clone the Repository**
    ```bash
    git clone [https://github.com/your-username/lang-take.git](https://github.com/your-username/lang-take.git)
    cd lang-take
    ```

2.  **Install Dependencies**
    Retrieve the required packages from pub.dev.
    ```bash
    flutter pub get
    ```

3.  **Environment Configuration**
    To secure sensitive keys, the application requires a configuration file. Create a file named `config.json` in the project root directory:

    ```json
    {
      "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY_HERE",
      "SHOW_RESET_ONBOARDING": false
    }
    ```

    > **Note:** The `SHOW_RESET_ONBOARDING` flag is used for debugging the first-run experience. Set to `true` to expose reset controls in the settings menu.

4.  **Execution**
    Run the application, passing the configuration file as a build argument.

    ```bash
    flutter run -d [device_id] --dart-define-from-file=config.json
    ```
    *Replace `[device_id]` with your target platform (e.g., `android`, `ios`, `linux`).*

---

## Configuration Reference

The application relies on the following build-time configuration flags:

| Key | Type | Description |
| :--- | :--- | :--- |
| **GEMINI_API_KEY** | String | **Required.** The authentication key for the Google Gemini API. |
| **SHOW_RESET_ONBOARDING** | Boolean | **Optional.** Defaults to `false`. Enables debug controls for the onboarding flow. |

---

## License

This software is distributed under the MIT License. Please refer to the [LICENSE](LICENSE) file for full legal text and usage permissions.
