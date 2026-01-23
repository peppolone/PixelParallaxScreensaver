#!/usr/bin/env python3
"""
Script per aggiungere gli sprite PNG al progetto Xcode come risorse
"""
import re

project_path = "/Users/peppe/Desktop/PixelParallaxScreensaver/PixelParallax.xcodeproj/project.pbxproj"

with open(project_path, 'r') as f:
    content = f.read()

sprites = [
    ("G1A2B3C4D5E60001", "G1A2B3C4D5E60002", "character_walk_1.png"),
    ("G2A2B3C4D5E60001", "G2A2B3C4D5E60002", "character_walk_2.png"),
    ("G3A2B3C4D5E60001", "G3A2B3C4D5E60002", "character_walk_3.png"),
]

# Check if already added
if "character_walk_1.png" in content:
    print("Sprites già presenti nel progetto!")
    exit(0)

for build_id, ref_id, filename in sprites:
    # 1. Add to PBXBuildFile section (as resource)
    build_file_entry = f'\t\t\t\t{build_id} /* {filename} in Resources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {filename} */; }};\n'
    content = content.replace(
        "/* End PBXBuildFile section */",
        f"{build_file_entry}/* End PBXBuildFile section */"
    )
    
    # 2. Add to PBXFileReference section
    file_ref_entry = f'\t\t\t\t{ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = image.png; path = "Assets/{filename}"; sourceTree = "<group>"; }};\n'
    content = content.replace(
        "/* End PBXFileReference section */",
        f"{file_ref_entry}/* End PBXFileReference section */"
    )
    
    # 3. Add to group
    content = content.replace(
        'A1B2C3D4E5F60003 /* Info.plist */,',
        f'A1B2C3D4E5F60003 /* Info.plist */,\n\t\t\t\t\t\t{ref_id} /* {filename} */,'
    )

# 4. Add to Resources build phase - find the files array
# Look for PBXResourcesBuildPhase
resources_pattern = r'(/\* Resources \*/ = \{[^}]+files = \()([^)]*)'
match = re.search(resources_pattern, content)
if match:
    existing_files = match.group(2).strip()
    new_files = existing_files
    for build_id, ref_id, filename in sprites:
        new_files += f'\n\t\t\t\t\t\t{build_id} /* {filename} in Resources */,'
    content = content.replace(match.group(0), match.group(1) + new_files)

with open(project_path, 'w') as f:
    f.write(content)

print("✅ Sprites PNG aggiunti al progetto Xcode come risorse!")
