#!/usr/bin/env python3
"""
Script per aggiungere MISpriteLoader.swift al progetto Xcode
"""
import re

project_path = "/Users/peppe/Desktop/PixelParallaxScreensaver/PixelParallax.xcodeproj/project.pbxproj"

with open(project_path, 'r') as f:
    content = f.read()

# Check if already added
if "MISpriteLoader" in content:
    print("MISpriteLoader.swift già presente nel progetto!")
    exit(0)

# Generate unique IDs (following the pattern used)
file_ref_id = "F1A2B3C4D5E60002"
build_file_id = "F1A2B3C4D5E60001"

# 1. Add to PBXBuildFile section
build_file_entry = f'\t\t\t\t{build_file_id} /* MISpriteLoader.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* MISpriteLoader.swift */; }};\n'
content = content.replace(
    "/* End PBXBuildFile section */",
    f"{build_file_entry}/* End PBXBuildFile section */"
)

# 2. Add to PBXFileReference section
file_ref_entry = f'\t\t\t\t{file_ref_id} /* MISpriteLoader.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MISpriteLoader.swift; sourceTree = "<group>"; }};\n'
content = content.replace(
    "/* End PBXFileReference section */",
    f"{file_ref_entry}/* End PBXFileReference section */"
)

# 3. Add to PBXGroup section (PixelParallax group) - add after MICharacters
content = content.replace(
    'E1F2A3B4C5D60002 /* MICharacters.swift */,',
    f'E1F2A3B4C5D60002 /* MICharacters.swift */,\n\t\t\t\t\t\t{file_ref_id} /* MISpriteLoader.swift */,'
)

# 4. Add to PBXSourcesBuildPhase section - find the files array and add
# Find the Sources build phase and add our file
sources_pattern = r'(/\* Sources \*/ = \{[^}]+files = \()([^)]*)'
match = re.search(sources_pattern, content)
if match:
    existing_files = match.group(2).strip()
    new_files = existing_files + f'\n\t\t\t\t\t\t{build_file_id} /* MISpriteLoader.swift in Sources */,'
    content = content.replace(match.group(0), match.group(1) + new_files)

with open(project_path, 'w') as f:
    f.write(content)

print("✅ MISpriteLoader.swift aggiunto al progetto Xcode!")
