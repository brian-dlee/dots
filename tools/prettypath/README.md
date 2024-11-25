# prettypath

A small utility for computing a shortened (or _pretty_) display for a provided path
utilizing a shortening algorithm so long paths do not use so many characters while
still being familiar enough to recognize. This tool is designed to be used within
a shell/tmux environment to display the active path in a particular session.

I've tried to write this tool with performance in mind, as it should run very fast
given that it may be executed often as per the render cycle of a terminal
environment.
