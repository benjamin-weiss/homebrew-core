class GitTown < Formula
  desc "High-level command-line interface for Git"
  homepage "http://www.git-town.com"
  url "https://github.com/Originate/git-town/archive/v4.2.1.tar.gz"
  sha256 "b5d62df0a464ac3d90cc5496f3027d024de3edbe8ea324637f54571e38d7cada"

  bottle do
    cellar :any_skip_relocation
    sha256 "e2ab2cec3f6b43790934366d463e56dbc9bb2cdf4353da4bb76097b54b640a5e" => :high_sierra
    sha256 "2b7f7e0c56371762d7dda2599f9c0d42dbc3cb00a3a8dfbf986ca568b8d4396c" => :sierra
    sha256 "cece6487b0a58126b108af4827328c6af9f79b9bf6867ae0ce92460071de6a2f" => :el_capitan
    sha256 "fdb4cd3367d885a72efeb6feafbdd3cd1dd8668dc37f0c33002690fa71a75a96" => :x86_64_linux # glibc 2.19
  end

  depends_on "go" => :build
  depends_on :macos => :el_capitan

  def install
    ENV["GOPATH"] = buildpath
    (buildpath/"src/github.com/Originate").mkpath
    ln_sf buildpath, buildpath/"src/github.com/Originate/git-town"
    system "go", "build", "-o", bin/"git-town"
  end

  test do
    system "git", "init"
    touch "testing.txt"
    system "git", "add", "testing.txt"
    system "git", "commit", "-m", "Testing!"

    system "#{bin}/git-town", "config"
  end
end
