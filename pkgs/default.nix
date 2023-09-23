# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  # example = pkgs.callPackage ./example { };
  discourse-footnote = pkgs.discourse.mkDiscoursePlugin
    {
      name = "discourse-footnote";
      src = pkgs.fetchFromGitHub {
        owner = "discourse";
        repo = "discourse-footnote";
        rev = "0986e5af27b1a34928e17b8824bfc6de1ba55199";
        sha256 = "sha256-jF7FzFjMcy5YNdfd5W7gvkzl755UbEmlHUl9j67/DvE=";
      };
    };
  discourse-cakeday = pkgs.discourse.mkDiscoursePlugin
    {
      name = "discourse-cakeday";
      src = pkgs.fetchFromGitHub {
        owner = "discourse";
        repo = "discourse-cakeday";
        rev = "14538bc419ed6bd268d116c128d970c9c380c822";
        sha256 = "sha256-1OtI+or47XBwq3mdRfOIg3OGCfVzNcK4hseJs7H+Vm8";
      };
    };
  discourse-templates = pkgs.discourse.mkDiscoursePlugin
    {
      name = "discourse-templates";
      src = pkgs.fetchFromGitHub {
        owner = "discourse";
        repo = "discourse-templates";
        rev = "decadc74394d1db64c59abdf48859cf4fdbca57c";
        sha256 = "sha256-rhkwAZGq9WPqVBuLc5eZJz+ve8x1nk6pVoYNEfDmPwI=";
      };
    };
#  discourse-spoiler-alert = pkgs.discourse.mkDiscoursePlugin
#    {
#      name = "discourse-spoiler-alert";
#      src = pkgs.fetchFromGitHub {
#        owner = "discourse";
#        repo = "discourse-spoiler-alert";
#        rev = "b57e79343acc15cb2c0a032a2deb29ad4b9d53cc";
#        sha256 = "sha256-Ypt6PYCZzArCv9KkCtw5rfT6++dDoUx5q9m/eMvP0Sc";
#      };
#    };
}
