cask "strata" do
  version "0.8.1"
  sha256 "23001f04ab1653f6e0b0dde2c392dd2004465434a5f01d51e91a8276421d57eb"

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
