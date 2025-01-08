#!/usr/bin/env python3

import os
import sys
import yaml
import json
import itertools
import requests
import argparse

DATABASE_FILE = "packages.json"

def load_database():
    if os.path.exists(DATABASE_FILE):
        with open(DATABASE_FILE, "r") as f:
            return json.load(f)
    return {}

def save_database(data):
    with open(DATABASE_FILE, "w") as f:
        json.dump(data, f, indent=4)

def remove_package(name):
    data = load_database()
    if name in data:
        del data[name]
        save_database(data)
        print(f"Package '{name}' removed successfully.")
    else:
        print(f"Package '{name}' not found in {DATABASE_FILE}.")

def list_packages():
    data = load_database()
    if not data:
        print("No packages found.")
        sys.exit(1)

    for name, details in data.items():
        print(f"Name: {name}")
        print(f"  Distros: {', '.join(details['distros'])}")
        print(f"  Architectures: {', '.join(details['architectures'])}")

def literal_representer(dumper, data):
    return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")

def adjust_architectures(architectures):
    if architectures[0] == "any":
        return ["amd64", "arm64"]
    return architectures

def gen_workflows():
    with open(DATABASE_FILE, "r") as f:
        packages = json.load(f)

    os.makedirs("workflows", exist_ok=True)
    class LiteralString(str): pass

    yaml.add_representer(LiteralString, literal_representer)

    for package_name, package_data in packages.items():
        distros = package_data["distros"]
        architectures = adjust_architectures(package_data["architectures"])

        matrix_combinations = [
            {"distro": distro, "architecture": arch}
            for distro, arch in itertools.product(distros, architectures)
        ]

        workflow_template = {
            "name": f"{package_name}",
            "on": {
                "repository_dispatch": {
                    "types": [
                        f"{package_name}"
                    ]
                },
                "workflow_dispatch": {}
            },
            "jobs": {
                "build": {
                    "runs-on": "ubuntu-latest",
                    "strategy": {
                        "matrix": {
                            "include": matrix_combinations
                        }
                    },
                    "steps": [
                        {
                            "name": "Init",
                            "uses": "actions/checkout@v4"
                        },
                        {
                            "name": "Set up QEMU",
                            "uses": "docker/setup-qemu-action@v3"
                        },
                        {
                            "name": "Set up SSH key",
                            "run": LiteralString(
                                f"mkdir -p ~/.ssh\n"
                                f"echo \"${{{{ secrets.SSH_KEY }}}}\" > ~/.ssh/id_ed25519\n"
                                f"chmod 600 ~/.ssh/id_ed25519\n"
                                f"ssh-keyscan -H \"${{{{ secrets.SSH_IP }}}}\" >> ~/.ssh/known_hosts"
                            )
                        },
                        {
                            "name": "Package",
                            "run": LiteralString(
                                f"mkdir -p out && cd out\n"
                                f"m_name=\"{package_name}\"\n"
                                f"m_dist=\"${{{{ matrix.distro }}}}\"\n"
                                f"m_arch=\"${{{{ matrix.architecture }}}}\"\n"
                                f"../scripts/packer.sh \"${{m_name}}\" \"${{m_dist}}\" \"${{m_arch}}\"\n"
                                "debfile=(*${m_arch}.deb)\n"
                                "echo \"DEBNAME=${debfile}\" >> $GITHUB_ENV"
                            )
                        },
                        {
                            "name": "Upload .deb files",
                            "uses": "actions/upload-artifact@v4",
                            "with": {
                                "name": "${{ env.DEBNAME }}@${{ matrix.distro }}",
                                "path": "out/${{ env.DEBNAME }}"
                            }
                        },
                        {
                            "name": "Upload to server",
                            "run": LiteralString(
                                f"LOCATION=\"${{{{ secrets.SSH_USER }}}}@${{{{ secrets.SSH_IP }}}}\"\n"
                                f"LOCAL_PORT=8080\n"
                                f"REMOTE_PORT=8088\n"
                                f"REPO_URL=\"http://localhost:${{LOCAL_PORT}}/api/repos/ppr-${{{{ matrix.distro }}}}/packages\"\n"
                                f"ssh -i ~/.ssh/id_ed25519 -fN -L ${{LOCAL_PORT}}:localhost:${{REMOTE_PORT}} \"${{LOCATION}}\"\n"
                                f"rm_str=\"$(./scripts/overflow.sh {package_name} ${{{{ matrix.distro }}}} ${{{{ matrix.architecture }}}} 5 ${{REPO_URL}})\"\n"
                                f"if [ -n \"${{rm_str}}\" ]; then\n  echo \"Removing ${{rm_str}}...\"\n"
                                f"  curl -X DELETE -H 'Content-Type: application/json' --data \"{{\\\"PackageRefs\\\": [${{rm_str}}]}}\" \"${{REPO_URL}}\" | jq\nfi\n"
                                f"curl -X POST -F file=@out/${{{{ env.DEBNAME }}}} \"http://localhost:${{LOCAL_PORT}}/api/files/${{{{ matrix.distro }}}}\" | jq\n"
                                f"curl -s -X POST -H 'Content-Type: application/json' \\\n"
                                f"  \"http://localhost:${{LOCAL_PORT}}/api/repos/ppr-${{{{ matrix.distro }}}}/file/${{{{ matrix.distro }}}}?forceReplace=1\" | jq\n"
                                f"curl -X PUT -H 'Content-Type: application/json' --data '{{\"Signing\": {{\"Skip\": false, \"GpgKey\": \"${{{{ secrets.GPG_KEY }}}}\"}}, \"MultiDist\": true, \"ForceOverwrite\": true}}' \"http://localhost:${{LOCAL_PORT}}/api/publish/pacstall/pacstall\" | jq\n"
                            )
                        }
                    ]
                }
            }
        }

        yaml_str = yaml.dump(workflow_template, sort_keys=False, default_flow_style=False)
        yaml_str = yaml_str.replace("run: |-", "run: |")
        output_file = f"workflows/{package_name}.yml"
        with open(output_file, "w") as f:
            f.write(yaml_str)

        print(f"Generated {output_file}")

