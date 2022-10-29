# Chaotic PPR

### How to create a local instance

#### Setting the base repository location
First, run `export PPR_BASE=<wherever you want to store packages>` and save that somewhere important.

#### Generating the repository
Run `./scripts/init.sh`. This will generate a basic apt repo structure.

#### Adding packages
Run `./scripts/add-package.sh <list of packages>`.
