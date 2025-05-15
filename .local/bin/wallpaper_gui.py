#!/usr/bin/env python3
import tkinter as tk
from tkinter import filedialog, messagebox
import subprocess
import os
import logging
import json
from PIL import Image, ImageTk
from tkinter import ttk

# Setup logging to ~/.cache/wallpaper_gui.log
log_dir = os.path.expanduser("~/.cache")
os.makedirs(log_dir, exist_ok=True)
logging.basicConfig(
    filename=os.path.join(log_dir, "wallpaper_gui.log"),
    level=logging.DEBUG,
    format="%(asctime)s %(levelname)s:%(message)s"
)

# Function to load Pywal colors if available (for theming GUI colors)
def load_pywal_colors():
    try:
        with open(os.path.expanduser("~/.cache/wal/colors.json")) as f:
            data = json.load(f)
            return data["colors"]
    except Exception as e:
        logging.warning("Could not load pywal colors: %s", e)
        return None

# Load colors or fallback to defaults
colors = load_pywal_colors()
BG = colors.get("color0") if colors else "#1e1e2e"
FG = colors.get("color7") if colors else "#cdd6f4"
ACCENT = colors.get("color4") if colors else "#89b4fa"

# Function to get dominant colors from an image (to display with wallpaper info)
def get_dominant_colors(file_path, num_colors=5):
    logging.debug("Extracting dominant colors from %s", file_path)
    try:
        img = Image.open(file_path).convert("RGB")
        img = img.resize((100, 100))
        color_counts = img.getcolors(maxcolors=10000)
        if color_counts:
            top_colors = sorted(color_counts, key=lambda x: x[0], reverse=True)[:num_colors]
            rgb_list = [c[1] for c in top_colors]
        else:
            palette = img.quantize(colors=num_colors).getpalette()[: num_colors * 3]
            rgb_list = [tuple(palette[i : i + 3]) for i in range(0, len(palette), 3)]
        return [f"#{r:02x}{g:02x}{b:02x}" for r, g, b in rgb_list]
    except (IOError, ValueError) as e:
        logging.error("Color extraction failed for %s: %s", file_path, e)
        return ["#000000"] * num_colors  # Fallback to black

