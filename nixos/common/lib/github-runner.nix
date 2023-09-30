{ lib, pkgs, config, ... }:
{
  users.users."node-yara-rs-runner" = { isNormalUser = false; };
  services.github-runners = {
    "node-yara-rs" = {
      url = "https://github.com/MTRNord/node-yara-rs";
      enable = true;
      extraLabels = [ "arm64" ];
      ephemeral = true;
      user = "node-yara-rs-runner";
      tokenFile = config.sops.secrets.node_yara_rs_runner_tokenfile.path;
      extraPackages = [
        pkgs.yarn
        pkgs.nodejs_20
        pkgs.curl
      ];
    };
  };
}
