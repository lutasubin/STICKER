#!/bin/bash
# Script để filter log chỉ hiển thị AppLogger và log chính
# Format log: [timestamp] [LEVEL] [ServiceName] message

# Pattern để match:
# - Log từ AppLogger: có format [YYYY-MM-DD...] [LEVEL]
# - Log từ các Service: có [ServiceName] trong message
# - ERROR, WARNING, INFO, DEBUG levels

flutter run 2>&1 | grep -E "\[[0-9]{4}-[0-9]{2}-[0-9]{2}.*\] \[(DEBUG|INFO|WARNING|ERROR|FATAL)\]|\[.*Service\]|\[.*Controller\]|\[.*Screen\]|❌|⚠️|ℹ️|🐛|💀" --color=always
