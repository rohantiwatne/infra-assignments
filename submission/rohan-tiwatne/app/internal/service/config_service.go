package service

import (
	"context"
	"fmt"
	"strings"

	"github.com/example/kubernetes-config-service/app/internal/domain"
	"github.com/example/kubernetes-config-service/app/internal/repository"
)

type ConfigRepository interface {
	GetByID(ctx context.Context, id string) (*domain.Config, error)
	Upsert(ctx context.Context, config *domain.Config) error
}

type ConfigService struct {
	repository ConfigRepository
}

func New(repository ConfigRepository) *ConfigService {
	return &ConfigService{repository: repository}
}

func (s *ConfigService) Get(ctx context.Context, id string) (*domain.Config, error) {
	id = strings.TrimSpace(id)
	if id == "" {
		return nil, fmt.Errorf("id is required")
	}
	return s.repository.GetByID(ctx, id)
}

func (s *ConfigService) Upsert(ctx context.Context, cfg *domain.Config) error {
	if err := validate(cfg); err != nil {
		return err
	}
	return s.repository.Upsert(ctx, cfg)
}

func validate(cfg *domain.Config) error {
	if cfg == nil {
		return fmt.Errorf("request body is required")
	}
	cfg.ID = strings.TrimSpace(cfg.ID)
	cfg.Host = strings.TrimSpace(cfg.Host)
	cfg.AppName = strings.TrimSpace(cfg.AppName)
	cfg.LogLevel = strings.TrimSpace(cfg.LogLevel)

	switch {
	case cfg.ID == "":
		return fmt.Errorf("id is required")
	case cfg.Host == "":
		return fmt.Errorf("host is required")
	case cfg.Port < 1 || cfg.Port > 65535:
		return fmt.Errorf("port must be between 1 and 65535")
	case cfg.AppName == "":
		return fmt.Errorf("app_name is required")
	case cfg.LogLevel == "":
		return fmt.Errorf("log_level is required")
	default:
		return nil
	}
}

var ErrNotFound = repository.ErrNotFound
