import os
import re
import sys

# Configuration
SOURCE_ENV = "./.env"
ROOT_DIR = "./"

def parse_env(filepath):
    """
    Parses an env file into a dictionary.
    Returns a dict of {KEY: VALUE}.
    """
    env_vars = {}
    if not os.path.exists(filepath):
        print(f"Warning: Source file {filepath} not found.")
        return env_vars
    
    print(f"Parsing source env: {filepath}")
    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            # Skip comments and empty lines
            if not line or line.startswith('#'):
                continue
            
            # Handle 'export KEY=VALUE'
            if line.startswith('export '):
                line = line[7:]
            
            # Match KEY=VALUE
            match = re.match(r'^([^=]+)=(.*)$', line)
            if match:
                key = match.group(1).strip()
                value = match.group(2).strip()
                
                # Remove surrounding quotes if present
                # We handle single and double quotes
                if (value.startswith('"') and value.endswith('"')) or \
                   (value.startswith("'") and value.endswith("'")):
                    value = value[1:-1]
                
                env_vars[key] = value
    
    return env_vars

def migrate_file(example_path, source_vars):
    """
    Reads .env.example, replaces values from source_vars, and writes to .env.
    """
    # Determine target path
    # config/.env.global.example -> config/.env.global
    # service/.env.example -> service/.env
    target_path = example_path.replace('.example', '')
    
    # Skip if target is the source itself (unlikely given naming, but good safety)
    if os.path.abspath(target_path) == os.path.abspath(SOURCE_ENV):
        print(f"Skipping {target_path} as it is the source file.")
        return

    print(f"Migrating: {os.path.basename(example_path)} -> {os.path.basename(target_path)}")
    
    new_lines = []
    replaced_count = 0
    
    try:
        with open(example_path, 'r') as f:
            for line in f:
                original_line = line
                stripped = line.strip()
                
                # Check if line is a variable assignment
                # We look for KEY=... or export KEY=...
                # We want to preserve indentation if possible, though .env usually doesn't have it.
                
                # Regex to capture the key
                # Matches: KEY=... or export KEY=...
                # Group 1: 'export ' or empty
                # Group 2: KEY
                # Group 3: Everything after =
                match = re.match(r'^(\s*export\s+)?([^=#\s]+)=(.*)$', stripped)
                
                if match:
                    prefix = match.group(1) or ""
                    key = match.group(2).strip()
                    
                    if key in source_vars:
                        val = source_vars[key]
                        # Construct new line
                        # We use double quotes for safety
                        new_line = f'{prefix}{key}="{val}"\n'
                        new_lines.append(new_line)
                        replaced_count += 1
                    else:
                        # Keep original line if key not found in source
                        new_lines.append(original_line)
                else:
                    # Keep comments, empty lines, etc.
                    new_lines.append(original_line)
        
        # Write to target file
        with open(target_path, 'w') as f:
            f.writelines(new_lines)
            
        print(f"  - Created {target_path} ({replaced_count} values migrated)")
        
    except Exception as e:
        print(f"  - Error processing {example_path}: {e}")

def main():
    # 1. Parse Source
    source_vars = parse_env(SOURCE_ENV)
    print(f"Loaded {len(source_vars)} variables from source.")
    
    # 2. Find all .env.example files
    example_files = []
    for root, dirs, files in os.walk(ROOT_DIR):
        # Skip .git and other non-project dirs if necessary
        if '.git' in dirs:
            dirs.remove('.git')
            
        for file in files:
            # Match .env.example OR .env.global.example
            if file.endswith('.env.example') or file == '.env.global.example':
                example_files.append(os.path.join(root, file))
    
    print(f"Found {len(example_files)} example files.")
    
    # 3. Migrate each file
    for example_file in example_files:
        migrate_file(example_file, source_vars)
        
    print("\nMigration complete.")

if __name__ == "__main__":
    main()
