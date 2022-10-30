# Chaotic PPR

### How to create a local instance

#### Setting the base repository location
First, run `export PPR_BASE=<wherever you want to store packages>` and save that somewhere important.

#### Generating the repository
Run `./scripts/init.sh`. This will generate a basic apt repo structure.

#### Adding packages
Run `./scripts/add-package.sh <list of packages>`.

#### Signing the repo
Run `./scripts/generate-pgp.sh`.

#### Adding to apt
Run ```bash
cat "$PPR_BASE/ppr.pub" | gpg --dearmor | sudo tee /usr/share/keyrings/ppr.gpg 1> /dev/null
echo "deb [signed-by=/usr/share/keyrings/ppr.gpg] http://127.0.0.1:8000 pacstall main" | sudo tee /etc/apt/sources.list.d/chaotic-ppr.list
```
