#!/usr/bin/env python3
"""
Add all Swift files to Xcode project
"""

import re
import uuid

def generate_uuid():
    """Generate a 24-character UUID for Xcode project"""
    return ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])

def add_swift_files_to_xcode():
    """Add all Swift files to Xcode project"""
    
    project_file = "/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Swift files to add (excluding the ones already there)
    existing_files = [
        "WrestlePickApp.swift",
        "ContentView.swift", 
        "NewsView.swift",
        "AwardsView.swift",
        "PredictionsView.swift",
        "ProfileView.swift",
        "SharedUIComponents.swift"
    ]
    
    # All Swift files in the directory
    all_swift_files = [
        "NewsArticle.swift",
        "NewsModels.swift", 
        "PredictionModels.swift",
        "User.swift",
        "Award.swift",
        "Event.swift",
        "Merch.swift",
        "MerchModels.swift",
        "SocialModels.swift",
        "SubscriptionModels.swift",
        "FantasyBookingModels.swift",
        "Prediction.swift"
    ]
    
    # Filter out existing files
    new_files = [f for f in all_swift_files if f not in existing_files]
    
    if not new_files:
        print("No new files to add")
        return
    
    # Generate UUIDs
    file_refs = {}
    build_files = {}
    
    for file in new_files:
        file_refs[file] = generate_uuid()
        build_files[file] = generate_uuid()
        print(f"Adding {file} to Xcode project")
    
    # Add file references
    file_ref_pattern = r'(.*884CA70F2E6CF28200051F1A /\* SharedUIComponents\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = SharedUIComponents\.swift; sourceTree = "<group>"; \};.*)'
    
    new_file_refs = []
    for file, file_id in file_refs.items():
        new_file_refs.append(f'\t\t{file_id} /* {file} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file}; sourceTree = "<group>"; }};')
    
    file_ref_replacement = r'\1\n' + '\n'.join(new_file_refs)
    content = re.sub(file_ref_pattern, file_ref_replacement, content, flags=re.DOTALL)
    
    # Add build files
    build_file_pattern = r'(.*884CA7142E6CF28200051F1A /\* ProfileView\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = 884CA70E2E6CF28200051F1A /\* ProfileView\.swift \*/; \};.*)'
    
    new_build_files = []
    for file, build_id in build_files.items():
        file_id = file_refs[file]
        new_build_files.append(f'\t\t{build_id} /* {file} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {file} */; }};')
    
    build_file_replacement = r'\1\n' + '\n'.join(new_build_files)
    content = re.sub(build_file_pattern, build_file_replacement, content, flags=re.DOTALL)
    
    # Add to Sources build phase
    sources_pattern = r'(.*884CA7142E6CF28200051F1A /\* ProfileView\.swift in Sources \*/,.*)'
    
    new_sources = []
    for file, build_id in build_files.items():
        new_sources.append(f'\t\t\t\t{build_id} /* {file} in Sources */,')
    
    sources_replacement = r'\1\n' + '\n'.join(new_sources)
    content = re.sub(sources_pattern, sources_replacement, content, flags=re.DOTALL)
    
    # Add to main group
    group_pattern = r'(.*884CA70F2E6CF28200051F1A /\* SharedUIComponents\.swift \*/,.*)'
    
    new_group_items = []
    for file, file_id in file_refs.items():
        new_group_items.append(f'\t\t\t\t{file_id} /* {file} */,')
    
    group_replacement = r'\1\n' + '\n'.join(new_group_items)
    content = re.sub(group_pattern, group_replacement, content, flags=re.DOTALL)
    
    # Write the updated content
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("Successfully added Swift files to Xcode project!")

if __name__ == "__main__":
    add_swift_files_to_xcode()
