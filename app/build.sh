#!/bin/bash
## DOWNLOAD BINARIES
set -e
PATH=$(pwd)/node_modules/.bin:$PATH
npm ci

## BUILD
npm run build

## CLEAN UP, cloudflare pages will reject the node_module size of >25mb
rm -rf node_modules
