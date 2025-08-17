#!/usr/bin/bash
#
# Copyright (c) 2022,2025 Robert Di Pardo
# License: https://github.com/rdipardo/nppFSIPlugin/blob/master/.circleci/scripts/gh_release.sh
#
test -z "$GH_API_TOKEN_2025" && exit 0

# https://discuss.circleci.com/t/circle-branch-and-pipeline-git-branch-are-empty/44317/3
COMMIT=$(git rev-parse "${CIRCLE_TAG:-@}") \
  && TMP=$(git branch -a --contains $COMMIT) \
  && BRANCH="${TMP##*[ /]}"

cd "$BIN_DIR" || exit 0
ASSETS=("${SLUGX86}" "${SLUGX64}")
test -z "$CIRCLE_TAG" && TAG_NAME=$(git describe --always '@') || TAG_NAME="$CIRCLE_TAG"
test -z "$CIRCLE_TAG" && PRE_RELEASE=true || PRE_RELEASE=false
printf '#### SHA256 Checksums\\n\\n' > sha256sums.md
for slug in "${ASSETS[@]}"; do printf '\\t%s\\n' "$(sha256sum "$slug")" >> sha256sums.md; done
curl -sL -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GH_API_TOKEN_2025}" \
        "https://api.github.com/repos/${CIRCLE_USERNAME}/${CIRCLE_PROJECT_REPONAME}/releases" \
    -d "{\"tag_name\":\"${CIRCLE_TAG}\",
        \"target_commitish\":\"${BRANCH}\",
        \"name\":\"${TAG_NAME}\",
        \"body\":\"$(cat sha256sums.md)\",
        \"draft\":false,
        \"prerelease\":${PRE_RELEASE},
        \"generate_release_notes\":false}" > response.json

RELEASE_ID=$(jq -Mcr '.id // ""' < response.json)
test -z "$RELEASE_ID" && exit 0

for slug in "${ASSETS[@]}"
do
    curl -sL -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${GH_API_TOKEN_2025}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Content-Type: application/octet-stream" \
      "https://uploads.github.com/repos/${CIRCLE_USERNAME}/${CIRCLE_PROJECT_REPONAME}/releases/${RELEASE_ID}/assets?name=${slug}" \
      --data-binary "@${slug}" >/dev/null 2>&1
done
