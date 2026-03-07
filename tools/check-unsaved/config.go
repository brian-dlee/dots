package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/BurntSushi/toml"
)

const configFile = "~/.config/dots/tools/check-unsaved/config.toml"

// Config is the top-level structure of the TOML config file.
type Config struct {
	Branches []string    `toml:"branches"`
	Repos    []RepoEntry `toml:"repo"`
	Scans    []ScanEntry `toml:"scan"`
}

// RepoEntry is an explicit git repo to check.
type RepoEntry struct {
	Path     string   `toml:"path"`
	Branches []string `toml:"branches,omitempty"`
}

// ScanEntry is a directory to scan recursively for git repos.
type ScanEntry struct {
	Path     string   `toml:"path"`
	Branches []string `toml:"branches,omitempty"`
}

func (c *Config) isEmpty() bool {
	return len(c.Repos) == 0 && len(c.Scans) == 0
}

// expandHome replaces a leading ~ with the user's home directory.
func expandHome(path string) string {
	if path == "~" {
		home, _ := os.UserHomeDir()
		return home
	}
	if strings.HasPrefix(path, "~/") {
		home, _ := os.UserHomeDir()
		return filepath.Join(home, path[2:])
	}
	return path
}

// contractHome replaces a leading home directory path with ~.
func contractHome(path string) string {
	home, err := os.UserHomeDir()
	if err != nil {
		return path
	}
	if path == home {
		return "~"
	}
	if strings.HasPrefix(path, home+string(os.PathSeparator)) {
		return "~" + path[len(home):]
	}
	return path
}

// normalizePath expands ~, resolves to absolute, then contracts ~ back.
// This gives a canonical "~/..." form suitable for storage and display.
func normalizePath(path string) (string, error) {
	expanded := expandHome(path)
	abs, err := filepath.Abs(expanded)
	if err != nil {
		return "", err
	}
	return contractHome(abs), nil
}

// absPath expands and resolves a path to absolute form.
func absPath(path string) string {
	expanded := expandHome(path)
	abs, err := filepath.Abs(expanded)
	if err != nil {
		return expanded
	}
	return abs
}

// configFilePath returns the absolute path to the config file.
func configFilePath() string {
	return expandHome(configFile)
}

// loadConfig reads the config file. Returns an empty config if the file
// doesn't exist yet (not an error — first run).
func loadConfig() (*Config, error) {
	path := configFilePath()
	cfg := &Config{}
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return cfg, nil
	}
	if _, err := toml.DecodeFile(path, cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config %s: %w", path, err)
	}
	return cfg, nil
}

// saveConfig writes the config to disk, creating directories as needed.
func saveConfig(cfg *Config) error {
	path := configFilePath()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}
	f, err := os.Create(path)
	if err != nil {
		return fmt.Errorf("failed to write config: %w", err)
	}
	defer f.Close()
	return toml.NewEncoder(f).Encode(cfg)
}

// mergeBranches merges global and local branch lists, deduplicating.
func mergeBranches(global, local []string) []string {
	seen := make(map[string]bool)
	var merged []string
	for _, b := range global {
		if !seen[b] {
			seen[b] = true
			merged = append(merged, b)
		}
	}
	for _, b := range local {
		if !seen[b] {
			seen[b] = true
			merged = append(merged, b)
		}
	}
	return merged
}

// cmdTrack adds or updates a repo or scan entry. Subsequent calls are
// authoritative: the existing entry for that path is replaced entirely.
func cmdTrack(path string, scan bool, branches []string) error {
	normalized, err := normalizePath(path)
	if err != nil {
		return fmt.Errorf("invalid path %q: %w", path, err)
	}
	cfg, err := loadConfig()
	if err != nil {
		return err
	}

	// Remove any existing entry for this path regardless of type.
	cfg.Repos = filterRepos(cfg.Repos, normalized)
	cfg.Scans = filterScans(cfg.Scans, normalized)

	if scan {
		entry := ScanEntry{Path: normalized}
		if len(branches) > 0 {
			entry.Branches = branches
		}
		cfg.Scans = append(cfg.Scans, entry)
		fmt.Fprintf(os.Stderr, "Tracking scan: %s\n", normalized)
	} else {
		entry := RepoEntry{Path: normalized}
		if len(branches) > 0 {
			entry.Branches = branches
		}
		cfg.Repos = append(cfg.Repos, entry)
		fmt.Fprintf(os.Stderr, "Tracking repo: %s\n", normalized)
	}
	return saveConfig(cfg)
}

// cmdUntrack removes an entry by path, whether it's a repo or scan.
func cmdUntrack(path string) error {
	normalized, err := normalizePath(path)
	if err != nil {
		return fmt.Errorf("invalid path %q: %w", path, err)
	}
	cfg, err := loadConfig()
	if err != nil {
		return err
	}

	beforeRepos := len(cfg.Repos)
	beforeScans := len(cfg.Scans)
	cfg.Repos = filterRepos(cfg.Repos, normalized)
	cfg.Scans = filterScans(cfg.Scans, normalized)

	if len(cfg.Repos) == beforeRepos && len(cfg.Scans) == beforeScans {
		fmt.Fprintf(os.Stderr, "Not tracked: %s\n", normalized)
		return nil
	}
	fmt.Fprintf(os.Stderr, "Untracked: %s\n", normalized)
	return saveConfig(cfg)
}

// cmdGlobal shows or updates the global branches list.
// With no branches, it prints the current setting.
// With branches, it replaces the global list (authoritative).
func cmdGlobal(branches []string) error {
	cfg, err := loadConfig()
	if err != nil {
		return err
	}
	if len(branches) == 0 {
		if len(cfg.Branches) == 0 {
			fmt.Println("Global branches: (none)")
		} else {
			fmt.Printf("Global branches: %s\n", strings.Join(cfg.Branches, ", "))
		}
		return nil
	}
	cfg.Branches = branches
	if err := saveConfig(cfg); err != nil {
		return err
	}
	fmt.Fprintf(os.Stderr, "Set global branches: %s\n", strings.Join(branches, ", "))
	return nil
}

// cmdList prints a human-readable summary of the current config.
func cmdList(cfg *Config) {
	if len(cfg.Branches) == 0 {
		fmt.Println("Global branches: (none)")
	} else {
		fmt.Printf("Global branches: %s\n", strings.Join(cfg.Branches, ", "))
	}

	if len(cfg.Repos) > 0 {
		fmt.Println("\nRepos:")
		for _, r := range cfg.Repos {
			if len(r.Branches) > 0 {
				fmt.Printf("  %-40s  branches: %s\n", r.Path, strings.Join(r.Branches, ", "))
			} else {
				fmt.Printf("  %s\n", r.Path)
			}
		}
	}

	if len(cfg.Scans) > 0 {
		fmt.Println("\nScan directories:")
		for _, s := range cfg.Scans {
			if len(s.Branches) > 0 {
				fmt.Printf("  %-40s  branches: %s\n", s.Path, strings.Join(s.Branches, ", "))
			} else {
				fmt.Printf("  %s\n", s.Path)
			}
		}
	}
}

func filterRepos(repos []RepoEntry, normalized string) []RepoEntry {
	var result []RepoEntry
	for _, r := range repos {
		if r.Path != normalized {
			result = append(result, r)
		}
	}
	return result
}

func filterScans(scans []ScanEntry, normalized string) []ScanEntry {
	var result []ScanEntry
	for _, s := range scans {
		if s.Path != normalized {
			result = append(result, s)
		}
	}
	return result
}
