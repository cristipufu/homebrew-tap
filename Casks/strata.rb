cask "strata" do
  version "0.8.4"
  sha256 "0705a085574162c84aaaad3390215541c99b7a153c9265a990659e6cd3bcd1bb"

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
