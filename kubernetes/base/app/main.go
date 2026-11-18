// A small, honest HTTP service for the GitOps demo. It serves a greeting on "/"
// and a readiness and liveness probe on "/healthz", and reads its version from
// the environment so a deployment can change what it reports without a rebuild.
// Its only job is to be built, scanned, signed, delivered by ArgoCD and observed,
// so the platform's controls can be shown working on a real workload.
package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
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

	// Timeouts bound how long a client may hold a connection open, which closes
	// off the Slowloris class of slow-client attacks. Without them a few idle
	// connections can tie the server up.
	srv := &http.Server{
		Addr:              addr,
		Handler:           newMux(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	// Kubernetes sends SIGTERM before it removes a pod during a rolling update.
	// Catch it, stop accepting new connections, and drain the in-flight ones so
	// no request is cut off mid-response.
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		log.Printf("sample app %s listening on %s", version(), addr)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("listen: %v", err)
		}
	}()

	<-ctx.Done()
	stop()
	log.Println("shutdown signal received, draining connections")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("graceful shutdown failed: %v", err)
	}
	log.Println("stopped cleanly")
}
