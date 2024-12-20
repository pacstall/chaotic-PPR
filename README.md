![PPR name](https://user-images.githubusercontent.com/58742515/199145376-027e5e44-37a7-4e75-bcaf-84981124dbfd.png)

> The Chaotic PPR is a system where Pacstall builds debs from pacscripts and uploads them to an APT repository, meaning that you can enjoy prebuilt pacstall packages without the build times, and you can even use the Chaotic PPR without Pacstall installed!

## Setup

Requirements:
- `aptly`

Installation:
```bash
git clone https://github.com/pacstall/chaotic-ppr
mkdir -p ~/.aptly

sed -i "s/\${USER}/${USER}/g" ppr/aptly-api.service
sudo cp ppr/aptly-api.service /etc/systemd/system/
sudo systemctl enable --now aptly-api

./ppr/scripts/creator.sh
```
Then, generate a keygen pair and set the `SSH_USER`, `SSH_IP`, and `SSH_KEY` repository secrets in GitHub. The main server is now set up and ready to accept and publish packages.

## Management

Currently using `manager.py`. Run `python3 manager.py {command} -h` for usage tips.
```
positional arguments:
  {add,remove,list,generate}
    add                 Add or edit a package
    remove              Remove a package
    list                List all packages
    generate            Generate workflows for all packages
```

Examples:

```bash
python3 manager.py list

python3 manager.py add ${package} -d ubuntu-latest,debian-stable -a amd64,arm64

python3 manager.py remove ${package}

python3 manager.py generate
```





