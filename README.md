# Config Server

Serves configuration from [Config-Repo](https://github.com/onurokkyay/Config-Repo) to the
services that read from it.

## Who reads from it

The [API gateway](https://github.com/onurokkyay/API-Gateway), and only it. Its configuration is
**routes**, which change every time a service is added or moved — exactly the change a config
server makes cheap, because it needs no rebuild and no redeploy.

The auth service and GameAtlas read their environment directly. Their configuration is signing
keys, database URLs and lifetimes: values that change almost never and require a restart when
they do, so central management bought nothing and cost a startup dependency.

## Running it

Against the real repository, which needs a token with read access:

```bash
GIT_TOKEN=<token> ./gradlew bootRun
```

Against a local clone, which needs no credential and is how the estate is tested end to end:

```bash
./gradlew bootRun --args="--spring.cloud.config.server.git.uri=file:///path/to/Config-Repo"
```

## Configuration

| Property | Env variable | Default |
| --- | --- | --- |
| `spring.cloud.config.server.git.uri` | `GIT_URI` | the GitHub repository |
| `spring.cloud.config.server.git.username` | `GIT_USERNAME` | `onurokkyay` |
| `spring.cloud.config.server.git.password` | `GIT_TOKEN` | – |
| `spring.cloud.config.server.git.default-label` | `GIT_BRANCH` | `main` |
| `server.port` | `SERVER_PORT` | `8888` |

`GIT_TOKEN` has no default on purpose: a blank password against the real repository fails loudly
rather than quietly serving stale configuration.

## A note on names

The config server serves `<name>.yml`, where the name comes from the client's
`spring.cloud.config.name`. A client asking for a file that does not exist gets the shared
`application.yml` and **no error** — it simply starts under-configured. The gateway therefore
names itself explicitly rather than letting the value be derived.
