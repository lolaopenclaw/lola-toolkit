#!/bin/bash

/usr/bin/rclone sync /home/mleon/.openclaw/memory/ grive_lola:openclaw_backups --create-empty-src-dirs
