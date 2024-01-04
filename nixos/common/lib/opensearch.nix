{
  lib,
  pkgs,
  config,
  ...
}: {
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/opensearch"
    ];
  };

  sops.secrets = {
    "opensearch/root_ca_key" = {
      user = "opensearch";
      group = "opensearch";
    };
    "opensearch/root_ca" = {
      user = "opensearch";
      group = "opensearch";
    };
    "opensearch/admin_key" = {
      user = "opensearch";
      group = "opensearch";
    };
    "opensearch/admin" = {
      user = "opensearch";
      group = "opensearch";
    };
    "opensearch/node1_key" = {
      user = "opensearch";
      group = "opensearch";
    };
    "opensearch/node1" = {
      user = "opensearch";
      group = "opensearch";
    };
  };

  services = {
    opensearch = {
      enable = true;
      settings = {
        "plugins.security.disabled" = false;
        "plugins.security.ssl.transport.pemcert_filepath" = config.sops.secrets."opensearch/node1".path;
        "plugins.security.ssl.transport.pemkey_filepath" = config.sops.secrets."opensearch/node1_key".path;
        "plugins.security.ssl.transport.pemtrustedcas_filepath" = config.sops.secrets."opensearch/root_ca".path;
        "plugins.security.ssl.http.enabled" = true;
        "plugins.security.ssl.http.pemcert_filepath" = config.sops.secrets."opensearch/node1".path;
        "plugins.security.ssl.http.pemkey_filepath" = config.sops.secrets."opensearch/node1_key".path;
        "plugins.security.ssl.http.pemtrustedcas_filepath" = config.sops.secrets."opensearch/root_ca".path;
        "plugins.security.allow_default_init_securityindex" = true;
        "plugins.security.authcz.admin_dn" = "CN=A,OU=Devops,O=Nordgedanken,L=Flensburg,ST=Schleswig-Holstein,C=DE";
        "plugins.security.nodes_dn" = "CN=search.midnightthoughts.space,OU=Devops,O=Nordgedanken,L=Flensburg,ST=Schleswig-Holstein,C=DE";
        "plugins.security.audit.type" = "internal_opensearch";
        "plugins.security.enable_snapshot_restore_privilege" = true;
        "plugins.security.check_snapshot_restore_write_privileges" = true;
        "plugins.security.restapi.roles_enabled" = [
          "all_access"
          "security_rest_api_access"
        ];
      };
    };
  };
}
