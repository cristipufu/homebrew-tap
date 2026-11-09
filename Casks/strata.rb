cask "strata" do
  version "0.8.5"
  sha256 "b80e43a8e1c14e27e7a6e39bee61ddb4769f0f621721ac0cb2298130cadefdc5"

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
