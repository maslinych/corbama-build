#!/bin/sh
environment="$1"
shift
tmux has-session -t "$environment" || \
    tmux new-session -d -s "$environment" "export share_network=1 ; hsh-shell --root --mount=/proc $environment" && \
    sleep 5 && \
    tmux send-keys -t "$environment":0 "service httpd2 start" Enter
