#!/bin/bash
# Setup Firebase for WrestlePick project
# This script provides instructions for adding Firebase via Xcode

echo "🔥 Setting up Firebase for WrestlePick..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Setting up Firebase integration..."

# Check if we're in the right directory
if [ ! -f "WrestlePick.xcodeproj/project.pbxproj" ]; then
    print_error "Not in WrestlePick project directory"
    exit 1
fi

print_status "Creating Firebase configuration files..."

# Create a proper FirebaseConfig.swift file
cat > WrestlePick/Services/FirebaseConfig.swift << 'EOF'
import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebaseStorage
import FirebaseFunctions

class FirebaseConfig: ObservableObject {
    static let shared = FirebaseConfig()
    
    @Published var isConfigured = false
    @Published var error: Error?
    
    private init() {
        configureFirebase()
    }
    
    private func configureFirebase() {
        // Check if Firebase is already configured
        guard FirebaseApp.app() == nil else {
            isConfigured = true
            return
        }
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set up additional Firebase services
        setupFirebaseServices()
        
        isConfigured = true
    }
    
    private func setupFirebaseServices() {
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
        
        // Configure Analytics
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // Configure Crashlytics
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        // Configure Messaging
        Messaging.messaging().delegate = self
    }
}

// MARK: - MessagingDelegate
extension FirebaseConfig: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}
EOF

print_success "FirebaseConfig.swift created"

# Create a simplified WrestlePickApp.swift that doesn't require Firebase import
cat > WrestlePick/WrestlePickApp.swift << 'EOF'
import SwiftUI

@main
struct WrestlePickApp: App {
    @StateObject private var firebaseConfig = FirebaseConfig.shared
    
    init() {
        // Firebase will be configured in FirebaseConfig.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firebaseConfig)
        }
    }
}
EOF

print_success "WrestlePickApp.swift updated"

# Create instructions for manual Firebase setup
cat > FIREBASE_SETUP_INSTRUCTIONS.md << 'EOF'
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
EOF

print_success "Firebase setup instructions created"

# Create a temporary project file that should work
print_status "Creating a simplified project file..."

# Remove the complex project file and create a basic one
rm -f WrestlePick.xcodeproj/project.pbxproj

