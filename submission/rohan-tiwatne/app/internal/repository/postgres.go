package repository

import (
	"context"
	"errors"

	"github.com/example/kubernetes-config-service/app/internal/domain"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Postgres struct {
	db *pgxpool.Pool
}

func NewPostgres(db *pgxpool.Pool) *Postgres {
	return &Postgres{db: db}
}

func (r *Postgres) GetByID(ctx context.Context, id string) (*domain.Config, error) {
	var cfg domain.Config

	err := r.db.QueryRow(ctx, `
		SELECT id, host, port, app_name, log_level
		FROM configs
		WHERE id = $1
	`, id).Scan(
		&cfg.ID,
		&cfg.Host,
		&cfg.Port,
		&cfg.AppName,
		&cfg.LogLevel,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	return &cfg, nil
}

func (r *Postgres) Upsert(ctx context.Context, config *domain.Config) error {
	_, err := r.db.Exec(ctx, `
		INSERT INTO configs (id, host, port, app_name, log_level)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (id)
		DO UPDATE SET
			host = EXCLUDED.host,
			port = EXCLUDED.port,
			app_name = EXCLUDED.app_name,
			log_level = EXCLUDED.log_level,
			updated_at = NOW()
	`,
		config.ID,
		config.Host,
		config.Port,
		config.AppName,
		config.LogLevel,
	)

	return err
}
