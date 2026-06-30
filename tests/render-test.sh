#!/usr/bin/env bash
# Render tests for the ValkeyInstance composition — encodes the web-UI acceptance
# criteria (spec: SPEC-valkey-admin-webui). Needs `crossplane` + a container runtime.
# rancher-desktop: socket at ~/.rd/docker.sock (auto-detected when DOCKER_HOST unset).
cd "$(dirname "$0")/.." || exit 2
[ -z "${DOCKER_HOST:-}" ] && [ -S "$HOME/.rd/docker.sock" ] && export DOCKER_HOST="unix://$HOME/.rd/docker.sock"
render(){ crossplane render "$1" configuration/composition.yaml tests/functions.yaml 2>/dev/null; }
ON="$(render tests/xr-webui-on.yaml)"; OFF="$(render tests/xr-webui-off.yaml)"
[ -n "$ON" ] && [ -n "$OFF" ] || { echo "render failed (is a container runtime running?)"; exit 2; }
VC_ON="$(grep -A40 'kind: ValkeyCluster' <<<"$ON")"
pass=0; fail=0
check(){ if eval "$2"; then echo "  ok   $1"; pass=$((pass+1)); else echo "  FAIL $1"; fail=$((fail+1)); fi; }

# AC-vaw-1-1 — webUI default(true) -> admin Deployment + Service
check "AC-vaw-1-1 Deployment"  'grep -q "resource-name: test-on-admin$" <<<"$ON"'
check "AC-vaw-1-1 Service"      'grep -q "resource-name: test-on-admin-svc$" <<<"$ON"'
check "AC-vaw-1-1 image pinned" 'grep -q "valkey/valkey-admin:1.0.2" <<<"$ON"'
# AC-vaw-1-2 — env wired incl. auth from observed Secret
check "AC-vaw-1-2 VALKEY_HOST"     'grep -q "valkey-test-on.default.svc.cluster.local" <<<"$ON"'
check "AC-vaw-1-2 DEPLOYMENT_MODE" 'grep -Eq "value: \"?K8\"?" <<<"$ON"'
check "AC-vaw-1-2 password ref"    'grep -q "name: test-on-auth" <<<"$ON" && grep -q "key: password" <<<"$ON"'
# AC-vaw-1-3 — webUI false -> no admin resources
check "AC-vaw-1-3 no UI when off"  '! grep -q "test-off-admin" <<<"$OFF"'
# AC-vaw-2-1 — no operator-owned StatefulSet patch
check "AC-vaw-2-1 no StatefulSet"  '! grep -q "kind: StatefulSet" <<<"$ON"'
check "AC-vaw-2-1 no container patch on ValkeyCluster" '! grep -q "containers:" <<<"$VC_ON"'

echo "  -> $pass passed, $fail failed"
[ "$fail" -eq 0 ]
