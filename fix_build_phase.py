#!/usr/bin/env python3

import re
import uuid

def fix_build_phase():
    """Fix the build phase to include all new files"""
    
    project_file = '/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj'
    
    print("🔧 Fixing build phase to include all files...")
    
    # Read project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Files that should be in the build phase
    files_to_build = [
        'WrestlePickApp.swift',
        'ContentView.swift',
        'RealDataModels.swift',
        'RealNewsView.swift',
        'RealRSSManager.swift',
        'SimpleNewsView.swift',
        'SimpleRSSManager.swift',
        'RealDataPredictionsView.swift',
        'CreatePredictionView.swift',
        'RealDataAwardsView.swift',
        'RealDataProfileView.swift',
        'FantasyBookingView.swift',
        'CreateBookingView.swift',
        'PredictionService.swift',
        'AwardsService.swift',
        'UserService.swift',
        'BookingService.swift',
        'Award.swift',
        'PredictionModels.swift',
        'FantasyBookingModels.swift',
        'User.swift'
    ]
    
    # Find the Sources build phase
    sources_pattern = r'/\* Sources \*/ = \{{(.*?)\}};'
    sources_match = re.search(sources_pattern, content, re.DOTALL)
    
    if sources_match:
        sources_content = sources_match.group(1)
        
        # Clear existing sources and add all files
        new_sources = ""
        for file_name in files_to_build:
            # Find the UUID for this file
            file_uuid_pattern = rf'([A-F0-9]{{24}}) /\* {re.escape(file_name)} \*/'
            file_match = re.search(file_uuid_pattern, content)
            
            if file_match:
                file_uuid = file_match.group(1)
                build_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
                
                # Add to sources
                new_sources += f'\t\t\t\t{build_uuid} /* {file_name} in Sources */,\n'
                print(f"  ✅ Added {file_name} to build phase")
            else:
                print(f"  ❌ Could not find UUID for {file_name}")
        
        # Update content
        new_sources_section = f'/* Sources */ = {{{new_sources}}};'
        content = content.replace(sources_match.group(0), new_sources_section)
    
    # Write updated project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ Successfully fixed build phase!")

if __name__ == "__main__":
    fix_build_phase()