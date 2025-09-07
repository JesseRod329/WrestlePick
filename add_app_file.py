#!/usr/bin/env python3

import re

# Read the project.pbxproj file
with open('WrestlePick.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Add WrestlePickApp.swift to the file references
file_ref_pattern = r'(/\* Begin PBXFileReference section \*/.*?)(/\* End PBXFileReference section \*/)'
file_ref_match = re.search(file_ref_pattern, content, re.DOTALL)

if file_ref_match:
    # Add the new file reference
    new_file_ref = '''		/* Begin PBXFileReference section */
		1A2B3C4D5E6F7890 /* WrestlePickApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WrestlePickApp.swift; sourceTree = "<group>"; };
		1A2B3C4D5E6F7891 /* WrestlePickApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WrestlePickApp.swift; sourceTree = "<group>"; };
		/* End PBXFileReference section */'''
    
    content = content.replace(file_ref_match.group(0), new_file_ref)

# Add to PBXBuildFile section
build_file_pattern = r'(/\* Begin PBXBuildFile section \*/.*?)(/\* End PBXBuildFile section \*/)'
build_file_match = re.search(build_file_pattern, content, re.DOTALL)

if build_file_match:
    new_build_file = '''		/* Begin PBXBuildFile section */
		1A2B3C4D5E6F7892 /* WrestlePickApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1A2B3C4D5E6F7890 /* WrestlePickApp.swift */; };
		/* End PBXBuildFile section */'''
    
    content = content.replace(build_file_match.group(0), new_build_file)

# Add to PBXSourcesBuildPhase
sources_pattern = r'(files = \(.*?)(\s+\);.*?runOnlyForDeploymentPostprocessing = 0;)'
sources_match = re.search(sources_pattern, content, re.DOTALL)

if sources_match:
    new_sources_entry = sources_match.group(1) + '''\n				1A2B3C4D5E6F7892 /* WrestlePickApp.swift in Sources */,''' + sources_match.group(2)
    content = content.replace(sources_match.group(0), new_sources_entry)

# Add to PBXGroup (WrestlePick group)
group_pattern = r'(WrestlePick = \{[^}]*children = \([^}]*)(\s+\);.*?sourceTree = "<group>";)'
group_match = re.search(group_pattern, content, re.DOTALL)

if group_match:
    new_group_entry = group_match.group(1) + '''\n				1A2B3C4D5E6F7890 /* WrestlePickApp.swift */,''' + group_match.group(2)
    content = content.replace(group_match.group(0), new_group_entry)

# Write the updated content back
with open('WrestlePick.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("Added WrestlePickApp.swift to Xcode project")

