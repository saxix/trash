#!/bin/bash

#USERNAME=$DOCKERHUB_USERNAME
#PASSWORD=$DOCKERHUB_TOKEN

set +e
ref="saxix/trash:test-develop"

repo="${ref%:*}"
tag="${ref##*:}"

echo "Repo: $repo"
echo "Tag: $tag"

if [ -n "$USERNAME" ];  then
  token=$(curl -u "$USERNAME:$PASSWORD" \
            -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull" \
            | jq -r '.token')
else
  token=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull" \
        | jq -r '.token')
fi

#echo $token
digest_response=$(curl -s -D -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
                -H "Authorization: Bearer $token" \
                -s "https://registry-1.docker.io/v2/${repo}/manifests/${tag}" )

digest=$(echo $digest_response | jq -r '.config.digest')
if [[ "$digest" == "null" ]]; then
  digest=$(echo $digest_response | jq -r '.manifests|.[]| "\(.digest) \(.platform.architecture)"' \
            | grep amd64 | awk '{print $1}' | sed 's/^sha256://' )
fi

echo $digest
#echo $digest_response | jq -r .config.digest

#digest=$(curl -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
#                -H "Authorization: Bearer $token" \
#                -s "https://registry-1.docker.io/v2/${repo}/manifests/${tag}" | jq -r .config.digest)
#
checksum=$(curl -H "Accept: application/vnd.docker.container.image.v1+json" \
       -H "Authorization: Bearer $token" \
       -s -L "https://registry-1.docker.io/v2/${repo}/blobs/${digest}")
echo $checksum
#checksum=$(curl -H "Accept: application/vnd.docker.container.image.v1+json" \
#       -H "Authorization: Bearer $token" \
#       -s -L "https://registry-1.docker.io/v2/${repo}/blobs/${digest}" | jq --raw-output '.config.Labels.${{ inputs.label }}' )
e="false"

if [ $checksum = '"${{ inputs.checksum }}"' ];then
  e="true"
  echo "Image ${{inputs.image}} found"
else
  echo "Image ${{inputs.image}} does not exist"
fi
echo "exists=$e" >> "$GITHUB_OUTPUT"Ï