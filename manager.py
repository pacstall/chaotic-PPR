#!/usr/bin/env python3

import os
import sys
import yaml
import json
import itertools
import requests
import argparse

class LiteralString(str): pass
yaml.add_representer(LiteralString, lambda dumper, data: dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|"))

DATABASE_FILE = "packages.json"

valid_distros = [
    "main",
    "ubuntu-latest", "ubuntu-rolling", "ubuntu-devel",
    "debian-stable", "debian-testing", "debian-unstable"
]

valid_architectures = ["all", "any", "amd64", "arm64"]

def adjust_architectures(architectures):
    if "any" in architectures:
        return ["amd64", "arm64"]
    return architectures

def load_database():
    if os.path.exists(DATABASE_FILE):
        with open(DATABASE_FILE, "r") as f:
            return json.load(f)
    return {}

def save_database(data):
    with open(DATABASE_FILE, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")

def remove_package(name):
    data = load_database()
    if name in data:
        del data[name]
        save_database(data)
        workflow_file = f"workflows/pkg-{name}.yml"
        if os.path.exists(workflow_file):
            os.remove(workflow_file)
        print(f"Package '{name}' removed successfully.")
    else:
        print(f"Package '{name}' not found in {DATABASE_FILE}.")

def list_package(name, details):
    print(f"Name: {name}")
    print(f"  Distros: {', '.join(details['distros'])}")
    print(f"  Architectures: {', '.join(details['architectures'])}")
    print(f"  Max Overflow: {details['maxOverflow']}")
    print(f"  Last Updated: {details['lastUpdatedAt']}")

def list_packages():
    data = load_database()
    if not data:
        print("No packages found.")
        sys.exit(1)

    for name, details in data.items():
        list_package(name, details)

def gen_workflow(package_name, package_data):
    os.makedirs("workflows", exist_ok=True)
    distros = package_data["distros"]
    architectures = adjust_architectures(package_data["architectures"])
    overflow = package_data["maxOverflow"]
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
                            f"REMOTE_PORT=${{{{ secrets.APTLY_PORT }}}}\n"
                            f"REPO_URL=\"http://localhost:${{LOCAL_PORT}}/api/repos/ppr-${{{{ matrix.distro }}}}/packages\"\n"
                            f"ssh -i ~/.ssh/id_ed25519 -fN -L ${{LOCAL_PORT}}:localhost:${{REMOTE_PORT}} \"${{LOCATION}}\"\n"
                            f"rm_str=\"$(./scripts/checker.sh overflow {package_name} ${{{{ matrix.distro }}}} ${{{{ matrix.architecture }}}} {overflow} ${{REPO_URL}})\"\n"
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
    output_file = f"workflows/pkg-{package_name}.yml"
    with open(output_file, "w") as f:
        f.write(yaml_str)

    print(f"Generated: {output_file}")

def gen_workflows():
    packages = load_database()
    for package_name, package_data in packages.items():
        gen_workflow(package_name, package_data)

def get_api_data(pkg_name):
    response = requests.get(f"https://pacstall.dev/api/packages/{pkg_name}")
    if response.status_code != 200:
        raise ValueError(f"Failed to fetch data for package '{pkg_name}'")

    api_data = response.json()
    last_updated = api_data.get("lastUpdatedAt")
    archopts = api_data.get("architectures")

    archarr = []
    if "arm64" in archopts or "aarch64" in archopts:
        archarr.append("arm64")
    if "amd64" in archopts or "x86_64" in archopts:
        archarr.append("amd64")
    if "all" in archopts:
        archarr = ["all"]
    elif "any" in archopts:
        archarr = ["any"] + adjust_architectures(archopts)

    return last_updated, archarr

def alter_package(name, distros, architectures, overflow=5):
    data = load_database()
    package_exists = name in data
    if not package_exists:
        missing = 0
        if distros is None:
            missing = 1
            print(f"Error: missing 'distros'")
        if architectures is None:
            missing = 1
            print(f"Error: missing 'architectures'")
        if (missing == 1):
            return
    if (overflow < 1):
        print(f"Error: 'overflow' must be 1 or greater")
        return

    if package_exists:
        current_data = data[name]
        distros = distros or current_data["distros"]
        architectures = architectures or current_data["architectures"]
        overflow = overflow or current_data["maxOverflow"]

    try:
        last_updated, available_architectures = get_api_data(name)
    except ValueError as e:
        print(e)
        return

    for arch in architectures:
        if arch not in available_architectures:
            print(f"Error: '{arch}' is not supported by package '{name}'\nSupported architectures: {', '.join(available_architectures)}")
            sys.exit(1)

    if 'any' in architectures:
        architectures = ['any']

    data[name] = {
        "distros": distros,
        "architectures": architectures,
        "maxOverflow": overflow,
        "lastUpdatedAt": last_updated,
    }

    save_database(data)
    list_package(name, data[name])
    gen_workflow(name, data[name])
    action = "updated" if package_exists else "added"
    print(f"Package has been {action} successfully.")

def add_command(subparsers, name, aliases, help_text, arguments):
    handler = globals().get(f"handle_{name}")
    if handler is None:
        print(f"Error: No handler defined for command '{name}'")
        return
    parser = subparsers.add_parser(name, help=f"{help_text} {{aliases: {'|'.join(aliases)}}}")
    for arg_name, arg_kwargs in arguments.items():
        parser.add_argument(arg_name, **arg_kwargs)
    parser.set_defaults(func=handler)

    for alias in aliases:
        parser = subparsers.add_parser(alias)
        for arg_name, arg_kwargs in arguments.items():
            parser.add_argument(arg_name, **arg_kwargs)
        parser.set_defaults(func=handler)

def handle_add(args):
    if args.distros:
        distros = [d.strip() for d in args.distros.split(",")]
        invalid_distros = [d for d in distros if d not in valid_distros]
        if invalid_distros:
            print(f"Error: Invalid distros given: {', '.join(invalid_distros)}")
            print(f"Valid distros are: {', '.join(valid_distros)}")
            return
    else:
        distros = None

    if args.architectures:
        architectures = [a.strip() for a in args.architectures.split(",")]
        invalid_architectures = [a for a in architectures if a not in valid_architectures]
        if invalid_architectures:
            print(f"Error: Invalid architectures given: {', '.join(invalid_architectures)}")
            print(f"Valid architectures are: {', '.join(valid_architectures)}")
            return
        if 'any' in architectures and 'all' in architectures:
            print(f"Error: 'any' and 'all' are mutually exclusive.")
            return
    else:
        architectures = None

    alter_package(args.name, distros, architectures, args.overflow)

def handle_remove(args):
    remove_package(args.name)

def handle_list(args):
    list_packages()

def handle_generate(args):
    print("Working...")
    gen_workflows()
    print("Done.")

def main():
    parser = argparse.ArgumentParser(description="PPR Manager")
    subparsers = parser.add_subparsers(dest="command", required=True, metavar='{add|remove|list|generate}')
    add_command(
        subparsers,
        name="add",
        aliases=["a", "e", "edit"],
        help_text="Add or edit a package",
        arguments={
            "name": {
                "help": "Package name"
            },
            "-d": {
                "help": "Comma-separated list of distros (e.g., ubuntu-latest,debian-stable)",
                "default": None,
                "dest": "distros"
            },
            "-a": {
                "help": "Comma-separated list of architectures (e.g., amd64,arm64)",
                "default": None,
                "dest": "architectures"
            },
            "-o": {
                "help": "Integer value of the overflow limit (default 5)",
                "type": int,
                "default": 5,
                "dest": "overflow"
            },
        },
    )
    add_command(
        subparsers,
        name="remove",
        aliases=["r", "rm"],
        help_text="Remove a package",
        arguments={
            "name": {
                "help": "Package name"
            },
        },
    )

    add_command(
        subparsers,
        name="list",
        aliases=["l"],
        help_text="List all packages",
        arguments={},
    )

    add_command(
        subparsers,
        name="generate",
        aliases=["g", "gen"],
        help_text="Generate workflows for all packages",
        arguments={},
    )

    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
