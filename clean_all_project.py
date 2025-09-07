#!/usr/bin/env python3

import re

def clean_all_xcode_project():
    """Remove all deleted files from Xcode project and keep only ContentView.swift"""
    
    project_file = "WrestlePick.xcodeproj/project.pbxproj"
    
    print("🧹 Cleaning up entire Xcode project...")
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # List of files to keep (only ContentView.swift)
    files_to_keep = ["ContentView.swift"]
    
    # Get all file references
    file_ref_pattern = r'([A-F0-9]{24}) /\* ([^/]+\.swift) \*/ = \{isa = PBXFileReference;.*?\};'
    file_refs = re.findall(file_ref_pattern, content, re.DOTALL)
    
    # Remove all file references except ContentView.swift
    for file_id, filename in file_refs:
        if filename not in files_to_keep:
            # Remove PBXFileReference
            file_ref_pattern = rf'{file_id} /\* {re.escape(filename)} \*/ = \{{isa = PBXFileReference;.*?\}};'
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
    clean_all_xcode_project()

