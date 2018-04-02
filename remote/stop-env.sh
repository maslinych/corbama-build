#!/bin/sh
environment="$1"
shift
tmux has-session -t "$environment" && \
    tmux send-keys -t "$environment":0 \"service httpd2 stop\" Enter && \
    tmux kill-session -t "$environment"
