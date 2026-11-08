class Shipgo < Formula
  desc "Cross-platform Git push tool"
  homepage "https://github.com/ORG/shipgo"
  url "https://github.com/ORG/shipgo/archive/refs/tags/v@VERSION@.tar.gz"
  sha256 "<filled-by-release>"
  license "MIT"

  def install
    bin.install "shipgo.sh" => "shipgo"
    bash_completion.install "shipgo-completion.bash" => "shipgo"
  end

  test do
    assert_match "shipgo @VERSION@", shell_output("#{bin}/shipgo version")
  end
end