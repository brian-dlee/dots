package main

import (
	"bufio"
	"fmt"
	"net/url"
	"os"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)

	for scanner.Scan() {
		input := scanner.Text()
		encoded := url.QueryEscape(input)
		fmt.Println(encoded)
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "failed to read stdin:", err)
	}
}
