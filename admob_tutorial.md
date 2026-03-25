# Flutter AdMob Implementation Guide: A Step-by-Step Lesson

Welcome to this lesson on mobile monetization! In this tutorial, we will learn how to integrate **Google AdMob** into a Flutter application. We will follow a "best practice" architecture by creating a centralized service to manage our ads.

---

## 📚 What is AdMob?
AdMob is Google's mobile advertising platform that allows developers to earn revenue by showing ads in their apps. In Flutter, we use the `google_mobile_ads` package to communicate with the AdMob SDK.

---

## 🛠️ Step 1: Add the Dependency
First, we need to add the official plugin to our `pubspec.yaml` file.

1.  Open `pubspec.yaml`.
2.  Add `google_mobile_ads` under the `dependencies` section:

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_mobile_ads: ^5.0.0 # Use the latest version
```

3.  Run `flutter pub get` in your terminal.

---

## ⚙️ Step 2: Platform Configuration
AdMob requires specific setup for both Android and iOS to identify your app.

### 🤖 Android Setup
Open `android/app/src/main/AndroidManifest.xml` and add your **AdMob App ID** inside the `<application>` tag:

```xml
<manifest>
    <application>
        <!-- AdMob App ID -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-3940256099942544~3347511713"/> <!-- This is a TEST ID -->
    </application>
</manifest>
```

### 🍎 iOS Setup
Open `ios/Runner/Info.plist` and add the `GADApplicationIdentifier` key:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string> <!-- This is a TEST ID -->
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
</array>
```

---

## 🏗️ Step 3: Create the AdService
To keep our code clean, we centralize ad logic in a service class. This makes it easier to manage ad lifecycle and switch between **Test IDs** and **Production IDs**.

Create a file `lib/services/ad_service.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _isInitialized = false;

  // Test Banner IDs (Safe for development)
  static const String _testBannerIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIdIos = 'ca-app-pub-3940256099942544/2934735716';

  // Initialize the Mobile Ads SDK
  static Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  // Get the correct ID based on platform
  static String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _testBannerIdAndroid;
    } else {
      return _testBannerIdIos;
    }
  }

  // Helper to create a Banner Ad
  static BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
    AdSize size = AdSize.banner, // Allow passing custom sizes
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    )..load();
  }
}
```

---

## 📏 Step 4: Choosing the Right Banner Size
AdMob offers different banner types. Choosing the right one is key to a good user experience and better revenue.

### 1. Standard Banner (`AdSize.banner`)
- **Dimensions**: 320x50.
- **Best For**: Simple layouts where space is fixed.
- **Implementation**: Just pass `AdSize.banner` (default in our service).

### 2. Adaptive Banner (Recommended)
- **Best For**: Modern apps. It automatically scales the ad height based on the device width.
- **Implementation**: Requires calculating the screen width before creating the ad.

---

## 🚀 Step 5: Initialize on Startup
Before showing any ads, we must initialize the SDK in `main.dart`.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Important: Initialize AdMob before runApp
  await AdService.initialize();

  runApp(const MyApp());
}
```

---

## 📱 Step 6: Displaying the Ad in a Widget
Now, let's display an **Adaptive Banner** in one of our screens.

1.  **Define variables** in your `State` class:
```dart
BannerAd? _bannerAd;
bool _isAdLoaded = false;
```

2.  **Implement the loading logic** (Handling responsiveness):
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _loadAdaptiveBanner();
}

void _loadAdaptiveBanner() async {
  // 1. Get the screen width
  final screenWidth = MediaQuery.of(context).size.width.truncate();
  
  // 2. Get the adaptive size
  final adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(screenWidth);

  if (adSize == null) return;

  // 3. Create the ad using our service
  _bannerAd = AdService.createBannerAd(
    size: adSize,
    onAdLoaded: (ad) {
      if (mounted) setState(() => _isAdLoaded = true);
    },
    onAdFailedToLoad: (ad, error) {
      ad.dispose();
    },
  );
}
```

3.  **Display the Widget** in your build method:
```dart
if (_isAdLoaded && _bannerAd != null)
  Center(
    child: SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    ),
  ),
```

4.  **Dispose the ad** when the screen is closed:
```dart
@override
void dispose() {
  _bannerAd?.dispose(); // CRITICAL: Prevent memory leaks
  super.dispose();
}
```

---

## ⚠️ Important
1.  **Never Use Production IDs During Development**: Using your real Ad Unit IDs while testing can lead to account suspension. Always use **Test IDs**.
2.  **Memory Management**: Always call `dispose()` on ads when they are no longer needed.
3.  **Adaptive Banners**: For better user experience, explore `AdSize.getAnchoredAdaptiveBannerAdSize` which adjusts to the screen width.

---

## 🔗 Useful Links
- [Official Google Mobile Ads for Flutter](https://pub.dev/packages/google_mobile_ads)
- [AdMob Implementation Guide (Android)](https://developers.google.com/admob/android/quick-start)
- [AdMob Implementation Guide (iOS)](https://developers.google.com/admob/ios/quick-start)
- [Google AdMob Console](https://apps.admob.com/)
