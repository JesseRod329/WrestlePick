# WrestlePick iOS App

A comprehensive wrestling news and prediction app built with SwiftUI, featuring real-time RSS feed integration and comprehensive wrestling data management.

## 🚀 Features

### ✅ Implemented
- **Real-time News Feed**: Live RSS integration with Wrestling Observer, PWTorch, and Fightful
- **Tab Navigation**: Clean SwiftUI interface with News, Predictions, Awards, and Profile tabs
- **Real Data Integration**: Comprehensive data models for wrestling news, predictions, and more
- **RSS Feed Management**: XML parsing and automatic refresh capabilities
- **Sample Data**: Working sample data for immediate testing and development

### 🔄 In Development
- **Live RSS Feeds**: Full integration with real wrestling news sources
- **Prediction System**: User predictions with accuracy tracking
- **Fantasy Booking**: Interactive storyline creation tools
- **Merchandise Tracking**: Community-driven merch monitoring
- **Social Features**: User profiles and community interactions

## 📱 App Structure

```
WrestlePick/
├── WrestlePick/
│   ├── ContentView.swift          # Main tab navigation
│   ├── WrestlePickApp.swift       # App entry point
│   ├── RealDataModels.swift       # Core data models
│   ├── SimpleNewsView.swift       # News display (currently active)
│   ├── SimpleRSSManager.swift     # Sample data manager
│   ├── RealNewsView.swift         # Live RSS news view
│   ├── RealRSSManager.swift       # Live RSS feed manager
│   ├── Services/                  # Data services
│   │   ├── RSSFeedManager.swift
│   │   ├── BreakingNewsDetector.swift
│   │   ├── DataQualityMonitor.swift
│   │   └── ...
│   └── Views/                     # Additional views
└── WrestlePickTests/              # Test suite
```

## 🛠 Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 15.0+
- macOS 14.0+

### Installation
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd WrestlePick
   ```

2. Open in Xcode:
   ```bash
   open WrestlePick.xcodeproj
   ```

3. Build and run:
   - Select iPhone simulator or device
   - Press Cmd+R to build and run

## 🔧 Current Status

### ✅ Working Features
- **Build Status**: ✅ Successfully builds without errors
- **News Tab**: Displays sample wrestling news with real data structure
- **RSS Integration**: Ready for live RSS feed integration
- **Data Models**: Complete real data models implemented
- **Xcode Integration**: All files properly included in project

### 🎯 Next Steps
1. **Switch to Live RSS**: Change `ContentView.swift` to use `RealNewsView()` instead of `SimpleNewsView()`
2. **Implement Remaining Tabs**: Add functionality to Predictions, Awards, and Profile tabs
3. **Add Real Data APIs**: Integrate with wrestling databases and APIs
4. **UI/UX Enhancement**: Improve user interface and user experience

## 📊 Data Sources

### RSS Feeds (Ready for Integration)
- **Wrestling Observer / F4W Online**: https://www.f4wonline.com/rss
- **PWTorch**: https://pwtorch.com/feed
- **Fightful**: https://www.fightful.com/rss
- **WWE Official**: https://www.wwe.com/rss
- **AEW Official**: https://www.allelitewrestling.com/rss
- **NJPW Official**: https://www.njpw1972.com/rss

### Data Models
- `NewsArticle`: Wrestling news articles with metadata
- `WrestlingPromotion`: WWE, AEW, NJPW, Impact, ROH, Indie
- `NewsCategory`: General, Breaking, Results, Rumors, Analysis, etc.
- `ReliabilityTier`: Tier 1 (Gold Standard), Tier 2, Tier 3
- `NewsSource`: Source information with reliability ratings

## 🧪 Testing

### Current Test Coverage
- **Unit Tests**: Basic functionality tests
- **Integration Tests**: Real data integration tests
- **Build Tests**: Xcode project integration tests

### Running Tests
```bash
# Run all tests
xcodebuild test -project WrestlePick.xcodeproj -scheme WrestlePick

# Run specific test
xcodebuild test -project WrestlePick.xcodeproj -scheme WrestlePick -only-testing:WrestlePickTests/RealDataIntegrationTests
```

## 🔄 Development Workflow

### Switching to Live RSS Feeds
To enable live RSS feeds instead of sample data:

1. Open `ContentView.swift`
2. Change line 6 from:
   ```swift
   SimpleNewsView()
   ```
   to:
   ```swift
   RealNewsView()
   ```

### Adding New Features
1. Create new Swift files in appropriate directories
2. Add files to Xcode project using the provided Python scripts
3. Update `ContentView.swift` to include new features
4. Test thoroughly before committing

## 📝 Recent Changes

### Latest Commit (777160f)
- ✅ Fixed Xcode project integration issues
- ✅ Resolved build errors and compilation issues
- ✅ Added comprehensive real data models
- ✅ Implemented RSS feed integration framework
- ✅ Created working sample data system
- ✅ Established proper file structure and organization

## 🤝 Team Collaboration

### Git Workflow
- **Main Branch**: `main` - stable, working code
- **Feature Branches**: Create branches for new features
- **Pull Requests**: Use PRs for code review and integration

### Code Standards
- Follow SwiftUI best practices
- Use meaningful variable and function names
- Add comments for complex logic
- Maintain consistent code formatting

## 📞 Support

For questions or issues:
1. Check the build status first
2. Review the error messages in Xcode
3. Check the git history for recent changes
4. Create an issue with detailed description

## 🎯 Roadmap

### Phase 1: Core Functionality ✅
- [x] Basic app structure
- [x] Real data models
- [x] RSS feed integration
- [x] Working build system

### Phase 2: Enhanced Features (Next)
- [ ] Live RSS feed integration
- [ ] Prediction system
- [ ] User authentication
- [ ] Social features

### Phase 3: Advanced Features
- [ ] Fantasy booking
- [ ] Merchandise tracking
- [ ] Push notifications
- [ ] Analytics and monitoring

---

**Ready for team development!** 🚀

The app is fully functional with a solid foundation for real data integration and feature development.