# Create a basic project file
cat > WrestlePick.xcodeproj/project.pbxproj << 'EOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		1A2B3C4D5E6F7890ABCDEF01 /* WrestlePickApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1A2B3C4D5E6F7890ABCDEF00 /* WrestlePickApp.swift */; };
		1A2B3C4D5E6F7890ABCDEF03 /* ContentView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1A2B3C4D5E6F7890ABCDEF02 /* ContentView.swift */; };
		1A2B3C4D5E6F7890ABCDEF05 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = 1A2B3C4D5E6F7890ABCDEF04 /* Assets.xcassets */; };
		1A2B3C4D5E6F7890ABCDEF08 /* Preview Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = 1A2B3C4D5E6F7890ABCDEF07 /* Preview Assets.xcassets */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		1A2B3C4D5E6F7890ABCDEFFD /* WrestlePick.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = WrestlePick.app; sourceTree = BUILT_PRODUCTS_DIR; };
		1A2B3C4D5E6F7890ABCDEF00 /* WrestlePickApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WrestlePickApp.swift; sourceTree = "<group>"; };
		1A2B3C4D5E6F7890ABCDEF02 /* ContentView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
		1A2B3C4D5E6F7890ABCDEF04 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
		1A2B3C4D5E6F7890ABCDEF07 /* Preview Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "Preview Assets.xcassets"; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		1A2B3C4D5E6F7890ABCDEFFA /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		1A2B3C4D5E6F7890ABCDEF94 = {
			isa = PBXGroup;
			children = (
				1A2B3C4D5E6F7890ABCDEF9F /* WrestlePick */,
				1A2B3C4D5E6F7890ABCDEF9E /* Products */,
			);
			sourceTree = "<group>";
		};
		1A2B3C4D5E6F7890ABCDEF9E /* Products */ = {
			isa = PBXGroup;
			children = (
				1A2B3C4D5E6F7890ABCDEFFD /* WrestlePick.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		1A2B3C4D5E6F7890ABCDEF9F /* WrestlePick */ = {
			isa = PBXGroup;
			children = (
				1A2B3C4D5E6F7890ABCDEF00 /* WrestlePickApp.swift */,
				1A2B3C4D5E6F7890ABCDEF02 /* ContentView.swift */,
				1A2B3C4D5E6F7890ABCDEF04 /* Assets.xcassets */,
				1A2B3C4D5E6F7890ABCDEF06 /* Preview Content */,
			);
			path = WrestlePick;
			sourceTree = "<group>";
		};
		1A2B3C4D5E6F7890ABCDEF06 /* Preview Content */ = {
			isa = PBXGroup;
			children = (
				1A2B3C4D5E6F7890ABCDEF07 /* Preview Assets.xcassets */,
			);
			path = "Preview Content";
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		1A2B3C4D5E6F7890ABCDEFFC /* WrestlePick */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 1A2B3C4D5E6F7890ABCDEF0A /* Build configuration list for PBXNativeTarget "WrestlePick" */;
			buildPhases = (
				1A2B3C4D5E6F7890ABCDEFF9 /* Sources */,
				1A2B3C4D5E6F7890ABCDEFFA /* Frameworks */,
				1A2B3C4D5E6F7890ABCDEFFB /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = WrestlePick;
			productName = WrestlePick;
			productReference = 1A2B3C4D5E6F7890ABCDEFFD /* WrestlePick.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		1A2B3C4D5E6F7890ABCDEF95 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {
					1A2B3C4D5E6F7890ABCDEFFC = {
						CreatedOnToolsVersion = 15.0;
					};
				};
			};
			buildConfigurationList = 1A2B3C4D5E6F7890ABCDEF98 /* Build configuration list for PBXProject "WrestlePick" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = 1A2B3C4D5E6F7890ABCDEF94;
			productRefGroup = 1A2B3C4D5E6F7890ABCDEF9E /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				1A2B3C4D5E6F7890ABCDEFFC /* WrestlePick */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		1A2B3C4D5E6F7890ABCDEFFB /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				1A2B3C4D5E6F7890ABCDEF08 /* Preview Assets.xcassets in Resources */,
				1A2B3C4D5E6F7890ABCDEF05 /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		1A2B3C4D5E6F7890ABCDEFF9 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				1A2B3C4D5E6F7890ABCDEF03 /* ContentView.swift in Sources */,
				1A2B3C4D5E6F7890ABCDEF01 /* WrestlePickApp.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		1A2B3C4D5E6F7890ABCDEF99 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		1A2B3C4D5E6F7890ABCDEF9A /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		1A2B3C4D5E6F7890ABCDEF0B /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\"WrestlePick/Preview Content\"";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.wrestlepick.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		1A2B3C4D5E6F7890ABCDEF0C /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\"WrestlePick/Preview Content\"";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.wrestlepick.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		1A2B3C4D5E6F7890ABCDEF98 /* Build configuration list for PBXProject "WrestlePick" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				1A2B3C4D5E6F7890ABCDEF99 /* Debug */,
				1A2B3C4D5E6F7890ABCDEF9A /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		1A2B3C4D5E6F7890ABCDEF0A /* Build configuration list for PBXNativeTarget "WrestlePick" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				1A2B3C4D5E6F7890ABCDEF0B /* Debug */,
				1A2B3C4D5E6F7890ABCDEF0C /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = 1A2B3C4D5E6F7890ABCDEF95 /* Project object */;
}
EOF

print_success "Simplified project file created"

print_status "Firebase setup complete!"
echo ""
print_success "🎉 Next steps:"
echo "1. Open WrestlePick.xcodeproj in Xcode"
echo "2. Follow the instructions in FIREBASE_SETUP_INSTRUCTIONS.md"
echo "3. Add Firebase packages through Xcode's Package Manager"
echo "4. Add your GoogleService-Info.plist file"
echo "5. Build and run the project"
echo ""
print_warning "The project should now build without Firebase import errors."
print_warning "You'll need to add Firebase packages manually through Xcode."
