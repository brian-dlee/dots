package main

import (
	"flag"
	"fmt"
	"os"
	"sort"
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

// --- color ---

type palette struct {
	bold   string
	dim    string
	reset  string
	red    string
	yellow string
	cyan   string
}

var clr palette

func initColors() {
	fi, err := os.Stdout.Stat()
	if err == nil && fi.Mode()&os.ModeCharDevice != 0 {
		clr = palette{
			bold:   "\033[1m",
			dim:    "\033[2m",
			reset:  "\033[0m",
			red:    "\033[31m",
			yellow: "\033[33m",
			cyan:   "\033[36m",
		}
	}
}

func main() {
	initColors()

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
		runChecks(os.Args[1], true)
	}
}

// --- subcommand runners ---

func runTrack(args []string) {
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

// resolveBranches returns the local branches for repoAbsPath using the most
// specific matching config entry:
//   - An exact [[repo]] match always wins.
//   - Otherwise, the [[scan]] entry with the longest matching path prefix wins.
func resolveBranches(cfg *Config, repoAbsPath string) []string {
	for _, r := range cfg.Repos {
		if absPath(r.Path) == repoAbsPath {
			return r.Branches
		}
	}
	var best []string
	bestLen := -1
	for _, s := range cfg.Scans {
		scanAbs := absPath(s.Path)
		if strings.HasPrefix(repoAbsPath, scanAbs+string(os.PathSeparator)) && len(scanAbs) > bestLen {
			bestLen = len(scanAbs)
			best = s.Branches
		}
	}
	return best
}

func runChecks(targetPath string, verbose bool) {
	cfg, err := loadConfig()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}

	// Single repo mode.
	if targetPath != "" {
		abs := absPath(targetPath)
		branches := mergeBranches(cfg.Branches, resolveBranches(cfg, abs))
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

	// Phase 1: Discover all unique repo absolute paths.
	seen := make(map[string]bool)
	var allPaths []string

	for _, r := range cfg.Repos {
		abs := absPath(r.Path)
		if !seen[abs] {
			seen[abs] = true
			allPaths = append(allPaths, abs)
		}
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
		for _, repoPath := range repos {
			if !seen[repoPath] {
				seen[repoPath] = true
				allPaths = append(allPaths, repoPath)
			}
		}
	}

	sort.Strings(allPaths)

	// Phase 2: Resolve branches per repo.
	type job struct {
		path     string
		branches []string
	}
	jobs := make([]job, len(allPaths))
	for i, p := range allPaths {
		jobs[i] = job{
			path:     p,
			branches: mergeBranches(cfg.Branches, resolveBranches(cfg, p)),
		}
	}

	// Phase 3: Check repos in parallel (8 workers). Each job writes to its own
	// buffered channel. The main goroutine reads channels in sorted order so
	// output streams out as results become available, preserving alphabetic order.
	const workers = 8
	channels := make([]chan RepoStatus, len(jobs))
	for i := range channels {
		channels[i] = make(chan RepoStatus, 1)
	}

	sem := make(chan struct{}, workers)
	for i, j := range jobs {
		go func(ch chan RepoStatus, j job) {
			sem <- struct{}{}
			defer func() { <-sem }()
			ch <- checkRepo(j.path, j.branches, verbose)
		}(channels[i], j)
	}

	dirty := false
	for _, ch := range channels {
		s := <-ch
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

// --- output ---

const minPathWidth = 40

func printMinimal(s RepoStatus) {
	var parts []string
	if n := len(s.Working); n > 0 {
		word := "changes"
		if n == 1 {
			word = "change"
		}
		parts = append(parts, clr.yellow+fmt.Sprintf("%d %s", n, word)+clr.reset)
	}
	for _, b := range s.Branches {
		if b.Ahead > 0 {
			parts = append(parts, clr.red+fmt.Sprintf("%s↑%d", b.Name, b.Ahead)+clr.reset)
		}
	}

	// Pad using visible length of path, not the colored string.
	pad := minPathWidth - len(s.Path)
	if pad < 2 {
		pad = 2
	}
	fmt.Printf("%s%s%s%s%s\n",
		clr.bold+clr.cyan, s.Path, clr.reset,
		strings.Repeat(" ", pad),
		strings.Join(parts, "  "),
	)
}

func printVerbose(s RepoStatus) {
	fmt.Printf("%s%s%s\n", clr.bold+clr.cyan, s.Path, clr.reset)

	if n := len(s.Working); n > 0 {
		word := "changes"
		if n == 1 {
			word = "change"
		}
		fmt.Printf("  %sworking copy: %d %s%s\n", clr.yellow, n, word, clr.reset)
		for _, l := range s.Working {
			fmt.Printf("    %s%s%s %s\n", clr.dim, l.Code, clr.reset, l.File)
		}
	}

	for _, b := range s.Branches {
		if b.Ahead > 0 {
			fmt.Printf("\n  %s%s%s: %s%d ahead%s\n",
				clr.bold, b.Name, clr.reset,
				clr.red, b.Ahead, clr.reset,
			)
			for _, c := range b.Commits {
				// git --oneline format: "<hash> <message>"
				if parts := strings.SplitN(c, " ", 2); len(parts) == 2 {
					fmt.Printf("    %s%s%s %s\n", clr.dim, parts[0], clr.reset, parts[1])
				} else {
					fmt.Printf("    %s\n", c)
				}
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
