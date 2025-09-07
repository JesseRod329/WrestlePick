#!/usr/bin/env python3

import re
import uuid

def add_merchitem_to_xcode():
    """Add MerchItem.swift to Xcode project"""
    
    project_file = "WrestlePick.xcodeproj/project.pbxproj"
    
    print("🔧 Adding MerchItem.swift to Xcode project...")
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Generate unique IDs for the new file
    file_ref_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
    build_file_id = str(uuid.uuid4()).replace('-', '').upper()[:24]
    
    # Add PBXFileReference for MerchItem.swift
    file_ref = f'''
		{file_ref_id} /* MerchItem.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "MerchItem.swift"; sourceTree = "<group>"; }};'''
    
    # Add PBXBuildFile for MerchItem.swift
    build_file = f'''
		{build_file_id} /* MerchItem.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* MerchItem.swift */; }};'''
    
    # Find the PBXFileReference section and add the file reference
    if "PBXFileReference" in content:
        # Find the last PBXFileReference entry
        pattern = r'(.*?)(\s+[A-F0-9]{24} /\* [^*]+ \*/ = \{isa = PBXFileReference[^}]+;\};)'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            content = content.replace(match.group(0), match.group(0) + file_ref)
        else:
            # Fallback: add after the first PBXFileReference
            content = re.sub(
                r'(\s+[A-F0-9]{24} /\* [^*]+ \*/ = \{isa = PBXFileReference[^}]+;\};)',
                r'\1' + file_ref,
                content,
                count=1
            )
    
    # Find the PBXBuildFile section and add the build file
    if "PBXBuildFile" in content:
        # Find the last PBXBuildFile entry
        pattern = r'(.*?)(\s+[A-F0-9]{24} /\* [^*]+ \*/ = \{isa = PBXBuildFile[^}]+;\};)'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            content = content.replace(match.group(0), match.group(0) + build_file)
        else:
            # Fallback: add after the first PBXBuildFile
            content = re.sub(
                r'(\s+[A-F0-9]{24} /\* [^*]+ \*/ = \{isa = PBXBuildFile[^}]+;\};)',
                r'\1' + build_file,
                content,
                count=1
            )
    
    # Add the file to the main group
    group_pattern = r'(WrestlePick = \{[^}]*children = \([^)]*?)(\);.*?sourceTree = "<group>";)'
    if re.search(group_pattern, content):
        content = re.sub(
            group_pattern,
            r'\1' + f'\n\t\t\t\t{file_ref_id} /* MerchItem.swift */,' + r'\n\t\t\t\2',
            content
        )
    
    # Add the file to the build phase
    sources_pattern = r'(buildPhases = \([^)]*?PBXSourcesBuildPhase[^)]*?files = \([^)]*?)(\);.*?runOnlyForDeploymentPostprocessing = 0;)'
    if re.search(sources_pattern, content):
        content = re.sub(
            sources_pattern,
            r'\1' + f'\n\t\t\t\t{build_file_id} /* MerchItem.swift in Sources */,' + r'\n\t\t\t\2',
            content
        )
    
    # Write the updated content back
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ MerchItem.swift added to Xcode project!")

if __name__ == "__main__":
    add_merchitem_to_xcode()

