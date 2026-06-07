import os
import re

TARGET_DIRS = [
    r"c:\Users\USER\OneDrive\Desktop\ChefRayy\lib",
]

def remove_const_recursively(text):
    # This regex attempts to find 'const ' followed by a word and a parenthesis, 
    # where inside there is Theme.of(context).
    # It's safer to just remove 'const ' from any line containing Theme.of(context)
    lines = text.split('\n')
    for i, line in enumerate(lines):
        if 'Theme.of(context)' in line and 'const ' in line:
            lines[i] = line.replace('const ', '')
    return '\n'.join(lines)

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # Fix prefix regex mistakes
    content = content.replace('Theme.of(context).scaffoldBackgroundColorWhite', 'Theme.of(context).colorScheme.surface')
    content = content.replace('Theme.of(context).scaffoldBackgroundColorMint', 'AppColors.backgroundMint') # Wait, mint wasn't in REPLACEMENTS but just in case
    content = content.replace('Theme.of(context).scaffoldBackgroundColorCard', 'Theme.of(context).colorScheme.surface')
    
    # Fix undefined context
    # Usually undefined context happens if it's assigned to a property outside of build
    # I will just revert Theme.of(context) in those specific files manually if needed, 
    # but let's first fix all 'const ' issues in the file.
    
    # Actually, we can remove 'const ' that appears before Theme.of(context) in the same line
    content = remove_const_recursively(content)
        
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated: {file_path}")

def main():
    for d in TARGET_DIRS:
        if not os.path.exists(d):
            continue
        for root, _, files in os.walk(d):
            for file in files:
                if file.endswith('.dart'):
                    process_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
