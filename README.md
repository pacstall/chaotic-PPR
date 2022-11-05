![PPR name](https://user-images.githubusercontent.com/58742515/199145376-027e5e44-37a7-4e75-bcaf-84981124dbfd.png)

> The Chaotic PPR is a system where Pacstall builds debs from pacscripts and uploads them to an APT repository, meaning that you can enjoy prebuilt pacstall packages without the build times, and you can even use the Chaotic PPR without Pacstall even installed!

### How to create a local instance

#### Setting the base repository location
First, make sure you have cloned the repo, and you are inside it. Then run `export PPR_BASE=$PWD/ppr-base` and save that somewhere important. Next, run `./scripts/init.sh`.

#### Creating the sftp password
Edit the file `.env`, and add the following information:
```bash
SFTP_PASS="MyComplexPassword"
```

#### Creating GPG keys
Run:
```bash
mkdir -p "$PPR_BASE"
cd "$PPR_BASE" && cd ..
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
cp "$PPR_BASE/ppr.pub" "$PWD"
gpg --armor --export-secret-keys "PPR" > "$PWD/private-ppr.txt"
```

#### Setting the default packagelist
To specify packages to be created on the docker containers first startup, edit the file `$PPR_BASE/default-packagelist`. You must specify valid package names separated by newlines.

#### Creating docker image
Run:
```bash
docker-compose up --build --force-recreate
```

#### Adding to apt
Run
```bash
curl -s localhost/ppr.pub | gpg --dearmor | sudo tee /usr/share/keyrings/ppr.gpg 1> /dev/null
echo "deb [signed-by=/usr/share/keyrings/ppr.gpg] http://127.0.0.1 pacstall main" | sudo tee /etc/apt/sources.list.d/chaotic-ppr.list
sudo apt-get update
```

#### Adding packages
When you want to add a deb package from your host system into the PPR, you must build it using `pacstall -PBI`, then rename the package to the following scheme: `${name}_${version}-1_amd64.deb`.

Then run the following to upload:
```bash
sshpass -p "password_from_env_file" sftp -P 420 sftp-pacstall@localhost <<EOF
put /my/super/special.deb /upload/pool/main/
EOF
```

The Chaotic PPR will automatically trigger the apt repository metadata rebuild for you.

Then all thats left is to wait for the package to be processed!

#### Consquent runs
Run `docker-compose up`.
