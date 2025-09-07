#!/usr/bin/env python3
"""
Simple script to add model files to Xcode project by modifying the project.pbxproj file
"""

import re
import uuid

def generate_uuid():
    """Generate a 24-character UUID for Xcode project"""
    return ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])

def add_models_to_xcode():
    """Add model files to Xcode project"""
    
    project_file = "/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Model files to add
    models = [
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
        "FantasyBookingModels.swift"
    ]
    
    # Generate UUIDs
    file_refs = {}
    build_files = {}
    
    for model in models:
        file_refs[model] = generate_uuid()
        build_files[model] = generate_uuid()
    
    # Add file references after the last existing file reference
    file_ref_pattern = r'(.*884CA70F2E6CF28200051F1A /\* SharedUIComponents\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = SharedUIComponents\.swift; sourceTree = "<group>"; \};.*)'
    
    new_file_refs = []
    for model, file_id in file_refs.items():
        new_file_refs.append(f'\t\t{file_id} /* {model} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {model}; sourceTree = "<group>"; }};')
    
    file_ref_replacement = r'\1\n' + '\n'.join(new_file_refs)
    content = re.sub(file_ref_pattern, file_ref_replacement, content, flags=re.DOTALL)
    
    # Add build files after the last existing build file
    build_file_pattern = r'(.*884CA7142E6CF28200051F1A /\* ProfileView\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = 884CA70E2E6CF28200051F1A /\* ProfileView\.swift \*/; \};.*)'
    
    new_build_files = []
    for model, build_id in build_files.items():
        file_id = file_refs[model]
        new_build_files.append(f'\t\t{build_id} /* {model} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {model} */; }};')
    
    build_file_replacement = r'\1\n' + '\n'.join(new_build_files)
    content = re.sub(build_file_pattern, build_file_replacement, content, flags=re.DOTALL)
    
    # Add to Sources build phase
    sources_pattern = r'(.*884CA7142E6CF28200051F1A /\* ProfileView\.swift in Sources \*/,.*)'
    
    new_sources = []
    for model, build_id in build_files.items():
        new_sources.append(f'\t\t\t\t{build_id} /* {model} in Sources */,')
    
    sources_replacement = r'\1\n' + '\n'.join(new_sources)
    content = re.sub(sources_pattern, sources_replacement, content, flags=re.DOTALL)
    
    # Add to Models group (we need to find where the Models group is defined)
    # For now, let's add them to the main group after SharedUIComponents
    group_pattern = r'(.*884CA70F2E6CF28200051F1A /\* SharedUIComponents\.swift \*/,.*)'
    
    new_group_items = []
    for model, file_id in file_refs.items():
        new_group_items.append(f'\t\t\t\t{file_id} /* {model} */,')
    
    group_replacement = r'\1\n' + '\n'.join(new_group_items)
    content = re.sub(group_pattern, group_replacement, content, flags=re.DOTALL)
    
    # Write the updated content
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("Successfully added model files to Xcode project!")

if __name__ == "__main__":
    add_models_to_xcode()
