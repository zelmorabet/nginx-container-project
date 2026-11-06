# Nginx + Tomcat Docker Images

A single GitHub repository that builds, tests, versions, and publishes two independent Docker images:

- **Nginx:** static HTML/CSS site served on container port `80`.
- **Tomcat:** Java 17 Jakarta Servlet application packaged as a WAR and served on container port `8080`.

## Repository layout

```text
.github/workflows/       Shared build and release workflows
nginx-image/             Nginx Docker build context and static app
tomcat-image/            Maven Java WAR, Tomcat config and Docker build context
CHANGELOG.md             Repository-level change history
README.md                This guide
```

## Docker Hub setup

Create these two Docker Hub repositories under your account:

- `nginx-demo`
- `tomcat-demo`

Configure GitHub repository secrets under **Settings → Secrets and variables → Actions**:

- `DOCKERHUB_USERNAME`: Docker Hub username.
- `DOCKERHUB_TOKEN`: Docker Hub access token with read/write permissions.

Enable GitHub Actions and allow workflow write access to repository contents (**Settings → Actions → General → Workflow permissions**). The release workflow creates commits, tags and GitHub Releases.

## Build locally

Run commands from the repository root.

### Nginx

```bash
docker build -t nginx-demo:local ./nginx-image
docker run --rm -p 8080:80 nginx-demo:local
```

Open http://localhost:8080.

### Tomcat Java application

The Tomcat Dockerfile uses a multi-stage build: Maven compiles the Servlet application into `ROOT.war`, then Tomcat 10.1 runs it on Java 17.

```bash
docker build -t tomcat-demo:local ./tomcat-image
docker run --rm -p 8081:8080 tomcat-demo:local
```

Open http://localhost:8081. The Java backend endpoint is http://localhost:8081/api/info.

## Configuration

Each image has a root `config.json` as its release source of truth and an application-facing config file:

- Nginx: `nginx-image/config.json` and `nginx-image/app/config.json`.
- Tomcat: `tomcat-image/config.json` and `tomcat-image/app/src/main/webapp/config.json`.

The release workflow updates both files for the selected image. Each Dockerfile ensures the root configuration is the deployed version. `docker.port` documents the container port; changing the actual port also requires changes to the server config, Dockerfile and workflow smoke test.

## GitHub Actions

### `docker-build.yml`

- Pull requests: detects which image directory changed, then builds and smoke-tests only that image.
- Pushes to `main`: builds/tests changed image(s), then publishes `latest` to Docker Hub.
- Version tags (`nginx-v*`, `tomcat-v*`): builds/tests and publishes the matching version tag.
- Manual run: choose `both`, `nginx`, or `tomcat`. A manual run on `main` publishes the selected image(s) as `latest`.

### `release-tag.yml`

Run **Actions → Create image release → Run workflow** and choose:

1. Image: `nginx` or `tomcat`.
2. Increment: `patch`, `minor`, or `major`.

The workflow reads that image's version, calculates the next SemVer, updates both configuration files, commits the change to `main`, creates an annotated image-specific Git tag, pushes it, publishes the versioned Docker image, and creates a GitHub Release with generated notes.

Example independent histories:

```text
nginx-v1.0.0
nginx-v1.0.1
nginx-v1.1.0

tomcat-v1.0.0
tomcat-v1.0.1
tomcat-v2.0.0
```

Existing tags are never force-overwritten. Releases are serialized because both images update the shared `main` branch. The release workflow publishes the image itself because a tag pushed using the default `GITHUB_TOKEN` does not trigger a separate workflow run.

## Local release helper scripts (optional)

These scripts create a local version commit and annotated tag; they do not push or publish:

```bash
./nginx-image/scripts/create-tag.sh patch
# or
./tomcat-image/scripts/create-tag.sh minor
```

Then push the commit and tag as instructed by the script. For normal releases, prefer the GitHub Actions release workflow.

## Tomcat implementation

The sample uses Java 17, Jakarta Servlet 6.0 (`jakarta.servlet.*`), Maven WAR packaging, and Tomcat 10.1. The `InfoServlet` exposes `/api/info`, while the static page fetches both `/config.json` and `/api/info`.

## Maintenance

Review and update base-image versions and GitHub Actions versions periodically. For stricter supply-chain controls, pin third-party GitHub Actions to full commit SHAs.
