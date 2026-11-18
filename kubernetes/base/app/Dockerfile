# Build a static binary, then ship it on distroless static as a non-root user.
# The runtime image has no shell and no package manager, so the Trivy attack
# surface is close to zero and the container cannot be used as a foothold.

# Build with a digest-pinned Go toolchain so the standard library compiled into
# the binary is reproducible and carries the latest security fixes. The Trivy
# stdlib gate fails the pipeline when this falls behind, which is how we caught
# the 1.24 toolchain. Pinning by digest, not a tag, is what makes this
# deterministic: even a patch tag like 1.27.4 can be re-pushed in the registry,
# but a digest cannot, so the same commit always resolves to the same base image
# and the same scan result. Bumping Go becomes a reviewed change to this digest.
# The 1.27.4 tag is kept alongside the digest only for readability.
FROM golang:1.27.4@sha256:205c7636d74e0ffbe3d007162df7d74f859f5a8c8322dfb9f907977686c126cf AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/app .

# Pin the runtime by digest for the same reason: :nonroot is a floating tag and
# the final image is what Trivy scans, so an un-pinned runtime could change the
# scan result between runs on an unchanged commit.
FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
COPY --from=build /out/app /app
EXPOSE 8080
# Use the distroless nonroot UID/GID numerically, not the name. With a named
# user the kubelet cannot verify the container is non-root under
# runAsNonRoot: true and rejects the pod with CreateContainerConfigError.
USER 65532:65532
ENTRYPOINT ["/app"]
