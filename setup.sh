#!/bin/bash

# WrestlePick iOS App Setup Script
# Run this script to set up the development environment

echo "🚀 Setting up WrestlePick iOS App..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi

echo "✅ Xcode found"

# Check if we're in the right directory
if [ ! -f "WrestlePick.xcodeproj/project.pbxproj" ]; then
    echo "❌ Please run this script from the WrestlePick project root directory"
    exit 1
fi

echo "✅ Project structure verified"

# Clean and build the project
echo "🔨 Cleaning and building project..."
xcodebuild clean -project WrestlePick.xcodeproj -scheme WrestlePick

if xcodebuild -project WrestlePick.xcodeproj -scheme WrestlePick -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed. Please check the error messages above."
    exit 1
fi

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "📦 Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit: WrestlePick iOS app setup"
    echo "✅ Git repository initialized"
else
    echo "✅ Git repository already exists"
fi

echo ""
echo "🎉 Setup complete! Your WrestlePick iOS app is ready for development."
echo ""
echo "Next steps:"
echo "1. Open WrestlePick.xcodeproj in Xcode"
echo "2. Select a simulator or device"
echo "3. Press Cmd+R to build and run"
echo ""
echo "To switch to live RSS feeds:"
echo "1. Open ContentView.swift"
echo "2. Change SimpleNewsView() to RealNewsView() on line 6"
echo ""
echo "Happy coding! 🎯"
