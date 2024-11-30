#!/bin/bash

set -e  # Exit on any error

# Clean up any existing gem files
rm -f *.gem

# Build all platform variants
echo "Building gems..."
gem build zen-engine-ruby-darwin-arm64.gemspec
gem build zen-engine-ruby-darwin-amd64.gemspec
gem build zen-engine-ruby-linux-arm64.gemspec
gem build zen-engine-ruby-linux-amd64.gemspec
gem build zen-engine-ruby-windows-amd64.gemspec

# Push all gems to RubyGems
echo "Pushing gems to RubyGems..."
for gem in *.gem; do
    echo "Pushing $gem..."
    gem push "$gem"
done

echo "Complete! All gems have been built and pushed." 