def get_architectures_from_api(pkg_name):
    response = requests.get(f"https://pacstall.dev/api/packages/{pkg_name}")
    if response.status_code != 200:
        raise ValueError(f"Failed to fetch data for package '{pkg_name}'")

    archopts = response.json().get("architectures", [])

    archarr = []
    if "arm64" in archopts or "aarch64" in archopts:
        archarr.append("arm64")
    if "amd64" in archopts or "x86_64" in archopts:
        archarr.append("amd64")
    if "all" in archopts:
        archarr = ["all"]
    elif "any" in archopts:
        archarr = ["amd64", "arm64"]

    return archarr

def add_or_update_package(name, distros, architectures):
    data = load_database()
    try:
        available_architectures = get_architectures_from_api(name)
    except ValueError as e:
        print(e)
        return

    for arch in architectures:
        if arch not in available_architectures and "all" not in available_architectures:
            print(f"Error: '{arch}' is not supported by package '{name}'\nSupported architectures: {', '.join(available_architectures)}")
            if arch == 'any':
                print("Note: 'any' packages must specify each arch to build")
            sys.exit(1)

    data[name] = {
        "distros": distros,
        "architectures": architectures
    }

    save_database(data)
    print(f"Package '{name}' has been added/updated successfully.")

def main():
    valid_distros = [
        "main", "ubuntu-latest", "ubuntu-rolling", "ubuntu-devel",
        "debian-stable", "debian-testing", "debian-unstable"
    ]
    
    valid_architectures = ["all", "any", "amd64", "arm64"]

    parser = argparse.ArgumentParser(description="PPR Manager")
    subparsers = parser.add_subparsers(dest="command", required=True)

    add_parser = subparsers.add_parser("add", help="Add or edit a package")
    add_parser.add_argument("name", help="Package name")
    add_parser.add_argument("-d", "--distros", required=True,
                            help="Comma-separated list of distros (e.g., ubuntu-latest,debian-stable)")
    add_parser.add_argument("-a", "--architectures", required=True,
                            help="Comma-separated list of architectures (e.g., amd64,arm64)")

    remove_parser = subparsers.add_parser("remove", help="Remove a package")
    remove_parser.add_argument("name", help="Package name")

    subparsers.add_parser("list", help="List all packages")

    subparsers.add_parser("generate", help="Generate workflows for all packages")

    args = parser.parse_args()

    if args.command == "add":
        distros = [d.strip() for d in args.distros.split(",")]
        invalid_distros = [d for d in distros if d not in valid_distros]
        if invalid_distros:
            print(f"Error: Invalid distros given: {', '.join(invalid_distros)}")
            print(f"Valid distros are: {', '.join(valid_distros)}")
            return

        architectures = [a.strip() for a in args.architectures.split(",")]
        invalid_architectures = [a for a in architectures if a not in valid_architectures]
        if invalid_architectures:
            print(f"Error: Invalid architectures given: {', '.join(invalid_architectures)}")
            print(f"Valid architectures are: {', '.join(valid_architectures)}")
            return

        add_or_update_package(args.name, distros, architectures)

    elif args.command == "remove":
        remove_package(args.name)

    elif args.command == "list":
        list_packages()

    elif args.command == "generate":
        print("Working...")
        gen_workflows()
        print("Done.")

if __name__ == "__main__":
    main()