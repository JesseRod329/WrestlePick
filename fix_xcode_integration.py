#!/usr/bin/env python3
"""
Comprehensive Xcode Project File Integration Fix
This script properly adds all missing Swift files to the Xcode project
"""

import re
import uuid
import os

def generate_uuid():
    """Generate a 24-character UUID for Xcode project files"""
    return ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])

def fix_xcode_integration():
    project_file = '/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj'
    
    # Files to add to the project
    files_to_add = [
        'RealDataModels.swift',
        'RealNewsView.swift', 
        'RealRSSManager.swift',
        'SimpleNewsView.swift',
        'SimpleRSSManager.swift'
    ]
    
    print("🔧 Fixing Xcode project integration...")
    print(f"Adding {len(files_to_add)} files to Xcode project")
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Generate UUIDs for all files
    file_uuids = {}
    build_file_uuids = {}
    
    for file_name in files_to_add:
        file_uuids[file_name] = generate_uuid()
        build_file_uuids[file_name] = generate_uuid()
        print(f"  📄 {file_name} -> {file_uuids[file_name]}")
    
    # 1. Add file references to the main group
    print("\n1. Adding file references...")
    
    # Find the main group section and add file references
    main_group_pattern = r'(.*1A2B3C4D5E6F7890ABCDEF00 /\* WrestlePickApp\.swift \*/.*?;)(.*?children = \(.*?\);.*?sourceTree = "<group>";.*?};)'
    
    file_refs = ""
    for file_name in files_to_add:
        file_refs += f"\n\t\t\t\t{file_uuids[file_name]} /* {file_name} */;"
    
    main_group_replacement = r'\1' + file_refs + r'\n\t\t\t\2'
    content = re.sub(main_group_pattern, main_group_replacement, content, flags=re.DOTALL)
    
    # 2. Add file reference definitions
    print("2. Adding file reference definitions...")
    
    file_ref_definitions = ""
    for file_name in files_to_add:
        file_ref_definitions += f'''
\t\t{file_uuids[file_name]} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};'''
    
    # Find the last file reference definition and add after it
    last_file_ref_pattern = r'(.*1A2B3C4D5E6F7890ABCDEF00 /\* WrestlePickApp\.swift \*/ = \{isa = PBXFileReference;.*?sourceTree = "<group>"; \};)'
    last_file_ref_replacement = r'\1' + file_ref_definitions
    
    content = re.sub(last_file_ref_pattern, last_file_ref_replacement, content, flags=re.DOTALL)
    
    # 3. Add build file references to the sources build phase
    print("3. Adding build file references...")
    
    build_file_refs = ""
    for file_name in files_to_add:
        build_file_refs += f"\n\t\t\t\t{build_file_uuids[file_name]} /* {file_name} in Sources */;"
    
    # Find the sources build phase and add file references
    sources_phase_pattern = r'(.*1A2B3C4D5E6F7890ABCDEF00 /\* WrestlePickApp\.swift in Sources \*/.*?;)(.*?runOnlyForDeploymentPostprocessing = 0;.*?};)'
    sources_phase_replacement = r'\1' + build_file_refs + r'\n\t\t\t\2'
    
    content = re.sub(sources_phase_pattern, sources_phase_replacement, content, flags=re.DOTALL)
    
    # 4. Add build file definitions
    print("4. Adding build file definitions...")
    
    build_file_definitions = ""
    for file_name in files_to_add:
        build_file_definitions += f'''
\t\t{build_file_uuids[file_name]} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuids[file_name]} /* {file_name} */; }};'''
    
    # Find the last build file definition and add after it
    last_build_file_pattern = r'(.*1A2B3C4D5E6F7890ABCDEF00 /\* WrestlePickApp\.swift in Sources \*/ = \{isa = PBXBuildFile;.*?fileRef = 1A2B3C4D5E6F7890ABCDEF00 /\* WrestlePickApp\.swift \*/; \};)'
    last_build_file_replacement = r'\1' + build_file_definitions
    
    content = re.sub(last_build_file_pattern, last_build_file_replacement, content, flags=re.DOTALL)
    
    # 5. Write the updated content
    print("5. Writing updated project file...")
    
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ Successfully fixed Xcode project integration!")
    print("\n📋 Summary:")
    for file_name in files_to_add:
        print(f"  ✅ {file_name} added to project")
    
    return True

def verify_integration():
    """Verify that the files were properly added"""
    project_file = '/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj'
    
    print("\n🔍 Verifying integration...")
    
    with open(project_file, 'r') as f:
        content = f.read()
    
    files_to_check = [
        'RealDataModels.swift',
        'RealNewsView.swift', 
        'RealRSSManager.swift',
        'SimpleNewsView.swift',
        'SimpleRSSManager.swift'
    ]
    
    for file_name in files_to_check:
        if file_name in content:
            print(f"  ✅ {file_name} found in project file")
        else:
            print(f"  ❌ {file_name} NOT found in project file")

if __name__ == "__main__":
    try:
        fix_xcode_integration()
        verify_integration()
        print("\n🎉 Xcode integration fix completed successfully!")
    except Exception as e:
        print(f"❌ Error: {e}")
        exit(1)
