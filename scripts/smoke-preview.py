#!/usr/bin/env python3
"""Run the notarized preview and verify its agent exits if the UI dies."""

import os
from pathlib import Path
import signal
import subprocess
import sys
import time


def process_id(executable):
    processes = subprocess.check_output(["ps", "-axo", "pid=,command="], text=True)
    for line in processes.splitlines():
        pid, command = line.split(maxsplit=1)
        if command == executable or command.startswith(executable + " "):
            return int(pid)
    return None


def wait_for(check):
    for _ in range(50):
        result = check()
        if result:
            return result
        time.sleep(0.2)
    raise RuntimeError("Timed out waiting for the app or agent to change state")


if len(sys.argv) != 2:
    raise SystemExit("Usage: python3 scripts/smoke-preview.py /path/to/SplitArc.app")

app = Path(sys.argv[1]).resolve(strict=True)
gui = str(app / "Contents/MacOS/SplitArc")
agent = str(app / "Contents/Helpers/SplitArcAgent.app/Contents/MacOS/SplitArcAgent")
if process_id(gui) or process_id(agent):
    raise SystemExit("Quit this copy of SplitArc before running the smoke test.")

subprocess.run(["open", "-g", "-n", str(app)], check=True)
try:
    gui_pid = wait_for(lambda: process_id(gui))
    agent_pid = wait_for(lambda: process_id(agent))
    time.sleep(1)
    if process_id(gui) != gui_pid or process_id(agent) != agent_pid:
        raise RuntimeError("The app or agent exited during startup")
    print("The app and Bluetooth agent launched.", flush=True)

    os.kill(gui_pid, signal.SIGTERM)
    wait_for(lambda: not process_id(gui) and not process_id(agent))
    print("The agent exited when the app stopped.")
finally:
    for executable in (gui, agent):
        pid = process_id(executable)
        if pid:
            os.kill(pid, signal.SIGKILL)
