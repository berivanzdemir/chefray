import os
import re

TARGET_DIRS = [
    r"c:\Users\USER\OneDrive\Desktop\ChefRayy\lib",
]

REPLACEMENTS = [
    (r'Theme\.of\(context\)\.colorScheme\.primaryDark', r'AppColors.primaryDark'),
    (r'Theme\.of\(context\)\.colorScheme\.primaryLight', r'AppColors.primaryLight'),
    (r'Theme\.of\(context\)\.colorScheme\.primaryGlow', r'AppColors.primaryGlow'),
    (r'Theme\.of\(context\)\.colorScheme\.primaryGradient', r'AppColors.primaryGradient'),
]

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    for pattern, replacement in REPLACEMENTS:
        content = re.sub(pattern, replacement, content)
        
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
