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
        owner = "pgbouncer";
        repo = "pgbouncer";
        rev = "60708022d5b934fa53c51849b9f02d87a7881b11";
        fetchSubmodules = true;
        hash = "sha256-ojZ23n8Bq4288yna9RVhDvZe+AcPEInG93z7/o3uQwY=";
      };

      nativeBuildInputs = [ pkgs.python312 pkgs.pandoc pkgs.libevent pkgs.libtool pkgs.autoconf pkgs.automake pkgs.openssl pkgs.pkg-config pkgs.autoreconfHook ];

      autoreconfPhase = ''
        ./autogen.sh
      '';

    });
  };

  patroni = prev.patroni.overrideAttrs (old: {
    nativeCheckInputs = with pkgs.python312.pythonPackages; [
      flake8
      mock
      pytestCheckHook
      pytest-cov
      requests
    ];
  });

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
