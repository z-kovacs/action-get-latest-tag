#!/bin/sh

set -e

git config --global --add safe.directory /github/workspace

git fetch --tags
# This suppress an error occurred when the repository is a complete one.
git fetch --prune --unshallow || true

latest_tag=''

if [ "${INPUT_SEMVER_ONLY}" = 'false' ]; then
  # Get a actual latest tag.
  # If no tags found, supress an error. In such case stderr will be not stored in latest_tag variable so no additional logic is needed.
  latest_tag=$(git describe --abbrev=0 --tags || true)
else
  # Get a latest tag in the shape of semver (or higher version in case they are attached to the same commit).
  #
  # Using two --sort keys result in using latter as primary, so we have to use them in reverse order of precedence.
  #
  # if you have 2 tags on the same commit, creatordate will be equal, so the order will be undefined, and the order of addition
  # so if you tag a commit first v1.2 first then tag the same commit with v2.0, with `--sort=-creatordate` the output will be:
  # - v1.2
  # - v2.0
  # with `-sort=-refname --sort=-creatordate` the output will be:
  # - v2.0
  # - v1.2
  # (We assume that reverse lexicographic order of tags is correct within the same commit.)
  #
  # Note: taggerdate field is not respecting reverse ordering modifier, so we cannot use that.
  for ref in $(git for-each-ref --sort=-refname --sort=-creatordate --format '%(refname)' refs/tags); do
    tag="${ref#refs/tags/}"
    if echo "${tag}" | grep -Eq '^v?([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?$'; then
      latest_tag="${tag}"
      break
    fi
  done
fi

if [ "${latest_tag}" = '' ] && [ "${INPUT_WITH_INITIAL_VERSION}" = 'true' ]; then
  latest_tag="${INPUT_INITIAL_VERSION}"
fi

echo "::set-output name=tag::${latest_tag}"
