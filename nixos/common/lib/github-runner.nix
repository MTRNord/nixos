{ lib, pkgs, config, ... }:
{
  users.users."node-yara-rs-runner" = { isNormalUser = false; };
  environment.systemPackages = with pkgs; [
    yarn
    nodejs_20
    curl
    rustup
    gnumake
    pkg-config
    openssl
    pcre
    protobufc
    autoconf
    automake
    libtool
    llvmPackages.libclang
    (yara.override { enableStatic = true; })
    gcc
  ];
  services.github-runners = {
    "node-yara-rs" = {
      url = "https://github.com/MTRNord/node-yara-rs";
      enable = true;
      extraLabels = [ "arm64" ];
      ephemeral = true;
      replace = true;
      user = "node-yara-rs-runner";
      tokenFile = config.sops.secrets.node_yara_rs_runner_tokenfile.path;
      extraPackages = with pkgs; [
        yarn
        nodejs_20
        curl
        rustup
        gnumake
        pkg-config
        openssl
        pcre
        protobufc
        autoconf
        automake
        libtool
        llvmPackages.libclang
        (yara.override { enableStatic = true; })
        gcc
      ];
      extraEnvironment = {
        YARA_LIBRARY_PATH = "${pkgs.yara}/lib";
        YARA_INCLUDE_DIR = "${pkgs.yara}/include";
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang}/lib";
        BINDGEN_EXTRA_CLANG_ARGS = "$(< ${pkgs.stdenv.cc}/nix-support/libc-crt1-cflags) \
          $(< ${pkgs.stdenv.cc}/nix-support/libc-cflags) \
          $(< ${pkgs.pkgs.stdenv.cc}/nix-support/cc-cflags) \
          $(< ${pkgs.stdenv.cc}/nix-support/libcxx-cxxflags) \
          ${lib.optionalString pkgs.stdenv.cc.isClang "-idirafter ${pkgs.stdenv.cc.cc}/lib/clang/${lib.getVersion pkgs.stdenv.cc.cc}/include"} \
          ${lib.optionalString pkgs.stdenv.cc.isGNU "-isystem ${pkgs.stdenv.cc.cc}/include/c++/${lib.getVersion pkgs.stdenv.cc.cc} -isystem ${pkgs.stdenv.cc.cc}/include/c++/${lib.getVersion pkgs.stdenv.cc.cc}/${pkgs.stdenv.hostPlatform.config} -idirafter ${pkgs.stdenv.cc.cc}/lib/gcc/${pkgs.stdenv.hostPlatform.config}/${lib.getVersion pkgs.stdenv.cc.cc}/include"} \
        ";
      };
    };
  };
}
