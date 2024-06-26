# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  nixpkgs-unstable,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
      (self: super: {
        lsd = nixpkgs-unstable.legacyPackages.aarch64-linux.lsd;
      })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };
  home = {
    username = "marcel";
    homeDirectory = "/home/marcel";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  # home.packages = with pkgs; [ steam ];

  home.file.".ssh/allowed_signers".text = ''
    * ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHeAYFhGNeDKYsb9qQx6V6OzWTr4M7Gue3Eka2Y3I56b marcel@worker-1
    * ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHeAYFhGNeDKYsb9qQx6V6OzWTr4M7Gue3Eka2Y3I56b marcel@worker-2
  '';

  # Enable home-manager and git
  programs = {
    home-manager.enable = true;
    k9s.enable = true;
    less.enable = true;
    ssh = {
      enable = true;
    };

    git = {
      enable = true;
      userName = "MTRNord";
      userEmail = "support@nordgedanken.dev";

      extraConfig = {
        # Sign all commits using ssh key
        commit.gpgsign = true;
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        user.signingkey = "~/.ssh/id_ed25519.pub";
      };
    };

    zsh = {
      enable = true;
      shellAliases = {
        update = "cd /etc/nixos/nixos && git pull && sudo nixos-rebuild switch --flake .#$(hostname) && home-manager switch --flake .#marcel@$(hostname)";
        rebuild-draupnir-yara = "cd /home/marcel/Draupnir && git stash && git pull && git stash pop && yarn describe-version && podman buildx build --tag git.nordgedanken.dev/kubernetes/gitops/gnuxie/draupnir:yara --platform linux/arm64 . && podman push git.nordgedanken.dev/kubernetes/gitops/gnuxie/draupnir:yara";
      };
      history = {
        size = 10000;
        path = "${config.xdg.dataHome}/zsh/history";
      };
      oh-my-zsh = {
        enable = true;
        plugins = ["git" "thefuck"];
        theme = "robbyrussell";
      };
    };

    lsd = {
      enable = true;
      enableAliases = true;
      settings = {
        classic = false;
        blocks = [
          "permission"
          "user"
          "group"
          "size"
          "git"
          "date"
          "name"
        ];
        total-size = true;
        header = true;
      };
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
