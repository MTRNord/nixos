{ lib, pkgs, config, stdenv, ... }:
{
  users.users."node-yara-rs-runner" = { isNormalUser = false; };
  services.github-runners = {
    "node-yara-rs" = {
      url = "https://github.com/MTRNord/node-yara-rs";
      enable = true;
      extraLabels = [ "arm64" ];
      ephemeral = true;
      replace = true;
      user = "node-yara-rs-runner";
      tokenFile = config.sops.secrets.node_yara_rs_runner_tokenfile.path;
      extraPackages = [
        pkgs.yarn
        pkgs.nodejs_20
        pkgs.curl
        pkgs.rustup
        pkgs.gnumake
        pkgs.pkg-config
        pkgs.openssl
        pkgs.pcre
        pkgs.protobufc
        pkgs.autoconf
        pkgs.automake
        pkgs.libtool
        pkgs.llvmPackages.libclang
        (pkgs.yara.override { enableStatic = true; })
        pkgs.gcc
      ];
      extraEnvironment = {
        YARA_LIBRARY_PATH = "${pkgs.yara}/lib";
        YARA_INCLUDE_DIR = "${pkgs.yara}/include";
        LIBCLANG_PATH = "${llvmPackages.libclang}/lib";
        BINDGEN_EXTRA_CLANG_ARGS = "$(< ${stdenv.cc}/nix-support/libc-crt1-cflags) \
          $(< ${stdenv.cc}/nix-support/libc-cflags) \
          $(< ${stdenv.cc}/nix-support/cc-cflags) \
          $(< ${stdenv.cc}/nix-support/libcxx-cxxflags) \
          ${lib.optionalString stdenv.cc.isClang "-idirafter ${stdenv.cc.cc}/lib/clang/${lib.getVersion stdenv.cc.cc}/include"} \
          ${lib.optionalString stdenv.cc.isGNU "-isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc} -isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc}/${stdenv.hostPlatform.config} -idirafter ${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${lib.getVersion stdenv.cc.cc}/include"} \
        ";
      };
    };
  };
}
