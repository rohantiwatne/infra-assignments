package repository

import (
	"context"
	"errors"

	"github.com/example/kubernetes-config-service/app/internal/domain"
)

var ErrNotFound = errors.New("config not found")

type Repository interface {
	GetByID(ctx context.Context, id string) (*domain.Config, error)
	Upsert(ctx context.Context, config *domain.Config) error
}
