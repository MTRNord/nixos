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
    pgbouncer = prev.pgbouncer.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        owner = "knizhnik";
        repo = "pgbouncer";
        rev = "70ad45b7ec0d183caa65e15fef2e7b8ed6926957";
        fetchSubmodules = true;
        hash = "sha256-VYP8CmdKCzmx7YzyQPuBHhTvkyKwy0PahbnDnzKdRv0=";
      };

      nativeBuildInputs = [ pkgs.libevent pkgs.libtool pkgs.autoconf pkgs.automake pkgs.openssl pkgs.pkg-config pkgs.autoreconfHook ];

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
