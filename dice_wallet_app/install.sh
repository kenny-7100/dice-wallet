#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

flutter build ipa --release --export-method development
xcrun devicectl device install app --device "iPhone" build/ios/ipa/dice_wallet_app.ipa
