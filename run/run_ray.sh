#!/bin/bash

export VLLM_HOST_IP=$(hostname -I | awk '{print $1}')

if [ -z "$MASTER_ADDR" ]; then
    echo "Error: MASTER_ADDR is not set!"
    exit 1
fi

export VLLM_MASTER_IP=$(getent hosts "$MASTER_ADDR" | awk '{ print $1 }' || echo "127.0.0.1")

echo "MASTER_ADDR: $MASTER_ADDR"
echo "VLLM_HOST_IP: $VLLM_HOST_IP"
echo "VLLM_MASTER_IP: $VLLM_MASTER_IP"

ray stop -f
sleep 1

if [ "$VLLM_MASTER_IP" = "$VLLM_HOST_IP" ]; then
    echo "Starting Ray as HEAD node..."
    ray start --head --port=6379 --dashboard-host=0.0.0.0
else
    echo "Starting Ray as worker node, connecting to $VLLM_MASTER_IP..."
    ray start --address="$VLLM_MASTER_IP:6379"
fi

# 建议加一点时间缓冲
sleep 3

if ray status > /dev/null 2>&1; then
    echo "Ray started successfully!"
else
    echo "Ray start failed. See /tmp/ray/session_latest/logs/ for details."
    exit 2
fi
