#!/usr/bin/env python3
"""
Add NewsView.swift to Xcode project
"""

import re
import uuid

def generate_uuid():
    """Generate a 24-character UUID for Xcode project"""
    return ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])

def add_newsview_to_xcode():
    """Add NewsView.swift to Xcode project"""
    
    project_file = "/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Generate UUIDs for NewsView.swift
    file_ref_id = generate_uuid()
    build_file_id = generate_uuid()
    
    print(f"Adding NewsView.swift to Xcode project")
    print(f"File ref ID: {file_ref_id}")
    print(f"Build file ID: {build_file_id}")
    
    # Add file reference after ContentView.swift
    file_ref_pattern = r'(.*884CA70D2E6CF28200051F1A /\* ContentView\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = ContentView\.swift; sourceTree = "<group>"; \};.*)'
    
    file_ref_replacement = r'\1\n\t\t' + file_ref_id + ' /* NewsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NewsView.swift; sourceTree = "<group>"; };'
    content = re.sub(file_ref_pattern, file_ref_replacement, content, flags=re.DOTALL)
    
    # Add build file after ContentView.swift
    build_file_pattern = r'(.*884CA7132E6CF28200051F1A /\* ContentView\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = 884CA70D2E6CF28200051F1A /\* ContentView\.swift \*/; \};.*)'
    
    build_file_replacement = r'\1\n\t\t' + build_file_id + ' /* NewsView.swift in Sources */ = {isa = PBXBuildFile; fileRef = ' + file_ref_id + ' /* NewsView.swift */; };'
    content = re.sub(build_file_pattern, build_file_replacement, content, flags=re.DOTALL)
    
    # Add to Sources build phase after ContentView.swift
    sources_pattern = r'(.*884CA7132E6CF28200051F1A /\* ContentView\.swift in Sources \*/,.*)'
    
    sources_replacement = r'\1\n\t\t\t\t' + build_file_id + ' /* NewsView.swift in Sources */,'
    content = re.sub(sources_pattern, sources_replacement, content, flags=re.DOTALL)
    
    # Add to main group after ContentView.swift
    group_pattern = r'(.*884CA70D2E6CF28200051F1A /\* ContentView\.swift \*/,.*)'
    
    group_replacement = r'\1\n\t\t\t\t' + file_ref_id + ' /* NewsView.swift */,'
    content = re.sub(group_pattern, group_replacement, content, flags=re.DOTALL)
    
    # Write the updated content
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("Successfully added NewsView.swift to Xcode project!")

if __name__ == "__main__":
    add_newsview_to_xcode()
