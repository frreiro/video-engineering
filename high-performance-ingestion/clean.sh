#!/bin/bash

pkill ffplay || true

sudo tc qdisc del dev veth-loss root 2>/dev/null || true

sudo ip link del veth-clean 2>/dev/null || true
sudo ip link del veth-loss 2>/dev/null || true

echo "Ambiente removido."