package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
)

const usage = `check-unsaved — check git repos for uncommitted or unpushed changes

Usage:
  check-unsaved                              minimal summary (dirty repos only)
  check-unsaved -v                           verbose, all configured repos
  check-unsaved <path>                       verbose, one specific repo

  check-unsaved track <path> [-b branch]...
  check-unsaved track --scan <path> [-b branch]...
  check-unsaved untrack <path>

  check-unsaved global [-b branch]...        set global branches (authoritative)
  check-unsaved global                       show current global branches

  check-unsaved list                         print full config

Config: ~/.config/dots/tools/check-unsaved/config.toml
`

func main() {
	if len(os.Args) < 2 {
		runChecks("", false)
		return
	}

	switch os.Args[1] {
	case "track":
		runTrack(os.Args[2:])
	case "untrack":
		runUntrack(os.Args[2:])
	case "global":
		runGlobal(os.Args[2:])
	case "list":
		runList()
	case "-v":
		runChecks("", true)
	case "-h", "--help":
		fmt.Print(usage)
		os.Exit(0)
	default:
		if strings.HasPrefix(os.Args[1], "-") {
			fmt.Fprintf(os.Stderr, "Unknown flag: %s\n\n%s", os.Args[1], usage)
			os.Exit(1)
		}
		// Treat as a path: verbose check of a single repo.
		runChecks(os.Args[1], true)
	}
}

// --- subcommand runners ---

func runTrack(args []string) {
	// Manual parsing so that flags and path may appear in any order.
	// Supported: track <path> -b br, track -b br <path>, track --scan <path>
	var scan bool
	var branches []string
	var pathArg string

	i := 0
	for i < len(args) {
		a := args[i]
		switch {
		case a == "--scan" || a == "-scan":
			scan = true
			i++
		case a == "-b":
			if i+1 >= len(args) {
				fmt.Fprintln(os.Stderr, "Error: -b requires a value")
				os.Exit(1)
			}
			branches = append(branches, args[i+1])
			i += 2
		case strings.HasPrefix(a, "-b="):
			branches = append(branches, a[3:])
			i++
		case strings.HasPrefix(a, "-"):
			fmt.Fprintf(os.Stderr, "Unknown flag: %s\nUsage: check-unsaved track [--scan] <path> [-b branch]...\n", a)
			os.Exit(1)
		default:
			if pathArg != "" {
				fmt.Fprintln(os.Stderr, "Error: too many arguments\nUsage: check-unsaved track [--scan] <path> [-b branch]...")
				os.Exit(1)
			}
			pathArg = a
			i++
		}
	}

	if pathArg == "" {
		fmt.Fprintln(os.Stderr, "Usage: check-unsaved track [--scan] <path> [-b branch]...")
		os.Exit(1)
	}
	if err := cmdTrack(pathArg, scan, branches); err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}
}

func runUntrack(args []string) {
	if len(args) != 1 {
		fmt.Fprintln(os.Stderr, "Usage: check-unsaved untrack <path>")
		os.Exit(1)
	}
	if err := cmdUntrack(args[0]); err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}
}

func runGlobal(args []string) {
	fs := flag.NewFlagSet("global", flag.ExitOnError)
	var branches multiFlag
	fs.Var(&branches, "b", "Global branch (repeatable; replaces existing list)")
	fs.Usage = func() {
		fmt.Fprintln(os.Stderr, "Usage: check-unsaved global [-b branch]...")
	}
	if err := fs.Parse(args); err != nil {
		os.Exit(1)
	}
	if err := cmdGlobal([]string(branches)); err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}
}

func runList() {
	cfg, err := loadConfig()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}
	cmdList(cfg)
}

func runChecks(targetPath string, verbose bool) {
	cfg, err := loadConfig()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}

	// Single repo mode: check one path without requiring config.
	if targetPath != "" {
		abs := absPath(targetPath)
		branches := cfg.Branches
		for _, r := range cfg.Repos {
			if absPath(r.Path) == abs {
				branches = mergeBranches(branches, r.Branches)
				break
			}
		}
		status := checkRepo(abs, branches, true)
		printVerbose(status)
		if status.isDirty() {
			os.Exit(1)
		}
		return
	}

	if cfg.isEmpty() {
		fmt.Fprintln(os.Stderr, "No repos configured.\nUse 'check-unsaved track <path>' or 'check-unsaved track --scan <path>' to get started.")
		os.Exit(1)
	}

	// Collect statuses, deduplicating by absolute path.
	var statuses []RepoStatus
	seen := make(map[string]bool)

	for _, r := range cfg.Repos {
		abs := absPath(r.Path)
		if seen[abs] {
			continue
		}
		seen[abs] = true
		branches := mergeBranches(cfg.Branches, r.Branches)
		statuses = append(statuses, checkRepo(abs, branches, verbose))
	}

	for _, s := range cfg.Scans {
		abs := absPath(s.Path)
		if _, err := os.Stat(abs); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: scan path not found: %s\n", s.Path)
			continue
		}
		repos, err := findRepos(abs)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Warning: error scanning %s: %v\n", s.Path, err)
			continue
		}
		branches := mergeBranches(cfg.Branches, s.Branches)
		for _, repoPath := range repos {
			if seen[repoPath] {
				continue
			}
			seen[repoPath] = true
			statuses = append(statuses, checkRepo(repoPath, branches, verbose))
		}
	}

	dirty := false
	for _, s := range statuses {
		if !s.isDirty() {
			continue
		}
		dirty = true
		if verbose {
			printVerbose(s)
		} else {
			printMinimal(s)
		}
	}

	if dirty {
		os.Exit(1)
	}
}

// --- output formatters ---

func printMinimal(s RepoStatus) {
	var parts []string
	if n := len(s.Working); n > 0 {
		parts = append(parts, fmt.Sprintf("%d changed", n))
	}
	for _, b := range s.Branches {
		if b.Ahead > 0 {
			parts = append(parts, fmt.Sprintf("%s↑%d", b.Name, b.Ahead))
		}
	}
	fmt.Printf("%-40s  %s\n", s.Path, strings.Join(parts, "  "))
}

func printVerbose(s RepoStatus) {
	fmt.Println(s.Path)
	if len(s.Working) > 0 {
		fmt.Printf("  working copy: %d change(s)\n", len(s.Working))
		for _, l := range s.Working {
			fmt.Printf("    %s %s\n", l.Code, l.File)
		}
	}
	for _, b := range s.Branches {
		if b.Ahead > 0 {
			fmt.Printf("\n  %s: %d ahead\n", b.Name, b.Ahead)
			for _, c := range b.Commits {
				fmt.Printf("    %s\n", c)
			}
		}
	}
	fmt.Println()
}

// multiFlag allows a flag to be specified multiple times: -b foo -b bar
type multiFlag []string

func (m *multiFlag) String() string { return strings.Join(*m, ", ") }
func (m *multiFlag) Set(v string) error {
	*m = append(*m, v)
	return nil
}
