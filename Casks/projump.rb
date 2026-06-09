# Homebrew Cask for Projump.
#
# This belongs in a tap repo (e.g. github.com/Tontoon7/homebrew-projump) so users can:
#   brew install --cask Tontoon7/projump/projump
# Homebrew strips the Gatekeeper quarantine on install, so the app launches even
# while it is only ad-hoc signed (not yet notarized).
#
# Before publishing: cut a GitHub release with dist/Projump-<version>.zip attached,
# then fill in the sha256 (shasum -a 256 dist/Projump-<version>.zip) and Tontoon7.

cask "projump" do
  version "0.1.0"
  sha256 "0ac310f1b9d428773f8aebb4404add1bce0a238c0b515fd300a7d60bb3cfa45e"

  url "https://github.com/Tontoon7/projump/releases/download/v#{version}/Projump-#{version}.zip"
  name "Projump"
  desc "Launch any CLI in the right project directory with a keyword"
  homepage "https://projump.dev"

  depends_on macos: ">= :sonoma"

  app "Projump.app"

  zap trash: [
    "~/.config/projump",
  ]
end
