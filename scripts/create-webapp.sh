#!/bin/bash

# Simple webapp creator for Hyprland
# Usage: create-webapp <name> <url> [browser]

if [ "$#" -lt 2 ]; then
    echo "Usage: create-webapp <name> <url> [browser]"
    echo "Example: create-webapp claude https://claude.ai brave"
    echo ""
    echo "Browser defaults to 'brave' if not specified"
    echo "Other options: chromium, google-chrome-stable, firefox"
    exit 1
fi

APP_NAME="$1"
APP_URL="$2"
BROWSER="${3:-brave}"

SCRIPT_PATH="$HOME/.local/bin/webapp-$APP_NAME"

# Create the webapp script
cat > "$SCRIPT_PATH" << EOF
#!/bin/bash
$BROWSER \\
  --app=$APP_URL \\
  --class=webapp-$APP_NAME \\
  --user-data-dir="\$HOME/.config/${BROWSER}-webapps/$APP_NAME"
EOF

chmod +x "$SCRIPT_PATH"

echo "✓ Created webapp-$APP_NAME"
echo ""
echo "Add this to your hyprland.conf:"
echo "bind = SUPER, <KEY>, exec, webapp-$APP_NAME"
echo ""
echo "Optional window rules:"
echo "windowrulev2 = size 1600 1000, class:^(webapp-$APP_NAME)$"
echo "windowrulev2 = center, class:^(webapp-$APP_NAME)$"
