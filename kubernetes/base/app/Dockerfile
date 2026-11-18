# Build a static binary, then ship it on distroless static as a non-root user.
# The runtime image has no shell and no package manager, so the Trivy attack
# surface is close to zero and the container cannot be used as a foothold.

# Build with a current Go toolchain so the standard library compiled into the
# binary carries the latest security fixes. The Trivy stdlib gate fails the
# pipeline when this falls behind, which is how we caught the 1.24 toolchain.
FROM golang:1.27 AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/app .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/app /app
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/app"]
