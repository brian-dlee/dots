package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

type Logger interface {
	Debug(msg string)
	DebugFn(msgFn func() string)
	Info(msg string)
	Warning(msg string)
}

type DefaultLogger struct{}

func NewDefaultLogger() Logger {
	return &DefaultLogger{}
}

func (l *DefaultLogger) Debug(msg string) {}

func (l *DefaultLogger) DebugFn(msgFn func() string) {}

func (l *DefaultLogger) Info(msg string) {}

func (l *DefaultLogger) Warning(msg string) {
	log.Println("[WARNING]", msg)
}

type VerboseLogger struct{}

func NewVerboseLogger() Logger {
	return &VerboseLogger{}
}

func (l *VerboseLogger) Debug(msg string) {
	log.Println("[DEBUG  ]", msg)
}

func (l *VerboseLogger) DebugFn(msgFn func() string) {
	log.Println("[DEBUG  ]", msgFn())
}

func (l *VerboseLogger) Info(msg string) {
	log.Println("[INFO   ]", msg)
}

func (l *VerboseLogger) Warning(msg string) {
	log.Println("[WARNING]", msg)
}

type PlatformPath struct {
	Path      string
	Drive     string
	IsWindows bool
}

func NewPlatformPath(inputPath string) (*PlatformPath, error) {
	isWindows := runtime.GOOS == "windows"
	barePath := inputPath
	drive := ""

	if isWindows {
		if len(inputPath) >= 2 {
			maybeDrive := strings.ToLower(inputPath)[0]
			maybeSep := inputPath[1]

			if 'a' <= maybeDrive && maybeDrive <= 'z' && maybeSep == ':' {
				drive = string(inputPath[0]) + ":"

				if len(inputPath) > 2 {
					barePath = inputPath[2:]
				} else {
					barePath = ""
				}
			}
		}
	}

	absoluteInputPath, err := filepath.Abs(barePath)
	if err != nil {
		return nil, err
	}

	return &PlatformPath{
		Path:      absoluteInputPath,
		Drive:     drive,
		IsWindows: isWindows,
	}, nil
}

func (p PlatformPath) SegmentCount() int {
	if p.Path == string(os.PathSeparator) {
		return 0
	}

	return strings.Count(p.Path, string(os.PathSeparator))
}

func (p PlatformPath) String() string {
	return fmt.Sprintf("%s%s", p.Drive, p.Path)
}

func reverseInPlace(elements []string) {
	total := len(elements)

	for i := 0; i < total/2; i++ {
		j := total - i - 1
		tmp := elements[i]
		elements[i] = elements[j]
		elements[j] = tmp
	}
}

func reverseCopy(elements []string) []string {
	clone := make([]string, len(elements))

	copy(clone, elements)
	reverseInPlace(clone)

	return clone
}

func yesish(envValue, defaultValue string) bool {
	value := envValue
	if value == "" {
		value = defaultValue
	} else {
		value = strings.ToLower(strings.TrimSpace(envValue))
	}

	switch value {
	case "1":
		return true
	case "y":
		return true
	case "yes":
		return true
	case "on":
		return true
	case "true":
		return true
	default:
		return false
	}
}

func main() {
	var logger Logger

	log.SetFlags(log.Ltime)

	if yesish(os.Getenv("DEBUG"), "0") {
		logger = NewVerboseLogger()
	} else {
		logger = NewDefaultLogger()
	}

	var userHomeDirPath *PlatformPath
	if result, err := os.UserHomeDir(); err != nil {
		logger.Warning(fmt.Sprintf("Unable to resolve user home directory: %s", err))
	} else {
		if result, err := NewPlatformPath(result); err != nil {
			logger.Warning(fmt.Sprintf("Failed to get user home directory: %s", err))
		} else {
			userHomeDirPath = result
		}
	}

	flagCompact := flag.Bool("compact", false, "Shorten intermediate path segments")
	flagMax := flag.Int("max", -1, "The max number of path segments to keep")
	flagMaxCompactChars := flag.Int("max-compact-chars", 3, "The maximum number of characters in a path segment to avoid appreviation")
	flag.Parse()

	args := flag.Args()

	if len(args) == 0 {
		log.Fatalf("No path provided. This tool requires a path to be supplied as an argument.")
	}

	inputPath := args[0]

	logger.Info(fmt.Sprintf("FLAG: compact           = %v", *flagCompact))
	logger.Info(fmt.Sprintf("FLAG: max               = %v", *flagMax))
	logger.Info(fmt.Sprintf("FLAG: max-compact-chars = %v", *flagMaxCompactChars))
	logger.Info(fmt.Sprintf("ARG:  path              = %v", inputPath))

	absolutePath, err := NewPlatformPath(inputPath)
	if err != nil {
		log.Fatalf("Failed to resolve absolute path for the provided path: %s", err)
	}

	logger.Debug(fmt.Sprintf("Absolute provided path '%s'", absolutePath))
	logger.Debug(fmt.Sprintf("User home path '%s'", userHomeDirPath))

	segments := strings.Split(absolutePath.Path, string(os.PathSeparator))

	// in absolute paths, the first segment is always empty
	segments = segments[1:]

	var resultPrefix string
	if userHomeDirPath != nil && strings.HasPrefix(absolutePath.String(), userHomeDirPath.String()) {
		logger.Debug("Using tilde as prefix: ~")

		resultPrefix = "~" + string(os.PathSeparator)
		segments = segments[userHomeDirPath.SegmentCount():]
	} else {
		logger.Debug(fmt.Sprintf("Using drive and root as prefix: %s", absolutePath))

		resultPrefix = absolutePath.Drive + string(os.PathSeparator)
	}

	reverseInPlace(segments)

	shortenedCount := len(segments) - *flagMax
	if shortenedCount < 0 {
		shortenedCount = 0
	}

	if *flagMax >= 0 {
		// this optimization prevents me from allocating during the `reverseCopy` call unless debug mode is active
		logger.DebugFn(func() string {
			return fmt.Sprintf("Only keeping %d segments max: %v", *flagMax, reverseCopy(segments))
		})

		if len(segments) > *flagMax {
			segments = segments[:*flagMax]
		}
	} else {
		// this optimization prevents me from allocating during the `reverseCopy` call unless debug mode is active
		logger.DebugFn(func() string {
			return fmt.Sprintf("Keeping original segments: %s", reverseCopy(segments))
		})

		shortenedCount = 0
	}

	result := make([]string, len(segments))
	for i, segment := range segments {
		if *flagCompact && i > 0 && len(segment) > *flagMaxCompactChars {
			result[i] = string(segment[0])
		} else {
			result[i] = segment
		}
	}

	reverseInPlace(result)

	if shortenedCount > 0 {
		logger.Debug(fmt.Sprintf("Inserting elipsis due to path being shortened by %d.", shortenedCount))

		resultPrefix += "…" + string(os.PathSeparator)
	}

	output := resultPrefix
	output += strings.Join(result, string(os.PathSeparator))

	fmt.Println(strings.TrimRight(output, string(os.PathSeparator)))
}
