#!/usr/bin/env python3
# ~/.config/waybar/scripts/network_manager_gui.py

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib
import subprocess
import os
import logging
from pathlib import Path
from datetime import datetime, timedelta

LOGFILE = Path.home() / ".cache/network_gui.log"
LOGFILE.parent.mkdir(exist_ok=True)
logging.basicConfig(filename=LOGFILE, level=logging.INFO, format="%(asctime)s: %(message)s")

# Cache for ethtool speed
SPEED_CACHE = {"interface": "", "speed": "Unknown", "timestamp": datetime.min}

def load_pywal_colors():
    colors = {}
    try:
        with open(Path.home() / ".cache/wal/colors", "r") as f:
            for i, line in enumerate(f):
                colors[f"color{i}"] = line.strip()
        logging.info("Loaded Pywal colors")
    except FileNotFoundError:
        logging.warning("Pywal colors not found, using defaults")
        colors = {f"color{i}": "#ffffff" for i in range(8)}
    return colors

def run_nmcli(args):
    try:
        result = subprocess.run(
            ["nmcli"] + args, capture_output=True, text=True, check=True, timeout=5
        )
        logging.info(f"nmcli {' '.join(args)}: {result.stdout.strip()}")
        return result.stdout
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        logging.error(f"nmcli {' '.join(args)} error: {e}")
        return ""

def get_network_status():
    global SPEED_CACHE
    status = {"ethernet": {}}
    interface = run_nmcli(["-t", "-f", "DEVICE,TYPE", "device"]).splitlines()
    interface = next((x.split(":")[0] for x in interface if ":ethernet" in x), "")
    if interface:
        output = run_nmcli(["-t", "-f", "GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS", "device", "show", interface])
        status["ethernet"] = {"interface": interface}
        for line in output.splitlines():
            if line.startswith("GENERAL.STATE:"):
                status["ethernet"]["state"] = line.split(":")[1].strip()
            if line.startswith("GENERAL.CONNECTION:"):
                status["ethernet"]["connection"] = line.split(":")[1].strip()
            if line.startswith("IP4.ADDRESS[1]:"):
                status["ethernet"]["ip"] = line.split(":")[1].strip()
        
        # Check speed cache (refresh every 30 seconds)
        now = datetime.now()
        if (
            SPEED_CACHE["interface"] != interface
            or now - SPEED_CACHE["timestamp"] > timedelta(seconds=30)
        ):
            try:
                cmd = ["ethtool", interface]  # Use ["sudo", "ethtool", interface] if needed
                ethtool_output = subprocess.run(
                    cmd, capture_output=True, text=True, timeout=1
                ).stdout
                for line in ethtool_output.splitlines():
                    if "Speed:" in line:
                        SPEED_CACHE["speed"] = line.split(":")[1].strip()
                        break
                else:
                    SPEED_CACHE["speed"] = "Unknown"
                SPEED_CACHE["interface"] = interface
                SPEED_CACHE["timestamp"] = now
                logging.info(f"Updated ethtool speed for {interface}: {SPEED_CACHE['speed']}")
            except (subprocess.SubprocessError, FileNotFoundError) as e:
                SPEED_CACHE["speed"] = "Unknown"
                logging.warning(f"Failed to get ethtool speed for {interface}: {e}")
        status["ethernet"]["speed"] = SPEED_CACHE["speed"]
    return status

def notify(message, urgency="normal"):
    try:
        subprocess.run(
            ["notify-send", "-u", urgency, "Network Manager", message], timeout=2, check=False
        )
        logging.info(f"Notification: {message}")
    except (subprocess.TimeoutExpired, FileNotFoundError, subprocess.SubprocessError):
        logging.warning(f"Notification failed: {message}")

class NetworkManagerGUI(Gtk.Window):
    def __init__(self):
        super().__init__(title="Network Manager")
        self.set_default_size(400, 200)
        self.set_border_width(10)
        self.set_position(Gtk.WindowPosition.CENTER)

        self.colors = load_pywal_colors()
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(vbox)

        grid = Gtk.Grid(column_spacing=10, row_spacing=5)
        labels = ["Ethernet Interface:", "Status:", "IP:", "Speed:"]
        self.status_labels = {}
        for i, label in enumerate(labels):
            grid.attach(Gtk.Label(label=label, xalign=0), 0, i, 1, 1)
            self.status_labels[label] = Gtk.Label(label="...", xalign=0)
            grid.attach(self.status_labels[label], 1, i, 1, 1)
        vbox.pack_start(grid, False, False, 0)

        hbox = Gtk.Box(spacing=10)
        refresh_btn = Gtk.Button(label="Refresh")
        refresh_btn.connect("clicked", self.on_refresh_clicked)
        toggle_btn = Gtk.Button(label="Toggle Ethernet")
        toggle_btn.connect("clicked", self.on_toggle_clicked)
        config_btn = Gtk.Button(label="Configure")
        config_btn.connect("clicked", self.on_config_clicked)
        hbox.pack_start(refresh_btn, False, False, 0)
        hbox.pack_start(toggle_btn, False, False, 0)
        hbox.pack_start(config_btn, False, False, 0)
        vbox.pack_start(hbox, False, False, 0)

        css = f"""
        window {{ background-color: {self.colors["color0"]}; }}
        button {{ background-color: {self.colors["color1"]}; color: {self.colors["color7"]}; }}
        label {{ color: {self.colors["color7"]}; }}
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode())
        Gtk.StyleContext.add_provider_for_screen(
            self.get_screen(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
        )

        self.refresh_status()
        GLib.timeout_add_seconds(5, self.refresh_status)

    def refresh_status(self):
        status = get_network_status()
        self.status_labels["Ethernet Interface:"].set_text(status["ethernet"].get("interface", "None"))
        self.status_labels["Status:"].set_text(status["ethernet"].get("state", "Unknown"))
        self.status_labels["IP:"].set_text(status["ethernet"].get("ip", "None"))
        self.status_labels["Speed:"].set_text(status["ethernet"].get("speed", "Unknown"))
        return True

    def on_refresh_clicked(self, button):
        self.refresh_status()
        notify("Status refreshed")

    def on_toggle_clicked(self, button):
        interface = self.status_labels["Ethernet Interface:"].get_text()
        if interface == "None":
            notify("No Ethernet interface", "critical")
            return
        status = self.status_labels["Status:"].get_text()
        if "connected" in status.lower():
            run_nmcli(["device", "disconnect", interface])
            notify("Ethernet Disconnected")
        else:
            run_nmcli(["device", "connect", interface])
            notify("Ethernet Connected")
        self.refresh_status()

    def on_config_clicked(self, button):
        try:
            subprocess.Popen(["nm-connection-editor"])
            notify("Opened configuration")
        except FileNotFoundError:
            notify("nm-connection-editor not found", "critical")
            logging.error("nm-connection-editor not found")
        except subprocess.SubprocessError as e:
            notify("Failed to open configuration", "critical")
            logging.error(f"Failed to open nm-connection-editor: {e}")
        self.refresh_status()

if __name__ == "__main__":
    subprocess.run(["systemctl", "start", "NetworkManager"], check=False)
    os.environ["GDK_BACKEND"] = "x11"  # Switch to X11 to test Wayland issues
    win = NetworkManagerGUI()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

