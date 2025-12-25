#!/bin/sh

tar --exclude='.git' --exclude='.env*' --exclude='**/.env*' --exclude='**/secrets*' --exclude='**/*secret*' --exclude='**/*password*' --exclude='**/*token*' -czf ~/tmp/nvim-config.tar.gz .

