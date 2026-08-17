package service_test

import (
	"context"
	"testing"

	"github.com/example/kubernetes-config-service/app/internal/domain"
	"github.com/example/kubernetes-config-service/app/internal/service"
)

type fakeRepository struct {
	value *domain.Config
}

func (f *fakeRepository) GetByID(ctx context.Context, id string) (*domain.Config, error) {
	return f.value, nil
}

func (f *fakeRepository) Upsert(ctx context.Context, cfg *domain.Config) error {
	f.value = cfg
	return nil
}

func TestUpsertValidation(t *testing.T) {
	svc := service.New(&fakeRepository{})

	err := svc.Upsert(context.Background(), &domain.Config{
		ID:       "cfg_1",
		Host:     "localhost",
		Port:     8080,
		AppName:  "config-service",
		LogLevel: "INFO",
	})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
}

func TestRejectInvalidPort(t *testing.T) {
	svc := service.New(&fakeRepository{})

	err := svc.Upsert(context.Background(), &domain.Config{
		ID:       "cfg_1",
		Host:     "localhost",
		Port:     70000,
		AppName:  "config-service",
		LogLevel: "INFO",
	})
	if err == nil {
		t.Fatal("expected invalid port error")
	}
}
