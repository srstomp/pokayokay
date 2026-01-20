#!/usr/bin/env python3
"""Redirect to actual bridge.py in plugins directory"""
import subprocess
import sys
import os

# Get the directory where this script is located
script_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = os.path.dirname(os.path.dirname(script_dir))

# Path to the actual bridge.py
actual_bridge = os.path.join(project_dir, 'plugins', 'pokayokay', 'hooks', 'actions', 'bridge.py')

if os.path.exists(actual_bridge):
    # Execute the actual bridge.py with the same arguments
    result = subprocess.run([sys.executable, actual_bridge] + sys.argv[1:])
    sys.exit(result.returncode)
else:
    print(f"bridge.py not found at {actual_bridge}", file=sys.stderr)
    sys.exit(0)  # Exit successfully to not block
