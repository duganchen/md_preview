#!/usr/bin/env bash

# A Markdown previewer to use in TMUX.

# This takes the path to the Markdown file you want to preview. In your current tmux pane, it starts up a watcher for changes
# that file. It also opens another tmux pane with a live server to serve up a preview. In most cases, the preview should then
# automatically open in your web browser. When you're done, go to the file watcher and press "q". It will close both the
# watcher and the server.

# This system uses the following:
# * tmux (of course)
# * "killercup"'s CSS (https://gist.github.com/killercup/5917178)
# * entr (http://www.entrproject.org/)
# * pandoc
# * live-server (http://tapiov.net/live-server/)


# Possible alternative CSS:
# http://benjam.info/panam/
# https://gist.github.com/killercup/5917178

TEMP=$(mktemp -d)
MD=$(realpath "$1")

# Note the "gfm", which means to hardcode for GitHub-flavored Markdown.

CSS=https://rawgit.com/otsaloma/markdown-css/master/tufte.css

pandoc -f gfm -t html -o "$TEMP/preview.html" -s -c "$CSS" --quiet "$MD"

mkfifo "$TEMP/pipe.fifo"
tmux split-window \; send-keys "echo \$TMUX_PANE > $TEMP/pipe.fifo" Enter \; select-pane -t "$TMUX_PANE"
SERVER_PANE=$(cat "$TEMP/pipe.fifo")
tmux send-keys -t "$SERVER_PANE" "cd $TEMP ; live-server preview.html" Enter

echo "$MD" | entr -s "pandoc -f gfm -t html -o $TEMP/preview.html -s -c $CSS $TEMP/pandoc.css --quiet $MD"
tmux kill-pane -t "$SERVER_PANE"
rm -rf "$TEMP"

