#!/usr/bin/env python3
"""
Fix the build phase to include all the new Swift files
"""

import re

def fix_build_phase():
    project_file = '/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj'
    
    print("🔧 Fixing build phase to include all Swift files...")
    
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Files to add to build phase
    files_to_add = [
        'RealDataModels.swift',
        'RealNewsView.swift', 
        'RealRSSManager.swift',
        'SimpleNewsView.swift',
        'SimpleRSSManager.swift'
    ]
    
    # Find the build phase section and add the new files
    build_phase_pattern = r'(.*1A2B3C4D5E6F7890ABCDEFF9 /\* Sources \*/ = \{\s*isa = PBXSourcesBuildPhase;\s*buildActionMask = 2147483647;\s*files = \(\s*1A2B3C4D5E6F7890ABCDEF03 /\* ContentView\.swift in Sources \*/,\s*1A2B3C4D5E6F7890ABCDEF01 /\* WrestlePickApp\.swift in Sources \*/,\s*\);\s*runOnlyForDeploymentPostprocessing = 0;\s*\};\s*/\* End PBXSourcesBuildPhase section \*/)'
    
    # Generate build file references for the new files
    build_file_refs = ""
    for file_name in files_to_add:
        # Find the build file ID for this file
        file_ref_pattern = rf'(\w+) /\* {re.escape(file_name)} \*/ = {{isa = PBXFileReference;'
        file_ref_match = re.search(file_ref_pattern, content)
        if file_ref_match:
            file_ref_id = file_ref_match.group(1)
            # Find the build file ID for this file
            build_file_pattern = rf'(\w+) /\* {re.escape(file_name)} in Sources \*/ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /\* {re.escape(file_name)} \*/; \}};'
            build_file_match = re.search(build_file_pattern, content)
            if build_file_match:
                build_file_id = build_file_match.group(1)
                build_file_refs += f"\n\t\t\t\t{build_file_id} /* {file_name} in Sources */,"
                print(f"  ✅ Added {file_name} to build phase")
            else:
                print(f"  ❌ Could not find build file for {file_name}")
        else:
            print(f"  ❌ Could not find file reference for {file_name}")
    
    # Update the build phase
    build_phase_replacement = r'\1' + build_file_refs + r'\n\t\t\2'
    content = re.sub(build_phase_pattern, build_phase_replacement, content, flags=re.DOTALL)
    
    # Write the updated content
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ Successfully updated build phase!")
    return True

if __name__ == "__main__":
    try:
        fix_build_phase()
        print("\n🎉 Build phase fix completed successfully!")
    except Exception as e:
        print(f"❌ Error: {e}")
        exit(1)
