#!/bin/bash
set -eo pipefail

# create a local filesystem mirror to avoid duplicate downloads
FS_MIRROR="/tmp/terraform.d/plugins"
terraform providers mirror -platform=linux_amd64 -platform=darwin_amd64 "${FS_MIRROR}"

# update the lock file
ALL_DIRS=$(find . -type f -name '*.tf' | xargs -I {} dirname {} | grep -v 'modules/')
for dir in ${ALL_DIRS}
do
  pushd "$dir"
  # always create a new lock to avoid duplicate downloads by terraoform init -upgrade
  rm -f .terraform.lock.hcl
  # generate h1 hashes for all platforms you need
  # recording zh hashes requires to download from origin, so we intentionally ignore them.
  terraform providers lock -fs-mirror="${FS_MIRROR}" -platform=linux_amd64 -platform=darwin_amd64
  popd
done
