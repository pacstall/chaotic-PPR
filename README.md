# Chaotic PPR

### How to create a local instance

#### Setting the base repository location
First, run `export PPR_BASE=$PWD/ppr-base` and save that somewhere important.

#### Creating GPG keys
Run:
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
gpg --armor --export "PPR" > "$PPR_BASE/ppr.pub"
gpg --armor --export-secret-keys "PPR" > "$PWD/private-ppr.txt"
```

#### Creating docker image
Run:
```bash
docker-compose up --build --force-recreate
```

#### Adding to apt
Run
```bash
curl -s localhost:8000/ppr.pub | gpg --dearmor | sudo tee /usr/share/keyrings/ppr.gpg 1> /dev/null
echo "deb [signed-by=/usr/share/keyrings/ppr.gpg] http://127.0.0.1:8000 pacstall main" | sudo tee /etc/apt/sources.list.d/chaotic-ppr.list
sudo apt-get update
```

#### Consquent runs
Run `docker-compose up`.
