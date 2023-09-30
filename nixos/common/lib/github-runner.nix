{ lib, pkgs, config, ... }:
{
  users.users."node-yara-rs-runner" = { isNormalUser = false; };
  environment.systemPackages = with pkgs; [
    yarn
    nodejs_20
    curl
    rustup
    (yara.override { enableStatic = true; })
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
        (yara.override { enableStatic = true; })
        nix
      ];
      extraEnvironment = {
        YARA_LIBRARY_PATH = "${pkgs.yara}/lib";
        YARA_INCLUDE_DIR = "${pkgs.yara}/include";
        LIBCLANG_PATH = "${pkgs.clang.cc.lib}/lib";
        BINDGEN_EXTRA_CLANG_ARGS = "$(< ${pkgs.clang}/nix-support/cc-cflags) $(< ${pkgs.clang}/nix-support/libc-cflags) $(< ${pkgs.clang}/nix-support/libcxx-cxxflags) $NIX_CFLAGS_COMPILE";
      };
    };
  };
}
