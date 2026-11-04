cask "strata" do
  version "0.8.2"
  sha256 "2767c8115a31c8e03c73be8b9a0851437f717e4c73a2afe375f6ce8e2c325dfe"

  url "https://github.com/cristipufu/strata-files/releases/download/v#{version}/Strata.dmg"
  name "Strata Files"
  desc "Native file manager with instant search, disk usage and dual panes"
  homepage "https://stratafiles.app/"

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :tahoe

  app "Strata.app"
  binary "#{appdir}/Strata.app/Contents/Helpers/strata"
end
