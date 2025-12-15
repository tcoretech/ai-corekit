#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
import yaml
from pathlib import Path
from typing import Dict, List, Any, Optional

# Configuration
PROJECT_ROOT = Path("/root/ai-launchkit")
CONFIG_DIR = PROJECT_ROOT / "config"
STACKS_DIR = CONFIG_DIR / "stacks"
CUSTOM_STACKS_DIR = STACKS_DIR / "custom"
SERVICES_FILE = CONFIG_DIR / "services.json"
GLOBAL_ENV_FILE = CONFIG_DIR / "global.env"

def load_services() -> Dict[str, Any]:
    if not SERVICES_FILE.exists():
        print(f"Error: {SERVICES_FILE} not found. Run migration first.")
        sys.exit(1)
    with open(SERVICES_FILE, "r") as f:
        return json.load(f)

def save_services(services: Dict[str, Any]):
    with open(SERVICES_FILE, "w") as f:
        json.dump(services, f, indent=2)

def load_stack(stack_name: str) -> Dict[str, Any]:
    base_stack_file = STACKS_DIR / f"{stack_name}.yaml"
    custom_stack_file = CUSTOM_STACKS_DIR / f"{stack_name}.yaml"
    
    stack_data = {}
    
    # 1. Load Base Stack (if exists)
    if base_stack_file.exists():
        with open(base_stack_file, "r") as f:
            stack_data = yaml.safe_load(f) or {}
    
    # 2. Load Custom Stack (if exists)
    if custom_stack_file.exists():
        with open(custom_stack_file, "r") as f:
            custom_data = yaml.safe_load(f) or {}
            
            # Merge Logic
            if not stack_data:
                # If no base stack, custom is the stack
                stack_data = custom_data
            else:
                # Additive Merge
                print(f"Merging custom stack configuration for '{stack_name}'...")
                
                # Override project_name if present
                if "project_name" in custom_data:
                    stack_data["project_name"] = custom_data["project_name"]
                
                # Add services (avoid duplicates)
                base_services = set(stack_data.get("services", []))
                custom_services = custom_data.get("services", [])
                for s in custom_services:
                    if s not in base_services:
                        stack_data.setdefault("services", []).append(s)

    if not stack_data:
        print(f"Error: Stack '{stack_name}' not found in {STACKS_DIR} or {CUSTOM_STACKS_DIR}")
        sys.exit(1)
        
    return stack_data

def get_stack_services(stack_data: Dict[str, Any], services_data: Dict[str, Any]) -> List[str]:
    """Return list of services in the stack that are ENABLED in services.json"""
    stack_services = stack_data.get("services", [])
    enabled_services = []
    for service in stack_services:
        if service not in services_data:
            print(f"Warning: Service '{service}' in stack but not in services.json")
            continue
        if services_data[service].get("enabled", False):
            enabled_services.append(service)
    return enabled_services

def generate_compose_command(services_list: List[str], services_data: Dict[str, Any], project_name: str, cmd_type: str = "up"):
    compose_files = []
    seen_paths = set()
    
    for service in services_list:
        meta = services_data.get(service)
        if not meta: continue
            
        # Path in config is relative to PROJECT_ROOT
        compose_file = PROJECT_ROOT / meta["path"]
        path_str = str(compose_file)
        
        if compose_file.exists():
            if path_str not in seen_paths:
                compose_files.extend(["-f", path_str])
                seen_paths.add(path_str)
        else:
            print(f"Warning: Compose file for {service} not found at {compose_file}")

    if not compose_files:
        print("No services enabled or found for this stack.")
        return None

    # Base command
    cmd = ["docker", "compose", "-p", project_name, "--project-directory", str(PROJECT_ROOT)] + compose_files
    
    if cmd_type == "up":
        cmd.extend(["up", "-d", "--remove-orphans"])
    elif cmd_type == "pull":
        cmd.extend(["pull"])
    elif cmd_type == "config":
        cmd.extend(["config"])
    elif cmd_type == "down":
        cmd.extend(["down"])
        
    return cmd

