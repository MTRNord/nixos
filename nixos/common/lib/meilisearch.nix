{
  lib,
  pkgs,
  config,
  ...
}: {
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/meilisearch"
    ];
  };
  services = {
    meilisearch = {
      enable = true;
      noAnalytics = true;
      environment = "production";
      masterKeyEnvironmentFile = config.sops.secrets."meilisearchKey".path;
      payloadSizeLimit = "1.0Gb";
    };
  };
}
