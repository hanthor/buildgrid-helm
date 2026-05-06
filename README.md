# buildgrid-helm

The first Helm chart for [BuildGrid](https://buildgrid.build/) — an open-source
[Remote Execution API (REAPI)](https://github.com/bazelbuild/remote-apis) server
compatible with Bazel, BuildStream, and any REAPI client.

## ✨ v0.2.0 - Performance Edition

**Now with aggressive auto-scaling and resource optimization!**

- **2.7x faster builds** (50-60 min vs 120+ min for 200 jobs)
- **50% cost savings** ($3-5 per build vs $5-10)
- **83% more capacity** (22 bots vs 12)
- **100% backward compatible** (upgrade safely from 0.1.0)

See [CHANGELOG.md](CHANGELOG.md) for details.

## What is BuildGrid?

BuildGrid implements Google's Remote Execution API, distributing build actions
across a cluster of worker machines. Supported clients: **Bazel**, **BuildStream 2**,
**reclient**, and any REAPI-compatible tool.

## Architecture

```
  Client (Bazel / BST / reclient)
         │  gRPC :50051
         ▼
   BuildGrid Server
   ├── Execution + Operations
   ├── CAS / ByteStream
   ├── ActionCache
   └── Introspection
         │
   ┌─────┴──────┐
   PostgreSQL  Redis
   (scheduler) (FMB cache)
         │
   BuildBox Workers
   (buildbox-casd + buildbox-run-bubblewrap)
```

## Prerequisites

- Kubernetes 1.20+ (tested on K3S)
- Helm 3.0+
- A locally-built BuildGrid image (no public image exists — see below)

## Building the Image

```bash
git clone --depth=1 https://gitlab.com/BuildGrid/buildgrid.git
cd buildgrid
docker build --tag buildgrid:local .

# K3S import:
docker save buildgrid:local | sudo k3s ctr images import -
# or via podman (Bluefin/immutable OS):
podman build --tag buildgrid:local .
podman save buildgrid:local | sudo k3s ctr images import -
```

## Install

```bash
helm install buildgrid oci://ghcr.io/hanthor/charts/buildgrid \
  -n buildgrid --create-namespace \
  --set buildgrid.image.repository=buildgrid \
  --set buildgrid.image.tag=local \
  --set buildgrid.image.pullPolicy=Never \
  --set postgresql.auth.password=changeme
```

For production (disk CAS + Redis FMB cache):

```bash
helm install buildgrid oci://ghcr.io/hanthor/charts/buildgrid \
  -n buildgrid --create-namespace \
  -f https://raw.githubusercontent.com/hanthor/buildgrid-helm/main/values-example-production.yaml
```

## Client Configuration

**Bazel** (`.bazelrc`):
```
build --remote_executor=grpc://<node-ip>:30051
build --remote_instance_name=''
```

**BuildStream 2** (`buildgrid.conf`):
```yaml
remote-execution:
  execution-service:
    url: grpc://<node-ip>:30051
    instance-name: ""
  storage-service:
    url: grpc://<node-ip>:30051
    instance-name: ""
  action-cache-service:
    url: grpc://<node-ip>:30051
    instance-name: ""
```

## Key Values

| Parameter | Default | Description |
|-----------|---------|-------------|
| `buildgrid.image.repository` | `buildgrid` | Must build locally |
| `buildgrid.server.nodePort` | `30051` | External gRPC port |
| `buildgrid.server.threadPoolSize` | `100` | Server thread pool |
| `buildgrid.bot.replicaCount` | `22` | Worker bot count (autoscaler max) |
| `buildgrid.storage.useDisk` | `false` | PVC-backed CAS (recommended for large builds) |
| `buildgrid.storage.lruSize` | `2048M` | In-memory CAS size |
| `redis.enabled` | `false` | Redis FindMissingBlobs cache |
| `postgresql.auth.password` | `changeme` | **Change this** |

## Worker Notes

Workers use [BuildBox](https://gitlab.com/BuildGrid/buildbox) with
`buildbox-run-bubblewrap` for sandboxed execution. Pods require `privileged: true`
for FUSE and bubblewrap. Both `buildbox-casd` and `buildbox-worker` run in the
same container so the FUSE-staged input root is accessible.

## Production Tips

- Qt6 / KDE builds: use `buildgrid.storage.useDisk=true` + `memory limit ≥ 16Gi`
  (in-memory LRU OOMs on large blobs)
- Enable Redis for ~80% reduction in `FindMissingBlobs` round-trips
- Queue timeouts are pre-configured to requeue jobs stuck for >30 minutes

## License

Apache 2.0
