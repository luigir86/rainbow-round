#!/usr/bin/env bash
# Builds the web version into build/webapp, ready to be served from any
# folder (no <base href>, no service worker) or published as a Claude
# artifact: only file types a static host serves everywhere are kept.
#   tool/build_webapp.sh
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build web --release --no-web-resources-cdn
rm -rf build/webapp
mkdir -p build/webapp
cd build/web
find . -type f \
  ! -name '*.symbols' ! -name '*.bin' ! -name '*.frag' \
  ! -name index.html ! -name webapp_index.html ! -name .last_build_id ! -name flutter_service_worker.js \
  -exec cp --parents {} ../webapp/ \;
cp ../../web/webapp_index.html ../webapp/index.html
