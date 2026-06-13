# ChefRay

ChefRay is a comprehensive Flutter application that empowers users to manage their daily diet, track nutrition, and discover intelligent recipe recommendations.

## Features

- **Diet & Nutrition Tracking**: Log daily food intake and monitor macros (calories, proteins, water).
- **Smart Recommendations**: Get recipe suggestions based on your dietary preferences and scanned ingredients.
- **AI Integration**: Powered by Google Gemini to analyze diet plans, parse OCR results, and rank recipes.
- **Barcode & OCR Scanner**: Easily add foods via barcode scanning or text recognition.
- **Daily Goals & Progress**: Visual representations of daily progress and health metrics.

## Built With

- [Flutter](https://flutter.dev/) - UI Toolkit
- [Supabase](https://supabase.com/) - Backend & Database
- [Firebase Cloud Messaging](https://firebase.google.com/) - Push Notifications
- [Google Gemini API](https://aistudio.google.com/) - AI Analysis

## Getting Started

### Prerequisites

- Flutter SDK (>=3.11.4)
- Dart SDK
- Supabase account & project
- Google AI Studio (Gemini) API Key

### Installation

1. Clone the repository:
   ```bash
   git clone <repository_url>
   cd chefray
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Setup Environment Variables:
   Copy `.env.example` to `.env` and fill in your keys:
   ```bash
   cp .env.example .env
   ```
   **Do NOT commit your `.env` file.** It is ignored by Git by default to keep your secrets safe.

4. Firebase Configuration (Android):
   Copy `android/app/google-services.json.example` to `android/app/google-services.json` and replace the placeholder values with your Firebase project configurations.

5. Run the Application:
   ```bash
   flutter run
   ```

## Güvenlik Notu

Bu repoda gerçek API anahtarları, Firebase yapılandırma dosyaları ve gizli ortam değişkenleri paylaşılmamaktadır. Projeyi çalıştırmak isteyen geliştiriciler `.env.example` dosyasını temel alarak kendi `.env` dosyalarını oluşturmalıdır.

## Academic / Usage Note
This project is intended for demonstration, learning, or academic use. Please ensure you comply with the respective API usage policies for Supabase, Firebase, and Gemini AI.

## License
MIT License
