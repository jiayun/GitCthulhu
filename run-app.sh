#!/bin/bash

echo "Building GitCthulhu..."
swift build

echo "Launching GitCthulhu GUI..."
# Run in background so it doesn't block the terminal
.build/debug/GitCthulhu &

echo "GitCthulhu is running! Check your dock or press Cmd+Tab to see the window."
echo "To stop the app, use: killall GitCthulhu"
