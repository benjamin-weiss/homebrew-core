class Ncurses < Formula
  desc "Text-based UI library"
  homepage "https://www.gnu.org/software/ncurses/"
  url "https://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz"
  mirror "https://ftpmirror.gnu.org/ncurses/ncurses-6.0.tar.gz"
  sha256 "f551c24b30ce8bfb6e96d9f59b42fbea30fa3a6123384172f9e7284bcf647260"
  revision 3

  bottle do
    sha256 "8a89b242114626454cc04a7213b1048a5d30c06fb414cd59d909c483f51c4e53" => :high_sierra
    sha256 "551937b3b407581f6cd20914d643600fd746333313a683c7b0dec841bfbb66df" => :sierra
    sha256 "70443e997a0964193949192a4d7643f220c48ef34be9fa8341925e3c1cc11814" => :el_capitan
    sha256 "f7e386ccd8420ddd2d60047c2781f80f7be74588d64d236d61b63fd452bd65d1" => :yosemite
    sha256 "52193a241a2676836dd3566ffaa6e1685c8230796bf5915e96fc961b7b37d75e" => :x86_64_linux # glibc 2.19
  end

  keg_only :provided_by_osx

  depends_on "pkg-config" => :build
  depends_on "gpatch" => :build unless OS.mac?

  # stable rollup patch created by upstream see
  # https://invisible-mirror.net/archives/ncurses/6.0/README
  resource "ncurses-6.0-20160910-patch.sh" do
    url "https://invisible-mirror.net/archives/ncurses/6.0/ncurses-6.0-20160910-patch.sh.bz2"
    mirror "https://www.mirrorservice.org/sites/lynx.invisible-island.net/ncurses/6.0/ncurses-6.0-20160910-patch.sh.bz2"
    sha256 "f570bcfe3852567f877ee6f16a616ffc7faa56d21549ad37f6649022f8662538"
  end

  def install
    # Fix the build for GCC 5.1
    # error: expected ')' before 'int' in definition of macro 'mouse_trafo'
    # See https://lists.gnu.org/archive/html/bug-ncurses/2014-07/msg00022.html
    # and https://trac.sagemath.org/ticket/18301
    # Disable linemarker output of cpp
    ENV.append "CPPFLAGS", "-P"

    (lib/"pkgconfig").mkpath

    # stage and apply patch
    buildpath.install resource("ncurses-6.0-20160910-patch.sh")
    system "sh", "ncurses-6.0-20160910-patch.sh"

    system "./configure", "--prefix=#{prefix}",
                          "--enable-pc-files",
                          "--with-pkg-config-libdir=#{lib}/pkgconfig",
                          "--enable-sigwinch",
                          "--enable-symlinks",
                          "--enable-widec",
                          "--mandir=#{man}",
                          "--with-manpage-format=normal",
                          "--with-shared",
                          "--with-gpm=no",
                          "--without-ada"
    system "make"
    ENV.deparallelize
    system "make", "install"
    make_libncurses_symlinks

    prefix.install "test"
    (prefix/"test").install "install-sh", "config.sub", "config.guess"
  end

  def make_libncurses_symlinks
    major = version.to_s.split(".")[0]

    %w[form menu ncurses panel].each do |name|
      if OS.mac?
        lib.install_symlink "lib#{name}w.#{major}.dylib" => "lib#{name}.dylib"
        lib.install_symlink "lib#{name}w.#{major}.dylib" => "lib#{name}.#{major}.dylib"
      else
        lib.install_symlink "lib#{name}w.so.#{major}" => "lib#{name}.so"
        lib.install_symlink "lib#{name}w.so.#{major}" => "lib#{name}.so.#{major}"
      end
      lib.install_symlink "lib#{name}w.a" => "lib#{name}.a"
      lib.install_symlink "lib#{name}w_g.a" => "lib#{name}_g.a"
    end

    lib.install_symlink "libncurses++w.a" => "libncurses++.a"
    lib.install_symlink "libncurses.a" => "libcurses.a"
    if OS.mac?
      lib.install_symlink "libncurses.dylib" => "libcurses.dylib"
    else
      lib.install_symlink "libncurses.so" => "libcurses.so"
      lib.install_symlink "libncurses.so" => "libtermcap.so"
      lib.install_symlink "libncurses.so" => "libtinfo.so"
    end

    (lib/"pkgconfig").install_symlink "ncursesw.pc" => "ncurses.pc"

    bin.install_symlink "ncursesw#{major}-config" => "ncurses#{major}-config"

    include.install_symlink [
      "ncursesw/curses.h", "ncursesw/form.h", "ncursesw/ncurses.h",
      "ncursesw/panel.h", "ncursesw/term.h", "ncursesw/termcap.h"
    ]
  end

  test do
    ENV["TERM"] = "xterm"
    system bin/"tput", "cols"

    system prefix/"test/configure", "--prefix=#{testpath}/test",
                                    "--with-curses-dir=#{prefix}"
    system "make", "install"

    system testpath/"test/bin/keynames"
    system testpath/"test/bin/test_arrays"
    system testpath/"test/bin/test_vidputs"
  end
end
