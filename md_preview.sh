#!/usr/bin/env bash

function preview_help {
cat <<-EOF
md_preview [OPTIONS] [FILE]
Previews the Markdown FILE.
  -f FORMAT
  -c URL
  -h
EOF
}

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
    \?)
      preview_help
      exit 1
      ;;
  esac

done

shift $((OPTIND - 1))

if [[ "$1" == "" ]]; then
  preview_help
  exit 1
fi

if ! [ -f "$1" ] ; then
  echo "Please specify a Markdown file to preview"  >&2
  exit 1
fi

# This sanity check at least works on slackware-current and OS X.
FILETYPE=$(file "$1" | awk -F ': ' '{print $2}')
if [[  "$FILETYPE" != "ASCII text"* && $FILETYPE != "empty" ]]; then
  echo "$1 is not a Markdown file."  >&2
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

