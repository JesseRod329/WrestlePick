# Firebase Setup Instructions for WrestlePick

## Manual Setup in Xcode

Since the project file is complex, please follow these steps to add Firebase manually:

### 1. Open Xcode Project
1. Open `WrestlePick.xcodeproj` in Xcode
2. Select the project in the navigator
3. Go to the "Package Dependencies" tab

### 2. Add Firebase Package
1. Click the "+" button to add a package
2. Enter the URL: `https://github.com/firebase/firebase-ios-sdk.git`
3. Click "Add Package"
4. Select the following products:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseMessaging
   - FirebaseAnalytics
   - FirebaseCrashlytics
   - FirebaseStorage
   - FirebaseFunctions
5. Click "Add Package"

### 3. Add Additional Packages
Repeat the process for these packages:

#### Kingfisher (Image Loading)
- URL: `https://github.com/onevcat/Kingfisher.git`
- Product: Kingfisher

#### SwiftyJSON (JSON Parsing)
- URL: `https://github.com/SwiftyJSON/SwiftyJSON.git`
- Product: SwiftyJSON

#### Alamofire (Networking)
- URL: `https://github.com/Alamofire/Alamofire.git`
- Product: Alamofire

### 4. Update Import Statements
Once packages are added, update the import statements in your Swift files:

```swift
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebaseStorage
import FirebaseFunctions
```

### 5. Add GoogleService-Info.plist
1. Download your `GoogleService-Info.plist` from Firebase Console
2. Add it to the project (drag and drop into Xcode)
3. Make sure it's added to the target

### 6. Build and Test
1. Clean build folder (Cmd+Shift+K)
2. Build the project (Cmd+B)
3. Run on simulator (Cmd+R)

## Alternative: Use CocoaPods

If you prefer CocoaPods:

1. Install CocoaPods: `sudo gem install cocoapods`
2. Create Podfile:
```ruby
platform :ios, '15.0'
use_frameworks!

target 'WrestlePick' do
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Messaging'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Storage'
  pod 'Firebase/Functions'
  pod 'Kingfisher'
  pod 'SwiftyJSON'
  pod 'Alamofire'
end
```
3. Run `pod install`
4. Open `WrestlePick.xcworkspace` instead of `.xcodeproj`

## Troubleshooting

### Common Issues:
1. **"No such module 'Firebase'"** - Make sure packages are added to the target
2. **Build errors** - Clean build folder and rebuild
3. **Import errors** - Check that all required products are selected
4. **Simulator issues** - Reset simulator and try again

### Verification:
- Check that Firebase packages appear in Project Navigator
- Verify import statements work without errors
- Test build succeeds
- App launches on simulator

## Next Steps:
1. Complete Firebase setup
2. Configure Firebase Console
3. Add GoogleService-Info.plist
4. Test authentication and Firestore
5. Implement app features
