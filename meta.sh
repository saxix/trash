#!/bin/bash
set -e pipefail
repo="saxix/trash"
tag="test-feature-ci3"
ref="${repo}:${tag}"

docker inspect --format '{{ index .Config.Labels "com.docker.compose.project"}}' ${ref}

exit 1

if [[ -z $ref ]]; then
  echo "::error:: No valid image provided"
  exit 1
fi

GITHUB_OUTPUT='&1'

architecture="amd64"
echo "::notice::✅ Fetching meta for '${ref}' ${architecture}"
repo="${ref%:*}"
tag="${ref##*:}"

echo "repo=$repo" >> $GITHUB_OUTPUT
echo "tag=$tag" >> $GITHUB_OUTPUT
echo "architecture=$architecture" >> $GITHUB_OUTPUT

echo "exists=false" >> "$GITHUB_OUTPUT"
echo "updated=false" >> "$GITHUB_OUTPUT"
echo "build_number=1" >> "$GITHUB_OUTPUT"
echo "build_date=-" >> "$GITHUB_OUTPUT"
echo "checksum=-" >> "$GITHUB_OUTPUT"

res=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull")
token=$(echo $res | jq -r '.token')
if [[ -z "$token" ]];then
  echo "::error::⛔ Unable to get valid token"
  exit 1
fi
echo "::notice::✅ Successfully obtained token"
url="https://registry-1.docker.io/v2/${repo}/manifests/${tag}"
manifest=$(curl -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
                -H "Authorization: Bearer ${token}" \
                -s $url)

if [[ -z "$manifest" ]];then
  echo "::error::⛔ Unable to get manifest from $url"
  exit 1
fi
echo "::notice::✅ Successfully obtained manifest"
echo $manifest | jq

if [[ $manifest =~ "MANIFEST_UNKNOWN" ]]; then
  echo "::error::⛔ Unknown Manifest"
  echo "exists=false" >> "$GITHUB_OUTPUT"
  exit 0
fi
if [[ $manifest == *errors\":* ]];then
  code=$(echo $manifest | jq .errors[0].code)
  message=$(echo $manifest | jq .errors[0].message)
  echo "::error title=$code::⛔ $message https://registry-1.docker.io/v2/${repo}/manifests/${tag}"
  exit 1
fi

check1=$(echo $manifest | jq 'try(.manifests[])')
check2=$(echo $manifest | jq 'try(.config.digest)')

if [[ -n "$check1" ]]; then
  digest=$(echo $manifest | jq -r ".manifests| map(select(.platform.architecture | contains (\"${architecture}\"))) | .[].digest" 2>&1)
elif [[ -n "$check2" ]]; then
  digest=$(echo $manifest | jq -r '.config.digest')
else
  echo "::error::⛔ Unable to detect digest"
  exit 1
fi

if [[ $digest == null ]]; then
  echo "::error::⛔ Digest is null"
  exit 1
fi
if [[ -z "$digest" ]];then
  echo "::error title=ERROR::⛔ Digest is empty"
  exit 1
fi
echo "::notice::✅ Successfully obtained digest: $digest"

url=https://registry-1.docker.io/v2/${repo}/blobs/$digest
blob=$(curl \
      --silent \
      --location \
      -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
      -H "Authorization: Bearer ${token}" \
      $url)
if [[ -z "$blob" ]]; then
  echo "::error title=ERROR::⛔ Empty Blob"
  exit 1
fi

curl -s -L \
    -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    -H "Authorization: Bearer $token" \
    "https://registry-1.docker.io/v2/${repo}/blobs/$digest"

echo "========"

if [[ $blob == *BLOB_UNKNOWN* ]];then
  echo "exists=false" >> "$GITHUB_OUTPUT"
  echo "::group title=ERROR::⛔ Unknown Blob at $url"
  echo "::error:: $blob"
  echo "::endgroup::"
  exit 0
fi
if [[ $blob == *errors\":* ]];then
  code=$(echo $blob | jq .errors[0].code)
  message=$(echo $blob | jq .errors[0].message)
  echo "::error title=$code::⛔ Error fetching blob"
  exit 1
fi
echo "::group::"
echo "::notice::✅ Successfully obtained blob"
echo "::notice::✅ $blob"
echo "::endgroup::"

build_number=$(echo $blob | jq '.config.Labels.BuildNumber')
checksum=$(echo $blob | jq -r '.config.Labels.checksum')
build_date=$(echo $blob | jq -r '.config.Labels.date')

if [[ $build_number =~ ^[0-9]+$ ]] ; then
  build_number=$(( build_number + 1 ))
else
  build_number=1
fi
if [[ $checksum == ${{inputs.checksum}} ]]; then
  echo "updated=true" >> $GITHUB_OUTPUT
else
  echo "updated=false" >> $GITHUB_OUTPUT
fi
echo "checksum=${checksum}" >> $GITHUB_OUTPUT
echo "build_number=${build_number}" >> $GITHUB_OUTPUT
echo "build_date=${build_date}" >> $GITHUB_OUTPUT
