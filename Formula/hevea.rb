class Hevea < Formula
  desc "LaTeX-to-HTML translator"
  homepage "http://hevea.inria.fr/"
  url "http://hevea.inria.fr/old/hevea-2.30.tar.gz"
  sha256 "9e93deac8d2cc62a8d9eae2817094cdba81cabef264d009f3d434d85ab9a249c"

  bottle do
    sha256 "a431a61f899ba34d9d233f9c0ebaf54dbaf2c5a4967fc9f7fc90f0a673eeebd2" => :high_sierra
    sha256 "b22f4a1e66c2eea6faecf98834a0897334e77684312653885049835c593ad431" => :sierra
    sha256 "079afe1b83d43ea8c3e5537d199ba20ee05a6460db653df0675948390b328b94" => :el_capitan
    sha256 "4b6005785553fdd3185d7b15c74f9e8ab0632994bc6cd714ece9148203589609" => :yosemite
    sha256 "4d4a678e0c284a2871b7f70b1ecd73e7265e0e1d43140679d25cf3bbc91ed574" => :x86_64_linux
  end

  depends_on "ocaml"
  depends_on "ocamlbuild" => :build
  depends_on "ghostscript" => :optional

  def install
    ENV["PREFIX"] = prefix
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.tex").write <<-EOS.undent
      \\documentclass{article}
      \\begin{document}
      \\end{document}
    EOS
    system "#{bin}/hevea", "test.tex"
  end
end
