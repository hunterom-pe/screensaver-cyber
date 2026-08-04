#!/usr/bin/env python3
import os
import base64

webcontent_dir = "CyberpunkSaver/WebContent"
index_path = os.path.join(webcontent_dir, "index.html")
styles_path = os.path.join(webcontent_dir, "styles.css")
app_path = os.path.join(webcontent_dir, "app.js")
bg_path = os.path.join(webcontent_dir, "assets/background.jpg")

with open(index_path, "r", encoding="utf-8") as f:
    html = f.read()

with open(styles_path, "r", encoding="utf-8") as f:
    css = f.read()

with open(app_path, "r", encoding="utf-8") as f:
    js = f.read()

with open(bg_path, "rb") as f:
    bg_base64 = base64.b64encode(f.read()).decode("utf-8")

bg_data_url = f"data:image/jpeg;base64,{bg_base64}"

# Replace stylesheet link with inline style
html = html.replace('<link rel="stylesheet" href="styles.css">', f'<style>\n{css}\n</style>')

# Replace script tag with inline script
html = html.replace('<script src="app.js"></script>', f'<script>\n{js}\n</script>')

# Replace background image src with Base64 data URL
html = html.replace('src="assets/background.jpg"', f'src="{bg_data_url}"')

output_path = os.path.join(webcontent_dir, "bundle.html")
with open(output_path, "w", encoding="utf-8") as f:
    f.write(html)

print(f"✅ Created single-file WebContent bundle at {output_path} ({os.path.getsize(output_path)} bytes)")
