# LangTake Mobile

LangTake Mobile is a native AI language tutor in your pocket.

## Features (MVP)

- **Native Camera Experience**: Instant launch, tap-to-focus, pinch-to-zoom.
- **On-Device AI Integration**: Uses Google Gemini API (Streamed) to identify objects.
- **Native Text-to-Speech**: Pronounces the name of the identified object.
- **Offline History**: Saves identified objects locally (JSON storage).
- **Dark Mode**: Sleek Material 3 dark theme.

## Setup

1.  **Dependencies**:
    Run `flutter pub get` to install dependencies.

2.  **API Key**:
    Set your Gemini API key in `lib/core/services/gemini_service.dart` or pass it via `--dart-define=GEMINI_API_KEY=your_key`.

3.  **Run**:
    `flutter run`

## Architecture

- **State Management**: Riverpod
- **Navigation**: GoRouter (Setup ready, currently using direct home widget)
- **AI**: google_generative_ai
- **Camera**: camera package
- **TTS**: flutter_tts
- **Storage**: JSON file (Isar implementation pending build_runner fix)

## Note on Database

The project was initially designed to use Isar, but due to environment issues with `build_runner`, a JSON file-based repository (`HistoryRepository`) is used for the MVP to ensure robustness and zero-setup persistence.
