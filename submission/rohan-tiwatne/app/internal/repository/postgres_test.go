package repository_test

import (
	"testing"

	"github.com/example/kubernetes-config-service/app/internal/repository"
)

func TestNotFoundSentinelIsAvailable(t *testing.T) {
	if repository.ErrNotFound == nil {
		t.Fatal("ErrNotFound must be initialized")
	}
}
