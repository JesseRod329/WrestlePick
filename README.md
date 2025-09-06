# WrestlePick iOS App

A comprehensive wrestling fan app for iOS with news, predictions, and community features.

## App Concept

"WrestlePick" - Think you can book better than WWE? Prove it. Track rumors, make predictions, and create your own wrestling awards.

## Features

- **News**: Stay updated with wrestling news and rumors
- **Predictions**: Make predictions and track your accuracy
- **Community**: Connect with other wrestling fans
- **Awards**: Create your own wrestling awards

## Project Structure

```
WrestlePick/
├── WrestlePick/
│   ├── Models/           # Data models
│   │   ├── User.swift
│   │   ├── NewsArticle.swift
│   │   ├── Prediction.swift
│   │   └── Award.swift
│   ├── Services/         # Business logic and data services
│   │   ├── AuthService.swift
│   │   ├── NewsService.swift
│   │   └── PredictionService.swift
│   ├── Views/            # SwiftUI views
│   ├── Resources/        # App resources
│   ├── Utilities/        # Utility functions
│   ├── Extensions/       # Swift extensions
│   ├── Assets.xcassets/  # App assets and icons
│   ├── Preview Content/  # SwiftUI preview assets
│   ├── WrestlePickApp.swift
│   ├── ContentView.swift
│   └── GoogleService-Info.plist
├── .gitignore
└── README.md
```

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Open the project in Xcode
2. Configure Firebase (when ready to implement)
3. Build and run

## Firebase Integration

The project is set up with Firebase configuration ready but not yet implemented. To add Firebase:

1. Add Firebase SDK dependencies to Package.swift
2. Configure Firebase services in the respective service files
3. Update GoogleService-Info.plist with actual Firebase configuration

## Development Status

This is the initial project scaffold. The following features are ready for implementation:

- ✅ Project structure and architecture
- ✅ Basic SwiftUI navigation
- ✅ Data models defined
- ✅ Service layer structure
- ✅ Firebase configuration ready
- ⏳ Firebase integration
- ⏳ UI implementation
- ⏳ Testing
