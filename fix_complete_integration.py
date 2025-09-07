#!/usr/bin/env python3

import re
import uuid

def fix_complete_integration():
    """Completely fix the Xcode project integration"""
    
    project_file = '/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj'
    
    print("🔧 Completely fixing Xcode project integration...")
    
    # Read project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # All Swift files that should be in the project
    all_files = [
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
    
    # Generate UUIDs for all files
    file_uuids = {}
    for file_name in all_files:
        file_uuids[file_name] = str(uuid.uuid4()).replace('-', '').upper()[:24]
    
    print(f"Processing {len(all_files)} files...")
    
    # 1. Clear and rebuild PBXFileReference section
    file_ref_pattern = r'/\* Begin PBXFileReference section \*/(.*?)/\* End PBXFileReference section \*/'
    file_ref_match = re.search(file_ref_pattern, content, re.DOTALL)
    
    if file_ref_match:
        new_file_refs = ""
        for file_name in all_files:
            file_uuid = file_uuids[file_name]
            new_file_refs += f'\t\t{file_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{file_name}"; sourceTree = "<group>"; }};\n'
        
        new_file_ref_section = f'/* Begin PBXFileReference section */{new_file_refs}/* End PBXFileReference section */'
        content = content.replace(file_ref_match.group(0), new_file_ref_section)
        print("  ✅ Rebuilt PBXFileReference section")
    
    # 2. Clear and rebuild PBXBuildFile section
    build_file_pattern = r'/\* Begin PBXBuildFile section \*/(.*?)/\* End PBXBuildFile section \*/'
    build_file_match = re.search(build_file_pattern, content, re.DOTALL)
    
    if build_file_match:
        new_build_files = ""
        for file_name in all_files:
            file_uuid = file_uuids[file_name]
            build_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
            new_build_files += f'\t\t{build_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {file_name} */; }};\n'
        
        new_build_file_section = f'/* Begin PBXBuildFile section */{new_build_files}/* End PBXBuildFile section */'
        content = content.replace(build_file_match.group(0), new_build_file_section)
        print("  ✅ Rebuilt PBXBuildFile section")
    
    # 3. Clear and rebuild Sources build phase
    sources_pattern = r'/\* Sources \*/ = \{{(.*?)\}};'
    sources_match = re.search(sources_pattern, content, re.DOTALL)
    
    if sources_match:
        new_sources = ""
        for file_name in all_files:
            file_uuid = file_uuids[file_name]
            build_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
            new_sources += f'\t\t\t\t{build_uuid} /* {file_name} in Sources */,\n'
        
        new_sources_section = f'/* Sources */ = {{{new_sources}}};'
        content = content.replace(sources_match.group(0), new_sources_section)
        print("  ✅ Rebuilt Sources build phase")
    
    # 4. Update main group to include all files
    main_group_pattern = r'/\* WrestlePick \*/ = \{{(.*?)\}};'
    main_group_match = re.search(main_group_pattern, content, re.DOTALL)
    
    if main_group_match:
        group_content = main_group_match.group(1)
        
        # Add all file references
        for file_name in all_files:
            file_uuid = file_uuids[file_name]
            group_content += f'\t\t\t\t{file_uuid} /* {file_name} */,\n'
        
        new_main_group_section = f'/* WrestlePick */ = {{{group_content}}};'
        content = content.replace(main_group_match.group(0), new_main_group_section)
        print("  ✅ Updated main group")
    
    # Write updated project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ Successfully fixed complete Xcode project integration!")
    
    # Verify integration
    print("\n🔍 Verifying integration...")
    for file_name in all_files:
        if file_name in content:
            print(f"  ✅ {file_name} found in project file")
        else:
            print(f"  ❌ {file_name} NOT found in project file")

if __name__ == "__main__":
    fix_complete_integration()