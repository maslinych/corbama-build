#!/bin/sh
environment="$1"
shift
tmux has-session -t "$environment" || "$environment is not running" && exit 0
tmux send-keys -t "$environment":0 \"service httpd2 stop\" Enter && 
tmux kill-session -t "$environment"
