#!/usr/bin/env python3
"""Read-only GPU telemetry. No third-party Python modules or elevated access."""
import csv
import io
import json
import math
from pathlib import Path
import re
import shlex
import shutil
import subprocess


def read(path):
    try:
        return path.read_text().strip()
    except OSError:
        return ""


def number(text, scale=1):
    try:
        value = float(text) / scale
        return round(value, 1) if math.isfinite(value) else None
    except (ValueError, TypeError):
        return None


def pci_address(text):
    try:
        domain, bus, slot = text.strip().lower().split(":")
        return f"{int(domain, 16):04x}:{bus}:{slot}"
    except ValueError:
        return text.strip().lower()


def parse_nvidia(text):
    result = {}
    for row in csv.reader(io.StringIO(text), skipinitialspace=True):
        if len(row) != 4:
            continue
        address, name, usage, temperature = (part.strip() for part in row)
        result[pci_address(address)] = {
            "name": name, "usage": number(usage), "temperature": number(temperature)
        }
    return result


def nvidia_readings(addresses):
    if not addresses or not shutil.which("nvidia-smi"):
        return {}
    try:
        result = subprocess.run([
            "nvidia-smi", "--id=" + ",".join(addresses),
            "--query-gpu=pci.bus_id,name,utilization.gpu,temperature.gpu",
            "--format=csv,noheader,nounits",
        ], capture_output=True, text=True, timeout=2, check=True)
        return parse_nvidia(result.stdout)
    except (OSError, subprocess.SubprocessError):
        return {}


def display_name(address, fallback):
    if shutil.which("lspci"):
        try:
            result = subprocess.run(["lspci", "-s", address, "-mm"],
                                    capture_output=True, text=True, timeout=1, check=True)
            parts = shlex.split(result.stdout)
            if len(parts) >= 4:
                return parts[3]
        except (OSError, ValueError, subprocess.SubprocessError):
            pass
    return fallback


def collect(drm_root=Path("/sys/class/drm"), nvidia=None):
    devices = {}
    for card in sorted(drm_root.glob("card*")):
        if not re.fullmatch(r"card\d+", card.name):
            continue
        device = (card / "device").resolve()
        vendor_id = read(device / "vendor")
        if not vendor_id:
            continue
        address = pci_address(device.name)
        if not re.fullmatch(r"[0-9a-f]{4,}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-7]", address):
            continue
        vendor = {"0x1002": "AMD", "0x10de": "NVIDIA", "0x8086": "Intel"}.get(vendor_id, "GPU")
        sleeping = read(device / "power/runtime_status") == "suspended"
        usage = None if sleeping else number(read(device / "gpu_busy_percent"))
        temperature = None
        if not sleeping:
            for sensor in sorted(device.glob("hwmon/hwmon*/temp1_input")):
                temperature = number(read(sensor), 1000)
                if temperature is not None:
                    break
        devices[address] = {
            "id": "pci:" + address, "pci": address, "vendor": vendor,
            "name": display_name(address, vendor + " " + address),
            "usage": usage, "temperature": temperature, "suspended": sleeping,
        }
    # Do not wake a suspended discrete GPU merely to draw its widget.
    active_nvidia = [address for address, gpu in devices.items()
                     if gpu["vendor"] == "NVIDIA" and not gpu["suspended"]]
    readings = nvidia_readings(active_nvidia) if nvidia is None else nvidia
    for address, sample in readings.items():
        if address in devices and not devices[address]["suspended"]:
            devices[address].update(sample)
    return list(devices.values())


if __name__ == "__main__":
    print(json.dumps(collect(), allow_nan=False))
