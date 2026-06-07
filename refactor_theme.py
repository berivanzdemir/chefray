import os
import re

TARGET_DIRS = [
    r"c:\Users\USER\OneDrive\Desktop\ChefRayy\lib\screens\profile",
    r"c:\Users\USER\OneDrive\Desktop\ChefRayy\lib\screens\home",
    r"c:\Users\USER\OneDrive\Desktop\ChefRayy\lib\screens\recipe_list",
    r"c:\Users\USER\OneDrive\Desktop\ChefRayy\lib\screens\recipe_detail",
    r"c:\Users\USER\OneDrive\Desktop\ChefRayy\lib\screens\cooking_mode",
    r"c:\Users\USER\OneDrive\Desktop\ChefRayy\lib\widgets\common",
]

REPLACEMENTS = [
    (r'AppColors\.background', r'Theme.of(context).scaffoldBackgroundColor'),
    (r'Color\(0xFFF7FBF9\)', r'Theme.of(context).scaffoldBackgroundColor'),
    (r'Color\(0xFFF8F9FA\)', r'Theme.of(context).scaffoldBackgroundColor'),
    
    (r'Colors\.white', r'Theme.of(context).colorScheme.surface'),
    (r'Color\(0xFFFFFFFF\)', r'Theme.of(context).colorScheme.surface'),
    (r'AppColors\.backgroundWhite', r'Theme.of(context).colorScheme.surface'),
    (r'AppColors\.backgroundCard', r'Theme.of(context).colorScheme.surface'),
    
    (r'AppColors\.textDark', r'Theme.of(context).colorScheme.onSurface'),
    (r'Color\(0xFF0D3230\)', r'Theme.of(context).colorScheme.onSurface'),
    
    (r'AppColors\.textLight', r'Theme.of(context).colorScheme.onSurfaceVariant'),
    (r'AppColors\.textMedium', r'Theme.of(context).colorScheme.onSurfaceVariant'),
    (r'Color\(0xFF6F8A88\)', r'Theme.of(context).colorScheme.onSurfaceVariant'),
    
    (r'AppColors\.primary', r'Theme.of(context).colorScheme.primary'),
    (r'Color\(0xFF17C878\)', r'Theme.of(context).colorScheme.primary'),
    
    (r'AppColors\.divider', r'Theme.of(context).dividerColor'),
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
            print(f"Dir not found: {d}")
            continue
        for root, _, files in os.walk(d):
            for file in files:
                if file.endswith('.dart'):
                    process_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
