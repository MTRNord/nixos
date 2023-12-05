{
  lib,
  pkgs,
  config,
  ...
}: {
  services = {
    meilisearch = {
      enable = true;
      noAnalytics = true;
      environment = "production";
      masterKeyEnvironmentFile = config.sops.secrets."meilisearchKey".path;
    };
  };
}
