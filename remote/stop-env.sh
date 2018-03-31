#!/bin/sh
environment="$1"
shift
tmux send-keys -t "$environment":0 \"service httpd2 stop\" Enter
tmux kill-session -t "$environment"
