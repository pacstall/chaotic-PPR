## Setup

Requirements:
- `aptly`
- `apache2`
- `certbot`
- `python3-certbot-apache`

Jumpstart (only for the main host):
```bash
git clone https://github.com/pacstall/chaotic-PPR.git
cd chaotic-PPR

# set up the user for hosting
mkdir -p ~/.aptly/public
sed -i "s/\${USER}/${USER}/g" aptly-api.service apache2/aptly.conf
chmod -R o+r ~/.aptly/public
chmod o+x ~/
chmod o+x ~/.aptly
cp ppr-public-key.asc ~/.aptly/public

# enable and start aptly api
sudo cp aptly-api.service /etc/systemd/system/
sudo systemctl enable --now aptly-api

# enable and start apache forwarding
sudo cp apache2/aptly.conf /etc/apache2/sites-available/aptly.conf
sudo a2ensite aptly.conf
sudo systemctl reload apache2
sudo systemctl enable apache2 --now
sudo certbot --apache -d ppr.pacstall.dev
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# set up aptly repos
./scripts/creator.sh
```
Then, set the following repository secrets for GitHub Actions:
- generate an ssh keygen pair and set `SSH_USER`, `SSH_IP`, and `SSH_KEY`
- get the `keyid` from `ppr-public-key.asc` and set it to `GPG_KEY`

The main server is now set up and ready to accept and publish packages.

To set up the landing page, create a static build from https://github.com/pacstall/chaotic-ppr-landing, and place the files in `~/.aptly/public`.

Installation (for mirrors):
```bash
WIP
```

## Management

Currently using `manager.py`. Type `python3 manager.py {command} -h` for usage tips.
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





