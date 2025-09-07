#!/usr/bin/env python3

import re
import os

def fix_file_paths():
    project_file = "WrestlePick.xcodeproj/project.pbxproj"
    
    if not os.path.exists(project_file):
        print(f"Error: {project_file} not found")
        return
    
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Find all Swift file references that need path fixes
    swift_files = [
        'WrestlePickApp.swift',
        'ContentView.swift', 
        'RealDataNewsView.swift',
        'RealDataPredictionsView.swift',
        'RealDataAwardsView.swift',
        'RealDataProfileView.swift',
        'FantasyBookingView.swift',
        'NewsArticle.swift',
        'Event.swift',
        'AnalyticsService.swift',
        'AuthenticationView.swift',
        'BookingEngine.swift',
        'BreakingNewsDetector.swift',
        'FirestoreCollections.swift',
        'LocalDatabaseService.swift',
        'MerchService.swift',
        'NewsService.swift'
    ]
    
    # Fix file paths for each Swift file
    for swift_file in swift_files:
        # Pattern to match file references that need path updates
        pattern = rf'(\t\t[0-9A-F]+\s+\/\*\s+{re.escape(swift_file)}\s+\*\/\s+=\s+\{{isa\s+=\s+PBXFileReference;\s+lastKnownFileType\s+=\s+sourcecode\.swift;\s+path\s+=\s+){re.escape(swift_file)}(\s*;\s*sourceTree\s+=\s+"<group>";\s+\}};)'
        
        # Replace with correct path
        replacement = rf'\1WrestlePick/{swift_file}\2'
        
        content = re.sub(pattern, replacement, content)
    
    # Write the updated content back
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("Successfully fixed file paths in project.pbxproj")

if __name__ == "__main__":
    fix_file_paths()