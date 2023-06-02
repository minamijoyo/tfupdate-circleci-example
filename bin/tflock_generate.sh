#!/bin/bash
set -eo pipefail

# create a plugin cache dir
export TF_PLUGIN_CACHE_DIR="/tmp/terraform.d/plugin-cache"
mkdir -p "${TF_PLUGIN_CACHE_DIR}"

# remove an old lock file before providers mirror command
rm -f .terraform.lock.hcl

# create a local filesystem mirror to avoid duplicate downloads
FS_MIRROR="/tmp/terraform.d/plugins"
terraform providers mirror -platform=linux_amd64 -platform=darwin_amd64 -platform=darwin_arm64 "${FS_MIRROR}"

# update the lock file
ALL_DIRS=$(find . -type f -name '*.tf' | xargs -I {} dirname {} | sort | uniq | grep -v 'modules/')
for dir in ${ALL_DIRS}
do
  pushd "$dir"
  # always create a new lock to avoid duplicate downloads by terraoform init -upgrade
  rm -f .terraform.lock.hcl
  # get modules to detect provider dependencies inside module
  terraform init -input=false -no-color -backend=false -plugin-dir="${FS_MIRROR}"
  # remove a temporary lock file to avoid a checksum mismatch error
  rm -f .terraform.lock.hcl
  # generate h1 hashes for all platforms you need
  # recording zh hashes requires to download from origin, so we intentionally ignore them.
  terraform providers lock -fs-mirror="${FS_MIRROR}" -platform=linux_amd64 -platform=darwin_amd64 -platform=darwin_arm64
  # clean up
  rm -rf .terraform
  popd
done
