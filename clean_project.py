#!/usr/bin/env python3

import re

def clean_xcode_project():
    """Remove deleted files from Xcode project"""
    
    project_file = "WrestlePick.xcodeproj/project.pbxproj"
    
    print("🧹 Cleaning up Xcode project...")
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # List of files to remove
    files_to_remove = [
        "AchievementSharingView.swift",
        "PaywallView.swift", 
        "CommentThreadView.swift",
        "FeedView.swift",
        "DataExportView.swift",
        "NewsCardView.swift",
        "NewsService.swift",
        "NewsModels.swift",
        "LocalDatabaseService.swift",
        "MerchService.swift",
        "BookingService.swift",
        "FirestoreCollections.swift",
        "AwardsView.swift",
        "AuthenticationView.swift",
        "CommunityVotingView.swift",
        "NewsArticle.swift"
    ]
    
    # Remove file references
    for filename in files_to_remove:
        # Remove PBXFileReference
        file_ref_pattern = rf'[A-F0-9]{{24}} /\* {re.escape(filename)} \*/ = \{{isa = PBXFileReference;.*?\}};'
        content = re.sub(file_ref_pattern, '', content, flags=re.DOTALL)
        
        # Remove PBXBuildFile
        build_file_pattern = rf'[A-F0-9]{{24}} /\* {re.escape(filename)} in Sources \*/ = \{{isa = PBXBuildFile;.*?\}};'
        content = re.sub(build_file_pattern, '', content, flags=re.DOTALL)
        
        # Remove from build phase
        build_phase_pattern = rf'[A-F0-9]{{24}} /\* {re.escape(filename)} in Sources \*/,'
        content = re.sub(build_phase_pattern, '', content)
        
        print(f"✅ Removed {filename}")
    
    # Write the cleaned project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("🎉 Project cleanup complete!")

if __name__ == "__main__":
    clean_xcode_project()

