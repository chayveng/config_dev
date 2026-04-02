#!/bin/bash

set -e

echo "== Set timezone to Asia/Bangkok (UTC+7) =="

sudo timedatectl set-timezone Asia/Bangkok

echo "== Verify timezone =="
timedatectl

echo "== Done! =="
