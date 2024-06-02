#!/bin/bash
CHECKSUM=$(cat /CHECKSUM | tr -d '"')
VERSION=$(cat /VERSION)

echo "{\"checksum\": \"${CHECKSUM}\", \"version\": \"${VERSION:-?}\"}"
