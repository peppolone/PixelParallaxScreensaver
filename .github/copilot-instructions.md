# Scenery & Drawing Instructions
1. THE SEA IS PERFECT: DO NOT TOUCH `drawSea`, `drawMonkeyIslandReflection`, or any code related to the sea generation in `MIScenery.swift` under any circumstances. It is considered final and perfect by the user. 
2. Make sure that when refactoring `MIScenery.swift` the sea logic remains absolutely untouched.

# Development & Debugging Rules
1. **Compilation Validation**: Always run `./install.sh` after making Swift changes to verify that the project compiles on both x86_64 and arm64. If an error occurs, analyze the error output and fix the Swift files immediately before reporting back to the user.
2. **NSColor Constructors**: Do not use `NSColor(hex: ...)` since it is not natively supported in standard AppKit without an extension. Instead, explicitly use `NSColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)`.
3. **Refactoring Mechanics**: 
   - Avoid writing long, error-prone standalone Python script patches (`patch_py.py`) to swap out Swift code blocks.
   - Rely directly on VS Code's `replace_string_in_file` tool to manipulate exact file strings. If the string is too long or spaces are inconsistent, use explicit `sed` or standard bash utilities with cautious exact line numbers, but primarily lean on exact replace bounds.

