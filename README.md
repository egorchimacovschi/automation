# automation

A small workshop project for practicing **Docker** and **GitHub Actions**: a C program is compiled inside a Docker image, and a CI/CD workflow builds that image and publishes it to the GitHub Container Registry (ghcr.io) on every push to `main`.

## Project structure

```
.
├── .github/
│   └── workflows/
│       └── publish_docker.yml   # CI/CD: build & push the image on every push to main
├── Dockerfile                   # How the image is built
├── README.md
└── test.c                       # The C program that runs inside the container
```

## The Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt update && apt install -y gcc

WORKDIR /test
COPY test.c /test/

RUN gcc test.c -o test > /dev/null
CMD ["./test"]
```

What each step does:

| Instruction | Purpose |
|---|---|
| `FROM ubuntu:22.04` | Starts from an Ubuntu 22.04 base image |
| `RUN apt update && apt install -y gcc` | Installs the C compiler |
| `WORKDIR /test` | Sets `/test` as the working directory inside the image |
| `COPY test.c /test/` | Copies the source file into the image |
| `RUN gcc test.c -o test` | Compiles the program **at build time**, so compile errors fail the build |
| `CMD ["./test"]` | Runs the compiled program when the container starts |

## Running locally

Build the image (the `.` means "use the Dockerfile in the current folder"):

```bash
docker build -t test_workshop .
```

Run it:

```bash
docker run --rm test_workshop
```

- `-t` / `--tag` gives the image a name (`name:tag`, tag defaults to `latest`)
- `--rm` removes the container after it exits
- add `-it` if the program reads input from the keyboard

After changing `test.c`, rebuild the image before running it again.

List your local images:

```bash
docker images
```

## CI/CD with GitHub Actions

The workflow in `.github/workflows/publish_docker.yml` runs automatically on every push to `main`:

1. **Trigger:** a push to the `main` branch starts the workflow.
2. **Runner:** GitHub spins up a fresh `ubuntu-latest` virtual machine.
3. **Permissions:** the job can read the repo (`contents: read`) and publish packages (`packages: write`).
4. **Checkout:** `actions/checkout` downloads the repository code.
5. **Login:** `docker/login-action` signs in to `ghcr.io` using the automatic `GITHUB_TOKEN` (no manual secrets needed).
6. **Build & push:** `docker/build-push-action` builds the image from the repo root (`context: .`) and pushes it as:

```
ghcr.io/egorchimacovschi/automation/test:latest
```

The `latest` tag is overwritten on every push, so it always points to the newest version.

## Pulling the published image

```bash
docker pull ghcr.io/egorchimacovschi/automation/test:latest
docker run --rm ghcr.io/egorchimacovschi/automation/test:latest
```

> New packages on ghcr.io are **private** by default. Either log in first (`docker login ghcr.io`) or make the package public from its settings page on GitHub.

## Lessons learned / common mistakes

- **Image names must be exact:** `unbuntu` → `ubuntu`. Docker will fail with *"repository does not exist"* on a typo.
- **`EXEC` is not a Dockerfile instruction.** Use `RUN` (build time), `CMD` or `ENTRYPOINT` (container start).
- **JSON-form `CMD` doesn't use a shell.** `CMD ["gcc test.c -o test && ./test"]` won't work; use `CMD ["sh", "-c", "..."]` or the plain shell form.
- **Compile at build time, not at startup.** `RUN gcc ...` + `CMD ["./test"]` is faster and catches errors early.
- **In GitHub Actions, `context` is relative to the repository root**, not to the workflow file. `context: ../../test` fails; `context: .` is correct.