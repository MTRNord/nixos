{
  lib,
  pkgs,
  config,
  ...
}: {
  users.users."node-yara-rs-runner" = {isNormalUser = false;};
  environment.systemPackages = with pkgs; [
    yarn
    nodejs_20
    curl
    rustup
    yara
  ];
  services.github-runners = {
    "node-yara-rs" = {
      url = "https://github.com/MTRNord/node-yara-rs";
      enable = false;
      extraLabels = ["arm64"];
      ephemeral = true;
      replace = true;
      user = "node-yara-rs-runner";
      tokenFile = config.sops.secrets.node_yara_rs_runner_tokenfile.path;
      extraPackages = with pkgs; [
        yarn
        nodejs_20
        curl
        rustup
        yara
        clang_16
        binutils
      ];
      extraEnvironment = {
        #YARA_LIBRARY_PATH = "${pkgs.yara}/lib";
        #YARA_INCLUDE_DIR = "${pkgs.yara}/include";
        LIBCLANG_PATH = "${pkgs.clang_16.cc.lib}/lib";
        BINDGEN_EXTRA_CLANG_ARGS = lib.readFile "${pkgs.clang_16}/nix-support/cc-cflags" + " " + lib.readFile "${pkgs.clang_16}/nix-support/libc-cflags" + " " + lib.readFile "${pkgs.clang_16}/nix-support/libcxx-cxxflags" + " " + "-idirafter ${pkgs.clang_16}/lib/clang/${lib.getVersion pkgs.clang_16}/include";
      };
    };
  };
}
