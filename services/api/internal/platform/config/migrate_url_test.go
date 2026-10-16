package config

import "testing"

func TestMigrateDatabaseURLFallsBackToDatabaseURL(t *testing.T) {
	t.Setenv("APP_ENV", "test")
	t.Setenv("DATABASE_URL", "postgres://terra_api:x@db:5432/terra")
	t.Setenv("MIGRATE_DATABASE_URL", "")
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if c.MigrateDatabaseURL != c.DatabaseURL {
		t.Fatalf("MigrateDatabaseURL = %q, want DATABASE_URL %q", c.MigrateDatabaseURL, c.DatabaseURL)
	}

	t.Setenv("MIGRATE_DATABASE_URL", "postgres://terra:y@db:5432/terra")
	c, err = Load()
	if err != nil {
		t.Fatal(err)
	}
	if c.MigrateDatabaseURL != "postgres://terra:y@db:5432/terra" || c.DatabaseURL != "postgres://terra_api:x@db:5432/terra" {
		t.Fatalf("got migrate=%q api=%q", c.MigrateDatabaseURL, c.DatabaseURL)
	}
}
