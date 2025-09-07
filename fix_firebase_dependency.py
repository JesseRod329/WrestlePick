#!/usr/bin/env python3

import re

def fix_firebase_dependency():
    """Fix Firebase dependency in Xcode project file"""
    
    project_file = "WrestlePick.xcodeproj/project.pbxproj"
    
    print("🔧 Fixing Firebase dependency...")
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Check if Firebase package is already referenced
    if "firebase-ios-sdk" in content:
        print("✅ Firebase package already referenced")
        return
    
    # Add Firebase package reference
    # Find the XCRemoteSwiftPackageReference section
    package_ref_pattern = r'(XCRemoteSwiftPackageReference.*?\{[^}]*\})'
    
    # Add Firebase package reference
    firebase_package = '''
		88F074142E6D19A2009FEB42 /* XCRemoteSwiftPackageReference "firebase-ios-sdk" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/firebase/firebase-ios-sdk.git";
			requirement = {
				kind = upToNextMajorVersion;
				minimumVersion = 10.0.0;
			};
		};'''
    
    # Find where to insert the package reference
    if "XCRemoteSwiftPackageReference" in content:
        # Insert after existing package references
        content = re.sub(
            r'(XCRemoteSwiftPackageReference.*?\{[^}]*\})',
            r'\1' + firebase_package,
            content
        )
    else:
        # Add package references section
        package_section = '''
		XCRemoteSwiftPackageReference "firebase-ios-sdk" = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/firebase/firebase-ios-sdk.git";
			requirement = {
				kind = upToNextMajorVersion;
				minimumVersion = 10.0.0;
			};
		};'''
        
        # Find the root object and add package references
        content = re.sub(
            r'(rootObject = [^;]+;)',
            r'\1' + package_section,
            content
        )
    
    # Add Firebase products to package product dependencies
    firebase_products = '''
				88F074142E6D19A2009FEB43 /* FirebaseFirestore */,
				88F074142E6D19A2009FEB44 /* FirebaseAuth */,
				88F074142E6D19A2009FEB45 /* FirebaseAnalytics */,'''
    
    # Find package product dependencies section
    if "packageProductDependencies" in content:
        content = re.sub(
            r'(packageProductDependencies = \([^)]*?)(\);',
            r'\1' + firebase_products + r'\n\t\t\t);',
            content
        )
    else:
        # Add package product dependencies section
        package_deps = '''
		packageProductDependencies = (
			''' + firebase_products + '''
		);'''
        
        # Find the target section and add package dependencies
        content = re.sub(
            r'(buildPhases = \([^)]*?\);.*?buildSettings = \([^)]*?\);.*?buildConfigurationList = [^;]+;)',
            r'\1' + package_deps,
            content
        )
    
    # Write the updated content back
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ Firebase dependency added!")

if __name__ == "__main__":
    fix_firebase_dependency()

