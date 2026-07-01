# tests

Render tests for the `ValkeyInstance` composition — the executable acceptance
criteria of [`SPEC-valkey-admin-webui`](https://github.com/open-service-portal/open-service-portal/blob/main/specs/valkey-admin-webui/0001_product_valkey-admin-webui.md). Each test renders the composition with `crossplane render` and asserts on the output.

## Run

```sh
bash tests/render-test.sh
```

Requires `crossplane` (v2+) and a container runtime (render runs the composition
functions in containers). On rancher-desktop the script auto-detects
`~/.rd/docker.sock`.

## Files

- `functions.yaml` — function packages (match the cluster-installed versions)
- `xr-webui-on.yaml` / `xr-webui-off.yaml` — render inputs
- `render-test.sh` — assertions (AC-vaw-1-1 … AC-vaw-2-1)
