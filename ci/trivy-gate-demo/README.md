# Trivy gate demonstration

The pipeline's scan stage fails on a fixable HIGH or CRITICAL finding, so an image
with a known vulnerability never reaches the sign or promote stages. This folder
proves that gate works, run by hand, without planting a vulnerability in the real
application.

## Fail

Build the deliberately old image and scan it with the same threshold the pipeline
uses:

```
docker build -t trivy-gate-demo ci/trivy-gate-demo
trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed trivy-gate-demo
echo "exit: $?"
```

The scan reports HIGH and CRITICAL findings and exits 1. In the pipeline, that
non-zero exit stops the run before sign and promote.

## Prove

Scan the real application image, built from `kubernetes/base/app`:

```
docker build -t sample-app kubernetes/base/app
trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed sample-app
echo "exit: $?"
```

The distroless static image reports no fixable HIGH or CRITICAL findings and exits
0, so the pipeline proceeds. The two runs side by side are the evidence that the
gate blocks a bad image and passes a clean one.
