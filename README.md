# 👶 Baby_Shophub

A modern Flutter mobile application for browsing and purchasing high-quality baby products. **Baby_Shophub** provides parents with a seamless shopping experience featuring secure authentication, intuitive product discovery, and reliable payment processing.

## ✨ Features

- **👤 User Authentication**: Google Sign-In integration for quick and secure access
- **🛍️ Product Browsing**: Browse baby products with detailed descriptions and images
- **🖼️ Image Management**: Upload and manage product images using image picker
- **💾 Local Storage**: Save preferences and order history with SharedPreferences
- **🔗 Deep Linking**: Support for app links and URL navigation
- **⚡ Smooth Animations**: Engaging animations powered by flutter_animate
- **✅ Form Validation**: Robust email and form validation
- **🔄 Loading States**: Beautiful loading indicators with flutter_spinkit
- **🌐 Backend Integration**: Real-time database with Supabase
- **🔐 Secure**: Permission handling and secure authentication

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.8.1+
- **Language**: Dart
- **UI Components**: Material Design 3
- **State Management**: Provider (implicit)
- **Animations**: flutter_animate 4.5.0

### Backend & Services
- **Database**: Supabase (PostgreSQL)
- **Authentication**: 
  - Google Sign-In
  - Supabase Auth
- **Storage**: Supabase Storage for images
- **Deep Linking**: app_links 6.1.4

### Utilities & Libraries
- **Image Processing**: image_picker 1.0.7
- **Permissions**: permission_handler 11.0.1
- **Local Storage**: shared_preferences 2.2.2
- **URL Handling**: url_launcher 6.2.6
- **Form Validation**: email_validator 2.1.17
- **Loading Indicators**: flutter_spinkit 5.2.0
- **Cryptography**: crypto 3.0.3
- **Icons**: cupertino_icons 1.0.8

## 📋 Prerequisites

- Flutter SDK 3.8.1+
- Dart 3.8.1+
- Android SDK 21+ / iOS 12+
- Supabase Project (with Database and Auth enabled)
- Google Cloud credentials for Google Sign-In
- Permission Handler setup for Android/iOS

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/Benjaminofili/Baby_Shophub.git
cd Baby_Shophub
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Set Up Environment Variables
Create a `.env` file or update your Supabase configuration in the app:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GOOGLE_SIGN_IN_CLIENT_ID=your_google_client_id
```

### 4. Configure Android & iOS Permissions
Update your `android/app/build.gradle` and `ios/Runner/Info.plist` to include:
- Camera permission (for image picker)
- Photo library permission
- Internet access

### 5. Run the App
```bash
flutter run
```

### For Specific Platforms:
- **Android**: `flutter run -d android`
- **iOS**: `flutter run -d ios`

## 📁 Project Structure

```
lib/
├── screens/              # UI screens (home, product details, checkout, etc.)
├── widgets/              # Reusable UI components
├── models/               # Data models for products, users, orders
├── services/             # Supabase and API service layer
├── utils/                # Helper functions and constants
├── providers/            # State management (if using Provider)
└── main.dart             # App entry point

assets/
├── images/               # Product images and icons
└── ...                   # Other static assets
```

## 🔄 How It Works

1. **User Authentication**: Sign in with Google or create an account
2. **Browse Products**: Explore baby products with filters and search
3. **View Details**: See detailed product information and images
4. **Add to Cart**: Save products to cart for later purchase
5. **Checkout**: Secure payment and order confirmation
6. **Order Tracking**: Monitor order status and delivery
7. **Account Management**: Manage profile, addresses, and order history

## 🔐 Authentication Flow

1. User launches app
2. Presented with login/signup screen
3. Can sign in with Google or email credentials
4. Upon successful authentication, redirected to home screen
5. Authentication state persisted locally with SharedPreferences
6. Logout clears local storage and returns to login screen

## 📸 Image Management

The app uses `image_picker` to allow users to:
- Select images from device gallery
- Capture images with camera
- Upload to Supabase Storage
- Display product images in product listings and details

Permissions are handled through `permission_handler` for seamless user experience.

## 🧪 Testing

Run unit tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter drive --target=test_driver/app.dart
```

## 📝 Roadmap

- [ ] Advanced product filtering (price range, ratings, categories)
- [ ] Wishlist functionality
- [ ] Product reviews and ratings
- [ ] Payment integration (Stripe/PayPal)
- [ ] Order tracking with real-time updates
- [ ] Push notifications for orders
- [ ] Social sharing features
- [ ] Multi-language support

## 📄 License

This project is currently under development. License details will be added upon public release.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 💬 Support

For issues, questions, or feature requests, please:
- Open an issue on GitHub
- Check existing issues for similar problems
- Contact the development team

## 🌱 About

**Baby_Shophub** is a passion project dedicated to making baby product shopping convenient, safe, and enjoyable for parents. We believe in quality products, transparent information, and exceptional customer service.

---

**Made with ❤️ by Benjamin**