def run_stack_command(stack_name: str, command: str, dry_run: bool):
    services_data = load_services()
    stack_data = load_stack(stack_name)
    project_name = stack_data.get("project_name", "localai")
    
    target_services = get_stack_services(stack_data, services_data)
    
    if not target_services:
        print(f"No enabled services found in stack '{stack_name}'.")
        return

    print(f"Running '{command}' on stack '{stack_name}' (Project: {project_name})")
    print(f"Services: {', '.join(target_services)}")
    
    cmd = generate_compose_command(target_services, services_data, project_name, command)
    if not cmd:
        return

    print("Generated Command:")
    print(" ".join(cmd))
    
    if not dry_run:
        # Load global env vars
        env = os.environ.copy()
        env["PROJECT_ROOT"] = str(PROJECT_ROOT)  # Inject PROJECT_ROOT
        
        # 1. Load Global Env
        if GLOBAL_ENV_FILE.exists():
            with open(GLOBAL_ENV_FILE, "r") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        key, val = line.split("=", 1)
                        val = val.strip().strip('"').strip("'")
                        env[key] = val

        # 2. Load Local Envs for ALL enabled services
        for service in target_services:
            meta = services_data.get(service)
            if not meta: continue
            
            compose_path = PROJECT_ROOT / meta["path"]
            service_dir = compose_path.parent
            service_env_path = service_dir / ".env"
            
            if service_env_path.exists():
                with open(service_env_path, "r") as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith("#") and "=" in line:
                            key, val = line.split("=", 1)
                            val = val.strip().strip('"').strip("'")
                            env[key] = val
            
            # 3. Run Init Script (if exists and command is 'up')
            if command == "up":
                init_script = service_dir / "init.sh"
                if init_script.exists() and os.access(init_script, os.X_OK):
                    print(f"Running init script for {service}...")
                    subprocess.run([str(init_script)], env=env, cwd=service_dir, check=False)

        subprocess.run(cmd, env=env, cwd=PROJECT_ROOT)

        # 4. Run Finalize Script (if exists and command is 'up')
        if command == "up":
            for service in target_services:
                meta = services_data.get(service)
                if not meta: continue
                
                compose_path = PROJECT_ROOT / meta["path"]
                service_dir = compose_path.parent
                finalize_script = service_dir / "finalize.sh"
                
                if finalize_script.exists() and os.access(finalize_script, os.X_OK):
                    print(f"Running finalize script for {service}...")
                    subprocess.run([str(finalize_script)], env=env, cwd=service_dir, check=False)

def list_services(args):
    services = load_services()
    print(f"{'Service':<30} {'Enabled':<10} {'Description'}")
    print("-" * 100)
    for service in sorted(services.keys()):
        data = services[service]
        enabled = "YES" if data.get("enabled") else "NO"
        desc = data.get("description", "")[:60]
        print(f"{service:<30} {enabled:<10} {desc}")

def enable_service(args):
    services = load_services()
    if args.service not in services:
        print(f"Service '{args.service}' not found.")
        return
    services[args.service]["enabled"] = True
    save_services(services)
    print(f"Service '{args.service}' enabled. Run 'launchkit up <stack>' to apply.")

def disable_service(args):
    services = load_services()
    if args.service not in services:
        print(f"Service '{args.service}' not found.")
        return
    services[args.service]["enabled"] = False
    save_services(services)
    print(f"Service '{args.service}' disabled. Run 'launchkit up <stack>' to apply.")

def main():
    parser = argparse.ArgumentParser(description="AI LaunchKit CLI")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # Up
    up_parser = subparsers.add_parser("up", help="Start a stack")
    up_parser.add_argument("stack", nargs="?", default="core", help="Stack name (default: core)")
    up_parser.add_argument("--dry-run", action="store_true", help="Show command without running")
    
    # Down
    down_parser = subparsers.add_parser("down", help="Stop a stack")
    down_parser.add_argument("stack", nargs="?", default="core", help="Stack name (default: core)")
    down_parser.add_argument("--dry-run", action="store_true", help="Show command without running")

    # Pull
    pull_parser = subparsers.add_parser("pull", help="Pull images for a stack")
    pull_parser.add_argument("stack", nargs="?", default="core", help="Stack name (default: core)")
    pull_parser.add_argument("--dry-run", action="store_true", help="Show command without running")

    # List
    subparsers.add_parser("list", help="List all services")
    
    # Enable
    enable_parser = subparsers.add_parser("enable", help="Enable a service")
    enable_parser.add_argument("service", help="Service name")
    
    # Disable
    disable_parser = subparsers.add_parser("disable", help="Disable a service")
    disable_parser.add_argument("service", help="Service name")
    
    # Refresh (Legacy alias)
    refresh_parser = subparsers.add_parser("refresh", help="Alias for 'up core'")
    refresh_parser.add_argument("--dry-run", action="store_true", help="Show command without running")

    args = parser.parse_args()
    
    if args.command == "up":
        run_stack_command(args.stack, "up", args.dry_run)
    elif args.command == "down":
        run_stack_command(args.stack, "down", args.dry_run)
    elif args.command == "pull":
        run_stack_command(args.stack, "pull", args.dry_run)
    elif args.command == "refresh":
        run_stack_command("core", "up", args.dry_run)
    elif args.command == "list":
        list_services(args)
    elif args.command == "enable":
        enable_service(args)
    elif args.command == "disable":
        disable_service(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
