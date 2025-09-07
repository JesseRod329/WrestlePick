#!/usr/bin/env python3

import re
import uuid

def add_files_to_xcode_project():
    """Add new view files to Xcode project"""
    
    project_file = '/Users/jesse/IOS/WrestlePick/WrestlePick.xcodeproj/project.pbxproj'
    
    # New files to add
    new_files = [
        'WrestlePick/Views/RealDataPredictionsView.swift',
        'WrestlePick/Views/CreatePredictionView.swift',
        'WrestlePick/Views/RealDataAwardsView.swift',
        'WrestlePick/Views/RealDataProfileView.swift',
        'WrestlePick/Views/FantasyBookingView.swift',
        'WrestlePick/Views/CreateBookingView.swift',
        'WrestlePick/Services/PredictionService.swift',
        'WrestlePick/Services/AwardsService.swift',
        'WrestlePick/Services/UserService.swift',
        'WrestlePick/Services/BookingService.swift',
        'WrestlePick/Award.swift',
        'WrestlePick/PredictionModels.swift',
        'WrestlePick/FantasyBookingModels.swift',
        'WrestlePick/User.swift'
    ]
    
    print("🔧 Adding new view files to Xcode project...")
    
    # Read project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Generate UUIDs for new files
    file_uuids = {}
    for file_path in new_files:
        file_uuids[file_path] = str(uuid.uuid4()).replace('-', '').upper()[:24]
    
    print(f"Adding {len(new_files)} files to Xcode project")
    for file_path in new_files:
        print(f"  📄 {file_path} -> {file_uuids[file_path]}")
    
    # 1. Add file references to PBXFileReference section
    file_ref_section = re.search(r'/\* Begin PBXFileReference section \*/(.*?)/\* End PBXFileReference section \*/', content, re.DOTALL)
    if file_ref_section:
        file_refs = file_ref_section.group(1)
        
        for file_path in new_files:
            file_name = file_path.split('/')[-1]
            file_uuid = file_uuids[file_path]
            
            # Add file reference
            new_ref = f'\t\t{file_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{file_name}"; sourceTree = "<group>"; }};\n'
            file_refs += new_ref
        
        # Update content
        new_file_ref_section = f'/* Begin PBXFileReference section */{file_refs}/* End PBXFileReference section */'
        content = content.replace(file_ref_section.group(0), new_file_ref_section)
    
    # 2. Add build file references to PBXBuildFile section
    build_file_section = re.search(r'/\* Begin PBXBuildFile section \*/(.*?)/\* End PBXBuildFile section \*/', content, re.DOTALL)
    if build_file_section:
        build_files = build_file_section.group(1)
        
        for file_path in new_files:
            file_name = file_path.split('/')[-1]
            file_uuid = file_uuids[file_path]
            build_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
            
            # Add build file reference
            new_build_file = f'\t\t{build_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {file_name} */; }};\n'
            build_files += new_build_file
        
        # Update content
        new_build_file_section = f'/* Begin PBXBuildFile section */{build_files}/* End PBXBuildFile section */'
        content = content.replace(build_file_section.group(0), new_build_file_section)
    
    # 3. Add files to Sources build phase
    sources_section = re.search(r'/\* Sources \*/ = \{{(.*?)\}};', content, re.DOTALL)
    if sources_section:
        sources_content = sources_section.group(1)
        
        for file_path in new_files:
            file_name = file_path.split('/')[-1]
            file_uuid = file_uuids[file_path]
            build_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
            
            # Add to sources
            new_source = f'\t\t\t\t{build_uuid} /* {file_name} in Sources */,\n'
            sources_content += new_source
        
        # Update content
        new_sources_section = f'/* Sources */ = {{{sources_content}}};'
        content = content.replace(sources_section.group(0), new_sources_section)
    
    # 4. Add files to appropriate groups
    # Add to main group
    main_group_section = re.search(r'/\* WrestlePick \*/ = \{{(.*?)\}};', content, re.DOTALL)
    if main_group_section:
        group_content = main_group_section.group(1)
        
        # Add Views group
        views_group_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
        views_group = f'\t\t\t\t{views_group_uuid} /* Views */,\n'
        group_content += views_group
        
        # Add Services group
        services_group_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
        services_group = f'\t\t\t\t{services_group_uuid} /* Services */,\n'
        group_content += services_group
        
        # Update content
        new_main_group_section = f'/* WrestlePick */ = {{{group_content}}};'
        content = content.replace(main_group_section.group(0), new_main_group_section)
    
    # Write updated project file
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ Successfully added new view files to Xcode project!")
    
    # Verify integration
    print("\n🔍 Verifying integration...")
    for file_path in new_files:
        file_name = file_path.split('/')[-1]
        if file_name in content:
            print(f"  ✅ {file_name} found in project file")
        else:
            print(f"  ❌ {file_name} NOT found in project file")

if __name__ == "__main__":
    add_files_to_xcode_project()
