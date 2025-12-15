import json
import os
import subprocess
import sys
from pathlib import Path

def load_env_file(env_path):
    if not os.path.exists(env_path):
        return
    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' in line:
                key, value = line.split('=', 1)
                # Remove quotes if present
                if (value.startswith('"') and value.endswith('"')) or                    (value.startswith("'") and value.endswith("'")):
                    value = value[1:-1]
                os.environ[key] = value

def main():
    project_root = Path(__file__).parent.parent.absolute()
    env_file = project_root / '.env'
    services_file = project_root / 'config' / 'services.json'
    utils_path = project_root / 'scripts' / 'utils.sh'
    
    load_env_file(env_file)
    
    if not services_file.exists():
        print(f"Error: {services_file} not found")
        sys.exit(1)

    with open(services_file, 'r') as f:
        services = json.load(f)
        
    # Get active profiles from COMPOSE_PROFILES
    compose_profiles = os.environ.get('COMPOSE_PROFILES', '')
    active_profiles = [p.strip() for p in compose_profiles.split(',') if p.strip()]
    
    # Iterate over services
    for profile, config in services.items():
        # Check if profile is active
        if profile in active_profiles:
            # Get directory from path
            compose_path = config.get('path')
            if not compose_path:
                continue
                
            service_dir = (project_root / compose_path).parent
            report_script = service_dir / 'report.sh'
            
            if report_script.exists():
                # Run the report script
                # We source utils.sh first to make helper functions available
                cmd = f'source "{utils_path}" && source "{report_script}"'
                
                # Run with bash
                subprocess.run(['bash', '-c', cmd], env=os.environ, check=False)

if __name__ == "__main__":
    main()
