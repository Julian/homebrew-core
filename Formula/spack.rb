class Spack < Formula
  desc "Package manager that builds multiple versions and configurations of software"
  homepage "https://spack.io"
  url "https://github.com/spack/spack/archive/v0.16.2.tar.gz"
  sha256 "ed3e5d479732b0ba82489435b4e0f9088571604e789f7ab9bc5ce89030793350"
  license any_of: ["Apache-2.0", "MIT"]
  revision 1
  head "https://github.com/spack/spack.git", branch: "develop"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "6a57e46cd9b0a498705657cc666892f031e57fd42bfdfbc2561165ded9582d37"
    sha256 cellar: :any_skip_relocation, big_sur:       "ab713b17720b8b02b22c0d2070e6b27d498d552c420e73bd7cf246e565bf7eae"
    sha256 cellar: :any_skip_relocation, catalina:      "ab713b17720b8b02b22c0d2070e6b27d498d552c420e73bd7cf246e565bf7eae"
    sha256 cellar: :any_skip_relocation, mojave:        "ab713b17720b8b02b22c0d2070e6b27d498d552c420e73bd7cf246e565bf7eae"
  end

  depends_on "python@3.9"

  # Fix incompatibility with Python 3.9.6+, remove with next release
  # https://github.com/spack/spack/issues/24644
  patch do
    url "https://github.com/spack/spack/commit/3b94e22ad44a5921b639dfc5a59a7626562457c7.patch?full_index=1"
    sha256 "77d9e48ecde83595a249b1859d62a2e94fda5c4aa9ed7cd1bc441f6083388132"
  end

  def install
    prefix.install Dir["*"]
  end

  def post_install
    mkdir_p prefix/"var/spack/junit-report" unless (prefix/"var/spack/junit-report").exist?
  end

  test do
    system "#{bin}/spack", "--version"
    assert_match "zlib", shell_output("#{bin}/spack list zlib")

    # Set up configuration file and build paths
    %w[opt modules lmod stage test source misc cfg-store].each { |dir| (testpath/dir).mkpath }
    (testpath/"cfg-store/config.yaml").write <<~EOS
      config:
        install_tree: #{testpath}/opt
        module_roots:
          tcl: #{testpath}/modules
          lmod: #{testpath}/lmod
        build_stage:
          - #{testpath}/stage
        test_stage: #{testpath}/test
        source_cache: #{testpath}/source
        misc_cache: #{testpath}/misc
    EOS

    # spack install using the config file
    system "#{bin}/spack", "-C", "#{testpath}/cfg-store", "install", "--no-cache", "zlib"

    # Get the path to one of the compiled library files
    zlib_prefix = shell_output("#{bin}/spack -ddd -C #{testpath}/cfg-store find --format={prefix} zlib").strip
    zlib_dylib_file = Pathname.new "#{zlib_prefix}/lib/libz.a"
    assert_predicate zlib_dylib_file, :exist?
  end
end
