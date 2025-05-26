import bpy, json, os

# 1. Load Pywal’s JSON
wal_path = os.path.expanduser("~/.cache/wal/colors.json")
if not os.path.exists(wal_path):
    print("Pywal cache not found:", wal_path)
    raise SystemExit
data = json.load(open(wal_path))

# 2. Helper to convert hex (“#rrggbb”) → [r, g, b] floats
def hex_to_rgb(hex_str):
    h = hex_str.lstrip('#')
    return [int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4)]

cols = data['colors']
bg   = hex_to_rgb(cols['background'])
fg   = hex_to_rgb(cols['foreground'])
c0   = hex_to_rgb(cols['color0'])
c7   = hex_to_rgb(cols['color7'])

# 3. Apply into Blender’s active theme
prefs = bpy.context.preferences
theme = prefs.themes[0]  # 0 is the default ‘User Interface’ theme

# Example: set editors’ header & text
theme.user_interface.wcol_tool.label.inner = fg
theme.user_interface.wcol_tool.label.inner_sel = c7
theme.user_interface.wcol_tool.inner = bg
theme.user_interface.wcol_tool.outer = c0

# Example: 3D View background
space = theme.view_3d.space
space.gradient_high = bg
space.gradient_low  = hex_to_rgb(cols['color1'])
