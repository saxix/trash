#!/bin/bash
CHECKSUM=$(cat /CHECKSUM)
VERSION=$(cat /VERSION)

echo "{\"checksum\": \"${CHECKSUM}\", \"version\": \"${VERSION}\"}"
