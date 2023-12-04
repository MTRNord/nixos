{
  lib,
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [
    zsh
  ];

  # Ensure /etc/shells is setup for zsh
  programs.zsh.enable = true;
  environment.shells = with pkgs; [zsh];
}
