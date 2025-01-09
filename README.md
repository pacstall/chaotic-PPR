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
sed -i "s/\${USER}/${USER}/g" server/systemd/aptly-api.service server/apache2/aptly.conf
chmod -R o+r ~/.aptly/public
chmod o+x ~/
chmod o+x ~/.aptly
cp server/ppr-public-key.asc ~/.aptly/public

# enable and start aptly api
sudo cp server/systemd/aptly-api.service /etc/systemd/system/
sudo systemctl enable --now aptly-api

# enable and start apache forwarding
sudo cp server/apache2/aptly.conf /etc/apache2/sites-available/aptly.conf
sudo a2ensite aptly.conf
sudo systemctl reload apache2
sudo systemctl enable apache2 --now
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo certbot --apache -d ppr.pacstall.dev

# set up aptly repos
./scripts/creator.sh
```
Then, set the following repository secrets for GitHub Actions:
- generate an ssh keygen pair and set `SSH_USER`, `SSH_IP`, and `SSH_KEY`:
  - `SSH_USER` - the host user
  - `SSH_IP` - the IP of the server
  - `SSH_KEY` - the contents of the generated `ppr_ssh_key` file:
```bash
ssh-keygen -t ed25519 -C "github-actions@ppr" -f ppr_ssh_key < /dev/null
cat ppr_ssh_key.pub >> ~/.ssh/authorized_keys
```

- get the `keyid` from `ppr-public-key.asc` and set it to `GPG_KEY`:
```bash
gpg --list-packets ppr-public-key.asc | awk '/keyid: / {print $2}'
```

If the GPG key ever needs to be regenerated:
```bash
echo "%echo Generating PPR PGP key
Key-Type: RSA
Key-Length: 4096
Name-Real: PPR
Name-Email: pacstall@pm.me
Expire-Date: 0
%no-ask-passphrase
%no-protection
%commit" > /tmp/pgp-key.batch
gpg --no-tty --batch --gen-key /tmp/pgp-key.batch
gpg --armor --export "PPR" > ppr-public-key.asc
gpg --armor --export-secret-keys "PPR" > ppr-private-key.asc
```

The main server is now set up and ready to accept and publish packages.

To set up the landing page, create a static build from https://github.com/pacstall/chaotic-ppr-landing, and place the files in `~/.aptly/public`.

Jumpstart (for mirrors):
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