# Main GUI class
class WallpaperGUI:
    def __init__(self, root):
        logging.debug("Initializing WallpaperGUI")
        self.root = root
        self.root.title("Hyprpaper Wallpaper Setter")
        self.root.geometry("675x500")
        self.root.resizable(False, False)
        self.root.attributes("-topmost", True)
        self.root.configure(bg=BG)

        # Store PhotoImage references
        self.thumbnail_images = []

        # Validate switch script
        self.switch_script = os.path.expanduser("~/.local/bin/switch_wallpaper.sh")
        self.script_valid = os.path.isfile(self.switch_script) and os.access(self.switch_script, os.X_OK)

        # Style for darker scrollbar
        style = ttk.Style()
        style.theme_use('clam')
        style.configure("Horizontal.TScrollbar", troughcolor=BG, background=ACCENT, bordercolor=BG, lightcolor=ACCENT, darkcolor=ACCENT)

        # Header and preview labels
        self.label = tk.Label(root, text="Select a wallpaper for Hyprpaper", bg=BG, fg=FG, wraplength=650)
        self.label.pack(pady=10)
        self.preview_label = tk.Label(root, text="No image selected", bg=BG, fg=FG)
        self.preview_label.pack(pady=10)
        self.status_label = tk.Label(root, text="", bg=BG, fg=ACCENT, wraplength=650)
        self.status_label.pack(pady=5)

        # Buttons
        self.select_button = tk.Button(root, text="Choose Folder", command=self.select_wallpaper, bg=ACCENT, fg="white")
        self.select_button.pack(pady=10)
        self.apply_button = tk.Button(
            root, text="Apply Wallpaper", command=self.apply_wallpaper,
            state="disabled" if self.script_valid else "disabled", bg=ACCENT, fg="white"
        )
        self.apply_button.pack(pady=10)

        # Canvas for thumbnails
        self.canvas = tk.Canvas(root, bg=BG, highlightthickness=0)
        self.scrollbar = ttk.Scrollbar(root, orient="horizontal", command=self.canvas.xview)
        self.canvas.configure(xscrollcommand=self.scrollbar.set)
        self.scrollbar.pack(fill="x", side="bottom")
        self.canvas.pack(fill="both", expand=True)
        self.thumb_frame = tk.Frame(self.canvas, bg=BG)
        self.canvas.create_window((0, 0), window=self.thumb_frame, anchor="nw")
        self.thumb_frame.bind("<Configure>", lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")))

        # Tracking variables
        self.thumbnail_buttons = []
        self.selected_file = None
        self.photo = None

        # Show error if script is missing
        if not self.script_valid:
            self.status_label.config(text="Error: Wallpaper switch script not found!")

        # Load thumbnails
        self.load_thumbnails()

    # Toast notification
    def show_toast(self, message, duration=2000):
        logging.debug("Showing toast: %s", message)
        toast = tk.Toplevel(self.root)
        toast.overrideredirect(True)
        toast.configure(bg=ACCENT)
        self.root.update_idletasks()
        x = self.root.winfo_rootx() + self.root.winfo_width() - 250
        y = self.root.winfo_rooty() + self.root.winfo_height() - 100
        toast.geometry(f"240x40+{x}+{y}")
        tk.Label(toast, text=message, bg=ACCENT, fg="white", font=("Arial", 10)).pack(padx=10, pady=5)
        toast.after(duration, toast.destroy)

    # Load and display wallpaper thumbnails incrementally
    def load_thumbnails(self):
        logging.debug("Loading thumbnails")
        wallpaper_dir = os.path.expanduser("~/Wallpaper")
        cache_file = os.path.expanduser("~/.cache/current_wallpaper")
        active_wallpaper = None

        # Validate wallpaper directory
        if not os.path.isdir(wallpaper_dir):
            logging.error("Wallpaper directory does not exist: %s", wallpaper_dir)
            messagebox.showerror("Error", f"Wallpaper directory {wallpaper_dir} not found!")
            return

        # Read active wallpaper
        try:
            if os.path.isfile(cache_file):
                with open(cache_file, "r") as f:
                    active_wallpaper = f.read().strip()
                logging.debug("Active wallpaper from cache: %s", active_wallpaper)
        except Exception as e:
            logging.warning("Could not read current wallpaper cache: %s", e)

        # Clear existing thumbnails
        for widget in self.thumb_frame.winfo_children():
            widget.destroy()
        self.thumbnail_buttons = []
        self.thumbnail_images = []

        # Get list of image files
        files = [f for f in os.listdir(wallpaper_dir) if f.lower().endswith((".png", ".jpg", ".jpeg"))]

        # Load thumbnails incrementally
        def load_next_file(index=0):
            if index >= len(files):
                self.canvas.configure(scrollregion=self.canvas.bbox("all"))
                return
            filename = files[index]
            full_path = os.path.join(wallpaper_dir, filename)
            try:
                img = Image.open(full_path)
                img.thumbnail((150, 150))
                photo = ImageTk.PhotoImage(img)
                btn = tk.Button(
                    self.thumb_frame,
                    image=photo,
                    highlightthickness=2,
                    highlightbackground="gray",
                    command=lambda p=full_path: self.load_selected_wallpaper(p),
                )
                btn.image = photo
                btn.grid(row=0, column=index, padx=5, pady=5)
                self.thumbnail_buttons.append((btn, full_path))
                self.thumbnail_images.append(photo)  # Keep reference

                # Auto-select active wallpaper
                if full_path == active_wallpaper:
                    self.load_selected_wallpaper(full_path)

                # Update scroll region
                self.canvas.configure(scrollregion=self.canvas.bbox("all"))
            except Exception as e:
                logging.error("Failed to load thumbnail %s: %s", full_path, e)
            self.root.after(10, load_next_file, index + 1)

        load_next_file()

    # Handle wallpaper selection and preview
    def load_selected_wallpaper(self, file_path):
        logging.debug("load_selected_wallpaper called with: %s", file_path)
        self.selected_file = file_path
        logging.debug("selected_file set to: %s", self.selected_file)
        self.apply_button.config(state="normal" if self.script_valid else "disabled")
        self.label.config(text=f"Selected: {os.path.basename(file_path)}")
        self.status_label.config(text="")  # Clear previous status

        try:
            img = Image.open(file_path)
            img.thumbnail((200, 200))
            self.photo = ImageTk.PhotoImage(img)
            self.preview_label.config(image=self.photo, text="")
        except Exception as e:
            self.preview_label.config(image=None, text=f"Preview failed: {e}")
            logging.error("Preview failed: %s", e)

        try:
            colors = get_dominant_colors(file_path)
            self.label.config(text=f"Selected: {os.path.basename(file_path)}\nColors: {', '.join(colors)}")
        except Exception as e:
            logging.error("Color display failed: %s", e)

        for btn, path in self.thumbnail_buttons:
            btn.config(highlightbackground="gray")
            if path == file_path:
                btn.config(highlightbackground="blue")

    # Open dialog to select custom wallpaper
    def select_wallpaper(self):
        logging.debug("Opening file dialog for custom selection")
        path = filedialog.askopenfilename(
            title="Select Wallpaper",
            filetypes=[("Image Files", "*.png *.jpg *.jpeg")],
            initialdir=os.path.expanduser("~/Wallpaper"),
        )
        logging.debug("Dialog returned path: %s", path)
        if path:
            self.load_selected_wallpaper(path)

    # Apply wallpaper using external script
    def apply_wallpaper(self):
        logging.debug("apply_wallpaper called; selected_file = %s", self.selected_file)
        if not self.selected_file:
            logging.warning("No wallpaper selected on apply")
            messagebox.showerror("Error", "No wallpaper selected!")
            return

        if not self.script_valid:
            logging.error("switch_wallpaper.sh invalid: %s", self.switch_script)
            messagebox.showerror("Error", "Wallpaper switch script not found!")
            return

        try:
            subprocess.run([self.switch_script, self.selected_file], check=True)
            with open(os.path.expanduser("~/.cache/current_wallpaper"), "w") as f:
                f.write(self.selected_file)
            self.show_toast("Wallpaper applied successfully!")
            self.load_thumbnails()
        except subprocess.CalledProcessError as e:
            logging.error("Error applying wallpaper: %s", e)
            self.show_toast(f"Error applying wallpaper: {e}")
            self.status_label.config(text="Error: " + str(e))

# Start the GUI
if __name__ == "__main__":
    logging.debug("Starting application")
    root = tk.Tk()
    gui = WallpaperGUI(root)
    root.mainloop()
