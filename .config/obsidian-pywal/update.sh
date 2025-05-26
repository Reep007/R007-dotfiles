#!/bin/bash

#!/bin/bash

css_file="$HOME/Vxxxt/.obsidian/snippets/pywal.css"
template="$HOME/.config/obsidian-pywal/template.css"
colors=($(< ~/.cache/wal/colors))

# Copy template first
cp "$template" "$css_file"

# Replace placeholder colors
sed -i "s/#1e1e1e/${colors[0]}/" "$css_file"
sed -i "s/#2e2e2e/${colors[1]}/" "$css_file"
sed -i "s/#44475a/${colors[2]}/" "$css_file"
sed -i "s/#f8f8f2/${colors[7]}/" "$css_file"
sed -i "s/#6272a4/${colors[5]}/" "$css_file"
sed -i "s/#ff79c6/${colors[3]}/" "$css_file"
sed -i "s/#bd93f9/${colors[4]}/" "$css_file"
sed -i "s/#50fa7b/${colors[6]}/" "$css_file"
sed -i "s/#8be9fd/${colors[8]}/" "$css_file"

# Touch to refresh
touch "$css_file"

# Enable the snippet in Obsidian
appearance_file="$HOME/Vxxxt/.obsidian/appearance.json"

if [[ -f "$appearance_file" ]]; then
  if ! grep -q '"pywal"' "$appearance_file"; then
    tmpfile=$(mktemp)
    jq '.enabledCssSnippets += ["pywal"] | unique' "$appearance_file" > "$tmpfile" && mv "$tmpfile" "$appearance_file"
    echo "✨ Enabled 'pywal' snippet in Obsidian."
  else
    echo "✔ 'pywal' snippet already enabled."
  fi
else
  echo "⚠️ appearance.json not found — couldn't enable snippet."
fi


echo "✅ Obsidian Pywal theme updated!"

