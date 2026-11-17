cask "strata" do
  version "0.8.7"
  sha256 "18f1fcdf81396d297e4c2e6279ec1dce89da75c60dffaa30b508a5b4689a3ef6"

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
