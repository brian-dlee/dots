package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

// StatusLine represents one line of `git status --porcelain` output.
type StatusLine struct {
	Code string // two-char code, e.g. " M", "??", "A "
	File string
}

// BranchResult holds the ahead count for a single branch.
type BranchResult struct {
	Name    string
	Ahead   int
	Commits []string // populated only in verbose mode
}

// RepoStatus holds all check results for one repository.
type RepoStatus struct {
	Path     string
	Working  []StatusLine
	Branches []BranchResult
}

func (r RepoStatus) isDirty() bool {
	if len(r.Working) > 0 {
		return true
	}
	for _, b := range r.Branches {
		if b.Ahead > 0 {
			return true
		}
	}
	return false
}

// gitStatus runs `git status --porcelain` and returns parsed lines.
func gitStatus(repoPath string) ([]StatusLine, error) {
	out, err := exec.Command("git", "-C", repoPath, "status", "--porcelain").Output()
	if err != nil {
		return nil, err
	}
	var lines []StatusLine
	for _, line := range strings.Split(strings.TrimRight(string(out), "\n"), "\n") {
		if len(line) < 4 {
			continue
		}
		lines = append(lines, StatusLine{
			Code: line[:2],
			File: line[3:],
		})
	}
	return lines, nil
}

// gitBranchStatus returns the number of commits on branch that haven't been
// pushed to the configured upstream (or any remote if no upstream is set).
// Returns a zero BranchResult (Ahead=0) if the branch doesn't exist locally.
// In verbose mode it also populates Commits with oneline summaries.
func gitBranchStatus(repoPath, branch string, verbose bool) BranchResult {
	result := BranchResult{Name: branch}

	// Confirm the branch exists locally.
	if err := exec.Command("git", "-C", repoPath, "rev-parse", "--verify", "--quiet", "refs/heads/"+branch).Run(); err != nil {
		return result
	}

	// Count commits ahead of upstream. Fall back to "not on any remote"
	// if no upstream is configured for the branch.
	upstream := branch + "@{upstream}"
	countOut, err := exec.Command("git", "-C", repoPath, "rev-list", "--count", upstream+".."+branch).Output()
	if err != nil {
		// No upstream configured — count commits not pushed to any remote.
		countOut, err = exec.Command("git", "-C", repoPath, "rev-list", "--count", "refs/heads/"+branch, "--not", "--remotes").Output()
		if err != nil {
			return result
		}
		upstream = "" // signals fallback path for commit listing below
	}

	ahead, err := strconv.Atoi(strings.TrimSpace(string(countOut)))
	if err != nil || ahead == 0 {
		return result
	}
	result.Ahead = ahead

	if verbose {
		var logOut []byte
		if upstream != "" {
			logOut, err = exec.Command("git", "-C", repoPath, "log", "--oneline", upstream+".."+branch).Output()
		}
		if upstream == "" || err != nil {
			logOut, _ = exec.Command("git", "-C", repoPath, "log", "--oneline", "refs/heads/"+branch, "--not", "--remotes").Output()
		}
		for _, line := range strings.Split(strings.TrimRight(string(logOut), "\n"), "\n") {
			if line != "" {
				result.Commits = append(result.Commits, line)
			}
		}
	}

	return result
}

// checkRepo collects working copy status and branch ahead-counts for a repo.
func checkRepo(repoPath string, branches []string, verbose bool) RepoStatus {
	status := RepoStatus{Path: contractHome(repoPath)}
	status.Working, _ = gitStatus(repoPath)
	for _, branch := range branches {
		result := gitBranchStatus(repoPath, branch, verbose)
		// Only include branches that exist locally.
		if result.Name != "" && (result.Ahead > 0 || branchExists(repoPath, branch)) {
			status.Branches = append(status.Branches, result)
		}
	}
	return status
}

// branchExists returns true if the branch exists locally in the given repo.
func branchExists(repoPath, branch string) bool {
	return exec.Command("git", "-C", repoPath, "rev-parse", "--verify", "--quiet", "refs/heads/"+branch).Run() == nil
}

// findRepos walks scanPath and returns paths of all directories containing
// a .git subdirectory, without descending into nested repos.
func findRepos(scanPath string) ([]string, error) {
	var repos []string
	err := filepath.Walk(scanPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // skip unreadable entries
		}
		if info.IsDir() && info.Name() == ".git" {
			repos = append(repos, filepath.Dir(path))
			return filepath.SkipDir
		}
		return nil
	})
	return repos, err
}
