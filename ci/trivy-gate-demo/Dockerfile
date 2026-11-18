# A throwaway image whose only purpose is to demonstrate the Trivy gate failing.
# It pins a deliberately old base with known, fixable HIGH and CRITICAL findings,
# so a scan with the same severity threshold the pipeline uses exits non-zero.
# This is not the sample app and is never deployed or signed; it proves the gate
# stops a bad image before promotion.
FROM debian:11.3

# No application. The base alone carries the findings the gate must catch.
CMD ["true"]
