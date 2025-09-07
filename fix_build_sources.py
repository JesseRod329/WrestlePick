#!/usr/bin/env python3

import re
import os

def fix_build_sources():
    project_file = "WrestlePick.xcodeproj/project.pbxproj"
    
    if not os.path.exists(project_file):
        print(f"Error: {project_file} not found")
        return
    
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Find all Swift files in the project
    swift_files = []
    for root, dirs, files in os.walk("WrestlePick"):
        for file in files:
            if file.endswith('.swift'):
                swift_files.append(file)
    
    print(f"Found Swift files: {swift_files}")
    
    # Create build file entries for each Swift file
    build_file_entries = []
    file_ref_entries = []
    sources_entries = []
    
    for i, swift_file in enumerate(swift_files):
        # Generate unique IDs
        file_ref_id = f"88F0{i:04d}2E6D19A2009FEB41"
        build_file_id = f"88F0{i:04d}2E6D19A2009FEB42"
        
        # Create file reference entry
        file_ref_entry = f"\t\t{file_ref_id} /* {swift_file} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {swift_file}; sourceTree = \"<group>\"; }};"
        file_ref_entries.append(file_ref_entry)
        
        # Create build file entry
        build_file_entry = f"\t\t{build_file_id} /* {swift_file} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {swift_file} */; }};"
        build_file_entries.append(build_file_entry)
        
        # Create sources entry
        sources_entry = f"\t\t\t\t\t\t{build_file_id} /* {swift_file} in Sources */,"
        sources_entries.append(sources_entry)
    
    # Add file references to the PBXFileReference section
    file_ref_pattern = r'(/\* Begin PBXFileReference section \*/.*?)(/\* End PBXFileReference section \*/)'
    file_ref_section = re.search(file_ref_pattern, content, re.DOTALL)
    
    if file_ref_section:
        existing_refs = file_ref_section.group(1)
        new_refs = existing_refs + '\n'.join(file_ref_entries) + '\n'
        content = content.replace(file_ref_section.group(1), new_refs)
    
    # Add build file entries to the PBXBuildFile section
    build_file_pattern = r'(/\* Begin PBXBuildFile section \*/.*?)(/\* End PBXBuildFile section \*/)'
    build_file_section = re.search(build_file_pattern, content, re.DOTALL)
    
    if build_file_section:
        existing_build_files = build_file_section.group(1)
        new_build_files = existing_build_files + '\n'.join(build_file_entries) + '\n'
        content = content.replace(build_file_section.group(1), new_build_files)
    
    # Add sources entries to the Sources build phase
    sources_pattern = r'(/\* Sources \*/ = \{[^}]*files = \([^}]*)(\s*\);.*?/\* End PBXSourcesBuildPhase \*/)'
    sources_section = re.search(sources_pattern, content, re.DOTALL)
    
    if sources_section:
        existing_sources = sources_section.group(1)
        new_sources = existing_sources + '\n'.join(sources_entries) + '\n'
        content = content.replace(sources_section.group(1), new_sources)
    
    # Write the updated content back
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("Successfully added all Swift files to build sources")

if __name__ == "__main__":
    fix_build_sources()
