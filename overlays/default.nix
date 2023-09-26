# This file defines overlays
{ inputs, pkgs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    asterisk = prev.asterisk.overrideAttrs (old: {
      preBuild = ''
        #cat third-party/pjproject/source/pjlib-util/src/pjlib-util/scanner.c
        make menuselect.makeopts
        cat menuselect.makeopts
        ./menuselect/menuselect --enable cdr_pgsql menuselect.makeopts
        ./menuselect/menuselect --enable cel_pgsql menuselect.makeopts
        cat menuselect.makeopts
        substituteInPlace menuselect.makeopts --replace 'codec_opus_open_source ' ""
        substituteInPlace menuselect.makeopts --replace 'format_ogg_opus_open_source ' ""
      '';
      buildInputs = old.buildInputs ++ [ pkgs.postgresql ];
    });
    # envoy = prev.envoy.overrideAttrs (old: {
    #   bazelBuildFlags = old.bazelBuildFlags ++ [ "--//contrib/postgres_proxy/filters/network/source:enabled" ];
    # });
    discourse-calendar = prev.discourse-calendar.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        owner = "discourse";
        repo = "discourse-calendar";
        rev = "4d4fe40d09f7232b1348e1ff910b37b2cec0835d";
        hash = "sha256-w1sqE3KxwrE8SWqZUtPVhjITOPFXwlj4iPyPZeSfvtI";
      };
    });
    discourse-assign = prev.discourse-assign.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        owner = "discourse";
        repo = "discourse-assign";
        rev = "e9c7cb5c3f90109bc47223b0aa4054d681e9cc04";
        hash = "sha256-w1h1dCSyOml+AT7lPKENYfawm6BU2De5CyBHrDnDcrM=";
      };
    });
    discourse-chat-integration = prev.discourse-chat-integration.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        owner = "discourse";
        repo = "discourse-chat-integration";
        rev = "4f9ccb58cae8600dcb6db84f38f235283911e6e8";
        hash = "sha256-Em9aAwAfUoqsOHLrqNhxUQXsO4Owydf9nhCHbBaqqpg=";
      };
    });
    discourse-data-explorer = prev.discourse-data-explorer.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        owner = "discourse";
        repo = "discourse-data-explorer";
        rev = "06193f27ef15828479eea61ae4a80bf59806a535";
        hash = "sha256-afjqgi2gzRpbZt5K9yXPy4BJ5qRv7A4ZkXHX85+Cv7s=";
      };
    });
    discourse-data-explorer = prev.discourse-data-explorer.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        owner = "discourse";
        repo = "discourse-data-explorer";
        rev = "06193f27ef15828479eea61ae4a80bf59806a535";
        hash = "sha256-afjqgi2gzRpbZt5K9yXPy4BJ5qRv7A4ZkXHX85+Cv7s=";
      };
    });
    pgbouncer = prev.pgbouncer.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        owner = "knizhnik";
        repo = "pgbouncer";
        rev = "9b65938e377ae43d838e31a69cb1c9d3e8b38661";
        fetchSubmodules = true;
        hash = "sha256-GCDb2BJlHSpY0pE56HMTJL51UKj4c05/JSaO8TRPGK0=";
      };

      nativeBuildInputs = [ pkgs.python311 pkgs.pandoc pkgs.libevent pkgs.libtool pkgs.autoconf pkgs.automake pkgs.openssl pkgs.pkg-config pkgs.autoreconfHook ];

      autoreconfPhase = ''
        ./autogen.sh
      '';

    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
