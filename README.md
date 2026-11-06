# Nginx Container Demo

A small static website served by Nginx, packaged with Docker and built/published with GitHub Actions.

## Repository layout

```text
app/                       Static HTML and CSS
nginx/nginx.conf            Nginx virtual-host configuration
config.json                 Central application and Docker settings
Dockerfile                  Container image definition
scripts/create-tag.sh       Optional local semantic-version helper
.github/workflows/
  docker-build.yml          Build, test, and publish to Docker Hub
  release-tag.yml            Manual SemVer release and GitHub Release
```

## Run locally

Requirements: Docker.

```bash
docker build -t nginx-container-demo:local .
docker run --rm -p 8080:80 nginx-container-demo:local
```

Open http://localhost:8080. The application reads `/config.json` in the browser.

## Configure Docker Hub

1. Create a Docker Hub access token with read/write access.
2. In GitHub, open **Settings → Secrets and variables → Actions → New repository secret**.
3. Add:
   - `DOCKERHUB_USERNAME`: your Docker Hub username.
   - `DOCKERHUB_TOKEN`: your Docker Hub access token.
4. Ensure GitHub Actions are enabled for the repository.

The publish workflow uses the Docker Hub repository name `nginx-container-demo`, so create that repository in Docker Hub first, or change the image name in `.github/workflows/docker-build.yml`.

## Build workflow

`.github/workflows/docker-build.yml`:
- Runs on pull requests, pushes to `main`, version-tag pushes (`v*`), and manual dispatch.
- Builds the image and checks the home page and `config.json`.
- Publishes on pushes to `main` and version tags.
- Publishes `latest` for the default branch.
- The manual release workflow publishes the versioned image directly. This is intentional: GitHub does not start a new workflow when a tag is pushed using the default `GITHUB_TOKEN`.

## Create a release

1. Push your changes to `main`.
2. Open **GitHub → Actions → Create Semantic Version Release**.
3. Select **Run workflow** and choose `patch`, `minor`, or `major`.
4. The workflow updates `config.json`, commits the version, creates an annotated tag, pushes both, and creates a GitHub Release with generated notes.
5. The release workflow creates the GitHub Release and publishes the matching versioned Docker image. The regular Docker workflow publishes `latest` from `main`.

Example: if `config.json` contains `1.0.0`, selecting `minor` creates `1.1.0` and tag `v1.1.0`.

The workflow does not force-push or overwrite tags. It serializes releases to avoid two release runs racing. Do not manually edit or create release tags outside this process unless you also update `config.json`.

## Local tag helper (optional)

The helper creates a local commit and annotated tag; it does not push anything:

```bash
chmod +x scripts/create-tag.sh
./scripts/create-tag.sh patch
git push origin HEAD
git push origin v1.0.1
```

For normal releases, prefer the GitHub Actions workflow.

## Important configuration note

`config.json` is copied into the web root and fetched by the browser at runtime. Its `application` values are displayed by the demo page. `docker.port` documents the container port; Docker's `EXPOSE 80` and Nginx listener remain 80. To change the actual container port, update the Dockerfile and Nginx configuration as well.

## Security and maintenance

- Never commit Docker Hub credentials.
- Use a Docker Hub access token rather than your account password.
- Consider pinning third-party GitHub Actions to full commit SHAs for stricter supply-chain security.
- Review and update the Nginx base image and action versions periodically.
