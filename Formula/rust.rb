class Rust < Formula
  desc "Safe, concurrent, practical language"
  homepage "https://www.rust-lang.org/"

  stable do
    url "https://static.rust-lang.org/dist/rustc-1.20.0-src.tar.gz"
    sha256 "2aa4875ff4472c6e35262bbb9052cb2623da3dae6084a858cc59d36f33f18214"

    resource "cargo" do
      url "https://github.com/rust-lang/cargo.git",
          :tag => "0.21.0",
          :revision => "5b4b8b2ae3f6a884099544ce66dbb41626110ece"
    end

    resource "racer" do
      url "https://github.com/racer-rust/racer/archive/2.0.10.tar.gz"
      sha256 "8e81da4f238117affe7631a7656b219294950ff17b2bea85794060be11b80489"
    end
  end

  bottle do
    sha256 "532cf7d2239885f7a77d0b5cf3a00071eb5b8c50b24b1558ad8112f8d2d446b0" => :high_sierra
    sha256 "f79c48a0f62f4c781562c8dafe2a2dbf6012d63d93d4e7ab674e244957152d7b" => :sierra
    sha256 "4fb38eeea97e9d337e996b161abf78f849bf441ccb69a193965b89457a5ad692" => :el_capitan
    sha256 "466202b90dba96080f879bd504b72e4a31cb44d11daf9eba6fc413eb2f234898" => :yosemite
    sha256 "c09b0af0fedcac1df1210b8cbf775fb3c47b3263edd788f476f7a123d8ca00e8" => :x86_64_linux
  end

  head do
    url "https://github.com/rust-lang/rust.git"

    resource "cargo" do
      url "https://github.com/rust-lang/cargo.git"
    end
  end

  option "with-llvm", "Build with brewed LLVM. By default, Rust's LLVM will be used."
  option "with-racer", "Build Racer code completion tool, and retain Rust sources."

  depends_on "cmake" => :build
  depends_on "pkg-config" => :run
  depends_on "llvm" => :optional
  depends_on "openssl"
  depends_on "libssh2"

  unless OS.mac?
    depends_on "binutils"
    depends_on "curl"
    depends_on :python
    depends_on "zlib"
  end

  conflicts_with "cargo-completion", :because => "both install shell completion for cargo"

  # According to the official readme, GCC 4.7+ is required
  fails_with :gcc_4_0
  fails_with :gcc
  ("4.3".."4.6").each do |n|
    fails_with :gcc => n
  end

  resource "cargobootstrap" do
    if OS.mac?
      # From https://github.com/rust-lang/rust/blob/#{version}/src/stage0.txt
      url "https://static.rust-lang.org/dist/2017-07-20/cargo-0.20.0-x86_64-apple-darwin.tar.gz"
      sha256 "bd0b62b6afbfb1435ac5a72cee072f0f65b29c6c0baeb11f4f9b9b16dc241151"
    elsif OS.linux?
      # From: https://github.com/rust-lang/rust/blob/#{version}/src/stage0.txt
      url "https://static.rust-lang.org/dist/2017-07-20/cargo-0.20.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "a677d13b01d00ad13edf75c7d1b484421c7fc09338bf9ed6d456b4685bb42ed1"
    end
  end

  def install
    # Reduce memory usage below 4 GB for Circle CI.
    ENV["MAKEFLAGS"] = "-j12 -l2.5" if ENV["CIRCLECI"]
    args = ["--prefix=#{prefix}"]
    args << "--disable-rpath" if build.head?
    args << "--enable-clang" if ENV.compiler == :clang
    args << "--llvm-root=#{Formula["llvm"].opt_prefix}" if build.with? "llvm"
    if build.head?
      args << "--release-channel=nightly"
    else
      args << "--release-channel=stable"
    end
    system "./configure", *args
    system "make"
    system "make", "install"

    resource("cargobootstrap").stage do
      system "./install.sh", "--prefix=#{buildpath}/cargobootstrap"
    end
    ENV.prepend_path "PATH", buildpath/"cargobootstrap/bin"

    resource("cargo").stage do
      ENV["RUSTC"] = bin/"rustc"
      system "cargo", "build", "--release", "--verbose"
      bin.install "target/release/cargo"
    end

    if build.with? "racer"
      resource("racer").stage do
        ENV.prepend_path "PATH", bin
        cargo_home = buildpath/"cargo_home"
        cargo_home.mkpath
        ENV["CARGO_HOME"] = cargo_home
        system bin/"cargo", "build", "--release", "--verbose"
        (libexec/"bin").install "target/release/racer"
        (bin/"racer").write_env_script(libexec/"bin/racer", :RUST_SRC_PATH => pkgshare/"rust_src")
      end
      # Remove any binary files; as Homebrew will run ranlib on them and barf.
      rm_rf Dir["src/{llvm,test,librustdoc,etc/snapshot.pyc}"]
      (pkgshare/"rust_src").install Dir["src/*"]
    end

    rm_rf prefix/"lib/rustlib/uninstall.sh"
    rm_rf prefix/"lib/rustlib/install.log"
  end

  def post_install
    Dir["#{lib}/rustlib/**/*.dylib"].each do |dylib|
      chmod 0664, dylib
      MachO::Tools.change_dylib_id(dylib, "@rpath/#{File.basename(dylib)}")
      chmod 0444, dylib
    end
  end

  test do
    system "#{bin}/rustdoc", "-h"
    (testpath/"hello.rs").write <<-EOS.undent
    fn main() {
      println!("Hello World!");
    }
    EOS
    system "#{bin}/rustc", "hello.rs"
    assert_equal "Hello World!\n", `./hello`
    system "#{bin}/cargo", "new", "hello_world", "--bin"
    assert_equal "Hello, world!",
                 (testpath/"hello_world").cd { `#{bin}/cargo run`.split("\n").last }
  end
end
