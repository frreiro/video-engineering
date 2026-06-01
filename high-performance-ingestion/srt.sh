#!/bin/bash

set -e

echo "Limpando ambiente anterior..."
sudo ip link del veth-clean 2>/dev/null || true
sudo ip link del veth-loss 2>/dev/null || true

#
# STREAM LIMPO
#
sudo ip link add veth-clean type veth peer name veth-clean-peer

sudo ip addr add 10.10.10.1/24 dev veth-clean
sudo ip addr add 10.10.10.2/24 dev veth-clean-peer

sudo ip link set veth-clean up
sudo ip link set veth-clean-peer up

#
# STREAM COM PERDA
#
sudo ip link add veth-loss type veth peer name veth-loss-peer

sudo ip addr add 10.20.20.1/24 dev veth-loss
sudo ip addr add 10.20.20.2/24 dev veth-loss-peer

sudo ip link set veth-loss up
sudo ip link set veth-loss-peer up

#
# DEGRADAÇÃO APENAS NO STREAM 2
#
sudo tc qdisc add dev veth-loss root netem \
    delay 100ms \
    loss 10%

echo
echo "====================================="
echo "STREAM 1 (SEM DEGRADAÇÃO)"
echo "====================================="
echo "OBS -> srt://10.10.10.2:9999?mode=caller"

echo
echo "====================================="
echo "STREAM 2 (COM PERDA)"
echo "====================================="
echo "OBS -> srt://10.20.20.2:10000?mode=caller"

echo
echo "Abrindo listeners..."

ffplay -x 640 -y 360 \
    -window_title "SRT CLEAN" \
    "srt://10.10.10.2:9999?mode=listener" &

ffplay -x 640 -y 360 \
    -window_title "SRT LOSS 10%" \
    "srt://10.20.20.2:10000?mode=listener" &

echo
echo "Pronto."
echo "Deixe o OBS transmitir para ambos os endereços."
echo

sleep 3600