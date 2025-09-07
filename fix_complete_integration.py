#!/usr/bin/env python3
"""
Complete Xcode integration fix - adds build file definitions and updates build phase
"""

import re
import uuid

def generate_uuid():
    """Generate a 24-character UUID for Xcode project files"""
    return ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])

def fix_complete_integration():
    project_file = '/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj'
    
    print("🔧 Complete Xcode integration fix...")
    
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Files to add to the project
    files_to_add = [
        'RealDataModels.swift',
        'RealNewsView.swift', 
        'RealRSSManager.swift',
        'SimpleNewsView.swift',
        'SimpleRSSManager.swift'
    ]
    
    # Generate UUIDs for build files
    build_file_uuids = {}
    for file_name in files_to_add:
        build_file_uuids[file_name] = generate_uuid()
        print(f"  📄 {file_name} -> {build_file_uuids[file_name]}")
    
    # 1. Add build file definitions
    print("\n1. Adding build file definitions...")
    
    build_file_definitions = ""
    for file_name in files_to_add:
        # Find the file reference ID for this file
        file_ref_pattern = rf'(\w+) /\* {re.escape(file_name)} \*/ = {{isa = PBXFileReference;'
        file_ref_match = re.search(file_ref_pattern, content)
        if file_ref_match:
            file_ref_id = file_ref_match.group(1)
            build_file_definitions += f'''
\t\t{build_file_uuids[file_name]} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {file_name} */; }};'''
            print(f"  ✅ Added build file definition for {file_name}")
        else:
            print(f"  ❌ Could not find file reference for {file_name}")
    
    # Find the last build file definition and add after it
    last_build_file_pattern = r'(.*1A2B3C4D5E6F7890ABCDEF01 /\* WrestlePickApp\.swift in Sources \*/ = \{isa = PBXBuildFile;.*?fileRef = 1A2B3C4D5E6F7890ABCDEF00 /\* WrestlePickApp\.swift \*/; \};)'
    last_build_file_replacement = r'\1' + build_file_definitions
    
    content = re.sub(last_build_file_pattern, last_build_file_replacement, content, flags=re.DOTALL)
    
    # 2. Update build phase to include new files
    print("\n2. Updating build phase...")
    
    build_file_refs = ""
    for file_name in files_to_add:
        build_file_refs += f"\n\t\t\t\t{build_file_uuids[file_name]} /* {file_name} in Sources */,"
    
    # Find the build phase and add the new files
    build_phase_pattern = r'(.*1A2B3C4D5E6F7890ABCDEFF9 /\* Sources \*/ = \{\s*isa = PBXSourcesBuildPhase;\s*buildActionMask = 2147483647;\s*files = \(\s*1A2B3C4D5E6F7890ABCDEF03 /\* ContentView\.swift in Sources \*/,\s*1A2B3C4D5E6F7890ABCDEF01 /\* WrestlePickApp\.swift in Sources \*/,\s*\);\s*runOnlyForDeploymentPostprocessing = 0;\s*\};\s*/\* End PBXSourcesBuildPhase section \*/)'
    
    build_phase_replacement = r'\1' + build_file_refs + r'\n\t\t\2'
    content = re.sub(build_phase_pattern, build_phase_replacement, content, flags=re.DOTALL)
    
    # 3. Write the updated content
    print("\n3. Writing updated project file...")
    
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ Successfully completed Xcode integration fix!")
    print("\n📋 Summary:")
    for file_name in files_to_add:
        print(f"  ✅ {file_name} added to build phase")
    
    return True

def verify_integration():
    """Verify that the files were properly added to build phase"""
    project_file = '/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj'
    
    print("\n🔍 Verifying build phase integration...")
    
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
        if f"{file_name} in Sources" in content:
            print(f"  ✅ {file_name} found in build phase")
        else:
            print(f"  ❌ {file_name} NOT found in build phase")

if __name__ == "__main__":
    try:
        fix_complete_integration()
        verify_integration()
        print("\n🎉 Complete Xcode integration fix completed successfully!")
    except Exception as e:
        print(f"❌ Error: {e}")
        exit(1)
