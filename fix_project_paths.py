#!/usr/bin/env python3

import re

def fix_project_paths():
    """Fix project file to reference correct file paths"""
    
    project_file = '/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj'
    
    print("🔧 Fixing project file paths...")
    
    # Read project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Files that need to be fixed
    files_to_fix = [
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
    
    # Fix file references
    for file_name in files_to_fix:
        # Find the file reference with wrong path
        wrong_path_pattern = rf'([A-F0-9]{{24}}) /\* {re.escape(file_name)} \*/ = \{{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = "{re.escape(file_name)}"; sourceTree = "<group>"; \}};'
        wrong_match = re.search(wrong_path_pattern, content)
        
        if wrong_match:
            file_uuid = wrong_match.group(1)
            # Replace with correct path
            correct_ref = f'{file_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{file_name}"; sourceTree = "<group>"; }};'
            content = content.replace(wrong_match.group(0), correct_ref)
            print(f"  ✅ Fixed path for {file_name}")
        else:
            print(f"  ❌ Could not find wrong path for {file_name}")
    
    # Write updated project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ Successfully fixed project file paths!")

if __name__ == "__main__":
    fix_project_paths()
