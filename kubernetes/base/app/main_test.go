package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthzReturnsOK(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rec := httptest.NewRecorder()

	newMux().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("healthz status = %d, want %d", rec.Code, http.StatusOK)
	}
	body, _ := io.ReadAll(rec.Result().Body)
	if string(body) != "ok\n" {
		t.Fatalf("healthz body = %q, want %q", string(body), "ok\n")
	}
}

func TestRootReportsVersion(t *testing.T) {
	t.Setenv("APP_VERSION", "1.2.3")

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rec := httptest.NewRecorder()

	newMux().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("root status = %d, want %d", rec.Code, http.StatusOK)
	}
	body, _ := io.ReadAll(rec.Result().Body)
	want := "eks-gitops-platform sample app, version 1.2.3\n"
	if string(body) != want {
		t.Fatalf("root body = %q, want %q", string(body), want)
	}
}
