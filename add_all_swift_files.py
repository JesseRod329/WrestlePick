#!/usr/bin/env python3

import os
import re
import uuid

def add_all_swift_files_to_xcode_project():
    # Path to the project file
    project_path = "WrestlePick.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Find all Swift files in the project directory
    swift_files = []
    for root, dirs, files in os.walk("WrestlePick"):
        # Skip certain directories
        skip_dirs = {'.git', '.svn', 'DerivedData', 'Build', 'build'}
        dirs[:] = [d for d in dirs if d not in skip_dirs]
        
        for file in files:
            if file.endswith('.swift'):
                relative_path = os.path.relpath(os.path.join(root, file), "WrestlePick")
                swift_files.append((file, relative_path))
    
    print(f"Found {len(swift_files)} Swift files")
    
    # Check which files are already in the project
    existing_files = set()
    for filename, _ in swift_files:
        if filename in content:
            existing_files.add(filename)
    
    files_to_add = [(filename, path) for filename, path in swift_files if filename not in existing_files]
    
    if not files_to_add:
        print("All Swift files are already in the project!")
        return
    
    print(f"Adding {len(files_to_add)} new files to the project")
    
    # Generate UUIDs for new files
    file_entries = []
    build_entries = []
    
    for filename, relative_path in files_to_add:
        file_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
        build_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
        
        file_entries.append(f'\t\t{file_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};')
        build_entries.append(f'\t\t{build_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {filename} */; }};')
        
        print(f"Adding {filename}")
    
    # Find the PBXFileReference section and add new files
    file_ref_pattern = r'(\/\* Begin PBXFileReference section \*\/.*?)(\/\* End PBXFileReference section \*\/)'
    if re.search(file_ref_pattern, content, re.DOTALL):
        new_file_content = '\n'.join(file_entries) + '\n\t\t'
        content = re.sub(file_ref_pattern, r'\1' + new_file_content + r'\2', content, flags=re.DOTALL)
    
    # Find the PBXBuildFile section and add new build files
    build_file_pattern = r'(\/\* Begin PBXBuildFile section \*\/.*?)(\/\* End PBXBuildFile section \*\/)'
    if re.search(build_file_pattern, content, re.DOTALL):
        new_build_content = '\n'.join(build_entries) + '\n\t\t'
        content = re.sub(build_file_pattern, r'\1' + new_build_content + r'\2', content, flags=re.DOTALL)
    
    # Find the PBXGroup section and add files to the WrestlePick group
    group_pattern = r'(1A2B3C4D5E6F7890ABCDEF01 \/\* WrestlePick \*\/ = \{[^}]*children = \([^)]*)(.*?)(\);)'
    if re.search(group_pattern, content, re.DOTALL):
        new_group_content = '\n\t\t\t\t'.join([f'{file_uuid} /* {filename} */,' for file_uuid, (filename, _) in zip([str(uuid.uuid4()).replace('-', '').upper()[:24] for _ in files_to_add], files_to_add)])
        content = re.sub(group_pattern, r'\1\n\t\t\t\t' + new_group_content + r'\2\3', content, flags=re.DOTALL)
    
    # Find the PBXSourcesBuildPhase section and add files to Sources
    sources_pattern = r'(1A2B3C4D5E6F7890ABCDEF04 \/\* Sources \*\/ = \{[^}]*files = \([^)]*)(.*?)(\);)'
    if re.search(sources_pattern, content, re.DOTALL):
        new_sources_content = '\n\t\t\t\t'.join([f'{build_uuid} /* {filename} in Sources */,' for build_uuid, (filename, _) in zip([str(uuid.uuid4()).replace('-', '').upper()[:24] for _ in files_to_add], files_to_add)])
        content = re.sub(sources_pattern, r'\1\n\t\t\t\t' + new_sources_content + r'\2\3', content, flags=re.DOTALL)
    
    # Write the updated content back to the file
    with open(project_path, 'w') as f:
        f.write(content)
    
    print(f"Successfully added {len(files_to_add)} Swift files to Xcode project!")

if __name__ == "__main__":
    add_all_swift_files_to_xcode_project()
