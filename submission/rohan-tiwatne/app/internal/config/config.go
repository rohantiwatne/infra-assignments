package config

import (
	"fmt"
	"os"
)

type DatabaseConfig struct {
	Host     string
	Port     string
	Name     string
	User     string
	Password string
}

type Config struct {
	ServerPort string
	Database   DatabaseConfig
}

func Load() (Config, error) {
	cfg := Config{
		ServerPort: getenv("SERVER_PORT", "8080"),
		Database: DatabaseConfig{
			Host:     os.Getenv("DB_HOST"),
			Port:     getenv("DB_PORT", "5432"),
			Name:     os.Getenv("DB_NAME"),
			User:     os.Getenv("DB_USER"),
			Password: os.Getenv("DB_PASSWORD"),
		},
	}

	switch {
	case cfg.Database.Host == "":
		return Config{}, fmt.Errorf("DB_HOST is required")
	case cfg.Database.Name == "":
		return Config{}, fmt.Errorf("DB_NAME is required")
	case cfg.Database.User == "":
		return Config{}, fmt.Errorf("DB_USER is required")
	case cfg.Database.Password == "":
		return Config{}, fmt.Errorf("DB_PASSWORD is required")
	}

	return cfg, nil
}

func getenv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
