#!/usr/bin/env python3
"""
Script to add model files to Xcode project
This script adds all model files from the Models/ directory to the WrestlePick.xcodeproj
"""

import os
import re
import uuid

def generate_uuid():
    """Generate a 24-character UUID for Xcode project"""
    return ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])

def add_model_files_to_xcode():
    """Add all model files to the Xcode project"""
    
    project_file = "/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj"
    models_dir = "/Users/jesse/IOS/WrestlePick/WrestlePick/Models"
    
    # List of model files to add
    model_files = [
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
    
    # Read current project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Generate UUIDs for new files
    file_refs = {}
    build_files = {}
    
    for model_file in model_files:
        if os.path.exists(os.path.join(models_dir, model_file)):
            file_refs[model_file] = generate_uuid()
            build_files[model_file] = generate_uuid()
            print(f"Adding {model_file} to Xcode project")
        else:
            print(f"Warning: {model_file} not found in Models directory")
    
    # Add file references to PBXFileReference section
    file_ref_section = "/* End PBXFileReference section */"
    new_file_refs = []
    
    for model_file, file_id in file_refs.items():
        new_file_refs.append(f"\t\t{file_id} /* {model_file} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {model_file}; sourceTree = \"<group>\"; }};")
    
    if new_file_refs:
        content = content.replace(file_ref_section, "\n".join(new_file_refs) + "\n" + file_ref_section)
    
    # Add build files to PBXBuildFile section
    build_file_section = "/* End PBXBuildFile section */"
    new_build_files = []
    
    for model_file, build_id in build_files.items():
        file_id = file_refs[model_file]
        new_build_files.append(f"\t\t{build_id} /* {model_file} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {model_file} */; }};")
    
    if new_build_files:
        content = content.replace(build_file_section, "\n".join(new_build_files) + "\n" + build_file_section)
    
    # Add files to Sources build phase
    sources_section_pattern = r'(.*884CA7142E6CF28200051F1A /\* ProfileView\.swift in Sources \*/;.*)'
    sources_replacement = r'\1\n' + '\n'.join([f'\t\t\t\t{build_id} /* {model_file} in Sources */,' for model_file, build_id in build_files.items()])
    
    content = re.sub(sources_section_pattern, sources_replacement, content, flags=re.DOTALL)
    
    # Add files to Models group
    models_group_pattern = r'(.*884CA70F2E6CF28200051F1A /\* SharedUIComponents\.swift \*/;.*)'
    models_replacement = r'\1\n' + '\n'.join([f'\t\t\t\t{file_id} /* {model_file} */,' for model_file, file_id in file_refs.items()])
    
    content = re.sub(models_group_pattern, models_replacement, content, flags=re.DOTALL)
    
    # Write updated project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("Successfully added model files to Xcode project!")

if __name__ == "__main__":
    add_model_files_to_xcode()
