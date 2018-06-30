#!/usr/bin/env bash

if [[ "$TMUX_PANE" == "" ]]; then
  echo "You can only md_preview inside tmux" >&2
  exit 1
fi

if ! [ -x "$(command -v live-server)" ] ; then
  echo "Please install live-server"  >&2
  exit 1
fi

if ! [ -x "$(command -v entr)" ] ; then
  echo "Please install entr"  >&2
  exit 1
fi

if ! [ -x "$(command -v pandoc)" ] ; then
  echo "Please install pandoc"  >&2
  exit 1
fi

CSS=${CSS:-https://rawgit.com/otsaloma/markdown-css/master/tufte.css}
FROM=${FROM:-gfm}
DIRECTION=${DIRECTION:-"-v"}

while getopts ":c:f:h" opt; do

  case "$opt" in
    c)
      CSS="$OPTARG"
      ;;
    f)
      FROM="$OPTARG"
      ;;
    h)
      DIRECTION="-h"
      ;;
  esac

done

shift $((OPTIND - 1))

if ! [ -f "$1" ] ; then
  echo "Please specify a file to preview"  >&22
  exit 1
fi

TEMP=$(mktemp -d)
MD=$(realpath "$1")

pandoc -f "$FROM" -t html -o "$TEMP/preview.html" -s -c "$CSS" --quiet "$MD"

mkfifo "$TEMP/pipe.fifo"
tmux split-window "$DIRECTION" \; send-keys "echo \$TMUX_PANE > $TEMP/pipe.fifo" Enter \; select-pane -t "$TMUX_PANE"
SERVER_PANE=$(cat "$TEMP/pipe.fifo")
tmux send-keys -t "$SERVER_PANE" "cd $TEMP ; live-server preview.html" Enter

echo "$MD" | entr -s "pandoc -f $FROM -t html -o $TEMP/preview.html -s -c $CSS --quiet $MD"
tmux kill-pane -t "$SERVER_PANE"
rm -rf "$TEMP"

