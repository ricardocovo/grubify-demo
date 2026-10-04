#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$LAB_DIR/infra/modules/container-app.bicep"

bicep build "$TEMPLATE" --stdout | python3 -c '
import json
import sys

template = json.load(sys.stdin)
apps = [
    resource for resource in template["resources"]
    if resource["type"] == "Microsoft.App/containerApps"
]
api = next(
    resource for resource in apps
    if resource["properties"]["template"]["containers"][0]["name"] == "grubify-api"
)
api_template = api["properties"]["template"]
container = api_template["containers"][0]
scale = api_template["scale"]

assert container["resources"]["cpu"] == "[json('\''1'\'')]"
assert container["resources"]["memory"] == "2Gi"
assert scale["minReplicas"] == 2
assert scale["maxReplicas"] == 5
assert scale["rules"] == [{
    "name": "http-concurrency",
    "http": {"metadata": {"concurrentRequests": "50"}},
}]
'

echo 'PASS: Grubify API CPU, memory, minimum replicas, and HTTP scaling rule'
