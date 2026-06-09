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
  version "0.1.1"
  sha256 "9924054bc2aba92ea869f003a244e1652b752cd4269e4d0234caba906139582d"

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
