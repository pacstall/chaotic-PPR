![PPR name](https://user-images.githubusercontent.com/58742515/199145376-027e5e44-37a7-4e75-bcaf-84981124dbfd.png)

> The Chaotic PPR is a system where Pacstall builds debs from pacscripts and uploads them to an APT repository, meaning that you can enjoy prebuilt pacstall packages without the build times, and you can even use the Chaotic PPR without Pacstall installed!

### How to create a local instance

<details>
<summary>How the PPR is structured</summary>

##### Containers
The PPR uses three docker containers to function:

* The `apt-repo` container, which is in charge of holding the repo contents, and generating the repo metadata.

* The `web` container which is an nginx server for viewing the repository. It is available on port `80`.

* The `sftp` container which is in charge of modifying the repository, primarily uploading packages to the server. It is available on port `420`.

##### Scripts
* `add-package.sh` is in charge of building the default packagelist into the repository on first run.

* `generate-release.sh` is in charge of generating the `Release` file structure, including checksums of packages.

* `rm-old.sh` is in charge of finding and removing old packages from the repository.

* `setup.sh` is in charge of setting up the initial repository and is an entrypoint that the `apt-repo` container will run on startup. If the repository has not been initialized, it will create one, and if it has, it will run `wait.sh`.

* `wait.sh` will detect modification, moves, creations, and deletions of files in `$PPR_BASE/pool/main/`, and will update the repository metadata and trigger `rm-old.sh`.

</details>

#### Setting the base repository location
First, make sure you have cloned the repo, and you are inside it. Then run `export PPR_BASE=$PWD/ppr-base` and save that somewhere important.

#### Creating the sftp password
Edit the file `.env`, and add the following information:
```bash
SFTP_PASS="MyComplexPassword"
```
#### Creating the SSH keys
In order to prevent the `sftp` container from regenerating ssh keys every time it starts, we must provide our own. This can also be used to verify the servers authenticity. Run:
```bash
mkdir -p sftp-keys/share/
cd sftp-keys/
ssh-keygen -t ed25519 -f ssh_host_ed25519_key < /dev/null
ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key < /dev/null
```

#### Creating GPG keys
Run:
```bash
mkdir -p "$PPR_BASE"
chmod 777 "$PPR_BASE"
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
#### Setting the default packagelist (*optional*)
To specify packages to be created on the docker containers first startup, edit the file `$PPR_BASE/default-packagelist`. You must specify valid package names separated by newlines. If you do not specify any packages to be added, the PPR will add `neofetch` by default.

#### Creating docker image
Run:
```bash
docker-compose up --build --force-recreate
```

#### Adding to apt
Run
```bash
curl -s localhost/ppr.pub | gpg --dearmor | sudo tee /usr/share/keyrings/ppr.gpg 1> /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/ppr.gpg] http://127.0.0.1 pacstall main" | sudo tee /etc/apt/sources.list.d/chaotic-ppr.list
sudo apt-get update
```

#### Adding packages
When you want to add a deb package from your host system into the PPR, you must build it using `pacstall -PBI`, then rename the package to the following scheme: `${name}_${version}-1_amd64.deb`.

Then run the following to upload:
```bash
sshpass -p "password_from_env_file" sftp -P 420 sftp-pacstall@localhost <<EOF
put /my/super/special.deb /upload/main/
EOF
```

The Chaotic PPR will automatically trigger the apt repository metadata rebuild for you, along with cleaning old versions.

Then all that's left is to wait for the package to be processed!

#### Subsequent runs
Run `docker-compose up`.
