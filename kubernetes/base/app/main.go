// A small, honest HTTP service for the GitOps demo. It serves a greeting on "/"
// and a readiness and liveness probe on "/healthz", and reads its version from
// the environment so a deployment can change what it reports without a rebuild.
// Its only job is to be built, scanned, signed, delivered by ArgoCD and observed,
// so the platform's controls can be shown working on a real workload.
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

// version is reported on the root path. A deployment sets APP_VERSION; the
// default keeps local runs honest about being unversioned.
func version() string {
	if v := os.Getenv("APP_VERSION"); v != "" {
		return v
	}
	return "dev"
}

// newMux builds the HTTP routes. It is separated from main so the tests can
// exercise the handlers without binding a port.
func newMux() *http.ServeMux {
	mux := http.NewServeMux()

	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "ok")
	})

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "eks-gitops-platform sample app, version %s\n", version())
	})

	return mux
}

func main() {
	addr := ":8080"
	if p := os.Getenv("PORT"); p != "" {
		addr = ":" + p
	}

	log.Printf("sample app %s listening on %s", version(), addr)
	if err := http.ListenAndServe(addr, newMux()); err != nil {
		log.Fatal(err)
	}
}
