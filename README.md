# template-valkey

Self-service **Valkey** (Redis-compatible in-memory store) for the Open Service
Portal, built on the official [`valkey-io/valkey-operator`](https://github.com/valkey-io/valkey-operator)
and exposed as a namespaced Crossplane v2 XR.

Spec & design: [`docs/specs/valkey-service.md`](../docs/specs/valkey-service.md) ·
spike findings: [`docs/specs/valkey-spike-findings.md`](../docs/specs/valkey-spike-findings.md).

## What you order

```yaml
apiVersion: openportal.dev/v1alpha1
kind: ValkeyInstance
metadata:
  name: my-cache
  namespace: default
spec:
  size: small            # small | medium | large  -> CPU/memory
  persistence:
    enabled: false       # set true + size for a PVC
```

You get a running, **password-protected** Valkey. Connection info is on the XR status:

- `status.endpoint` — `host:port` to connect to
- `status.authSecret` — Secret holding the app user's password (key `password`)

```sh
kubectl get valkeyinstance my-cache -o jsonpath='{.status.endpoint}'
kubectl get secret my-cache-auth -o jsonpath='{.data.password}' | base64 -d
```

## How it works

`ValkeyInstance` XR → Composition (`function-go-templating`) renders a password
`Secret` (create-only) and a `ValkeyCluster` (`shards:1, replicas:0`) → both
applied via **provider-kubernetes** → reconciled by the **valkey-operator**.

The operator is platform infrastructure, installed once per cluster by
`scripts/cluster-setup.sh` (not by this Composition).

## Layout

```
configuration/
  crossplane.yaml    # Configuration package metadata
  xrd.yaml           # ValkeyInstance API (XRD, v2, namespaced)
  composition.yaml   # Pipeline: go-templating -> provider-kubernetes -> auto-ready
example/
  xr.yaml            # example orders
```

## MVP scope

Single instance, `size` + optional `persistence`, one password-protected app user.
TLS, HA/replicas, sharding, advanced ACL and Backstage integration are deferred —
the XRD is designed to add them later without breaking changes.
