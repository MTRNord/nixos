{
  lib,
  pkgs,
  config,
  ...
}: {
  # SOPS
  sops = {
    age = {
      sshKeyPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
      # This is using an age key that is expected to already be in the filesystem
      keyFile = "/persist/var/lib/sops-nix/key.txt";
      # This will generate a new key if the key specified above does not exist
      generateKey = true;
    };
    gnupg.sshKeyPaths = ["/persist/etc/ssh/ssh_host_rsa_key"];

    defaultSopsFile = ./secrets/secrets.yaml;

    # keys
    secrets = {
      marcel_initial_password.neededForUsers = true;
      root_initial_password.neededForUsers = true;
      "wireguard/worker-1/wg0/private_key" = {};
      "wireguard/worker-1/wg1/private_key" = {};
      "wireguard/worker-2/wg0/private_key" = {};
      "wireguard/worker-2/wg1/private_key" = {};
      ssh_host_ed25519_key = {
        mode = "0600";
        path = "/etc/ssh/ssh_host_ed25519_key";
      };
      ssh_host_ed25519_key_pub = {
        mode = "0644";
        path = "/etc/ssh/ssh_host_ed25519_key.pub";
      };
      ssh_host_rsa_key = {
        mode = "0600";
        path = "/etc/ssh/ssh_host_rsa_key";
      };
      ssh_host_rsa_key_pub = {
        mode = "0644";
        path = "/etc/ssh/ssh_host_rsa_key.pub";
      };
      "ssh/marcel/id_ed25519" = {
        mode = "0600";
        owner = config.users.users.marcel.name;
        path = "/home/marcel/.ssh/id_ed25519";
      };
      "ssh/marcel/id_ed25519_pub" = {
        mode = "0644";
        owner = config.users.users.marcel.name;
        path = "/home/marcel/.ssh/id_ed25519.pub";
      };
      "ssh/root/id_ed25519" = {
        mode = "0600";
        owner = config.users.users.marcel.name;
        path = "/root/.ssh/id_ed25519";
      };
      "ssh/root/id_ed25519_pub" = {
        mode = "0644";
        owner = config.users.users.marcel.name;
        path = "/root/.ssh/id_ed25519.pub";
      };
      backup_password = {};
      forgejo_runner_token = {};
      #  sops.secrets.forgejo_runner_token.owner = config.users."gitea-runner".name;
      "asterisk/pjsip_conf" = {
        restartUnits = ["asterisk.service"];
        mode = "0777";
        path = "/etc/asterisk/pjsip.conf";
      };
      "asterisk/prometheus_conf" = {
        restartUnits = ["asterisk.service"];
        mode = "0777";
        path = "/etc/asterisk/prometheus.conf";
      };
      "asterisk/cel_pgsql_conf" = {
        restartUnits = ["asterisk.service"];
        mode = "0777";
        path = "/etc/asterisk/cel_pgsql.conf";
      };
      "asterisk/cdr_pgsql_conf" = {
        restartUnits = ["asterisk.service"];
        mode = "0777";
        path = "/etc/asterisk/cdr_pgsql.conf";
      };
      "patroni/replication_username" = {
        restartUnits = ["patroni.service"];
        owner = "patroni";
        group = "patroni";
      };
      "patroni/replication_password" = {
        restartUnits = ["patroni.service"];
        owner = "patroni";
        group = "patroni";
      };
      "patroni/replication_superuser_username" = {
        restartUnits = ["patroni.service"];
        owner = "patroni";
        group = "patroni";
      };
      "patroni/replication_superuser_password" = {
        restartUnits = ["patroni.service"];
        owner = "patroni";
        group = "patroni";
      };
      "discourse/db_password" = {
        restartUnits = ["discourse.service"];
        owner = "discourse";
        group = "discourse";
      };
      "discourse/secret_key_base" = {
        restartUnits = ["discourse.service"];
        owner = "discourse";
        group = "discourse";
      };
      "discourse/admin_password" = {
        restartUnits = ["discourse.service"];
        owner = "discourse";
        group = "discourse";
      };
      "discourse/mail_password" = {
        restartUnits = ["discourse.service"];
        owner = "discourse";
        group = "discourse";
      };
      "discourse/redis_password" = {
        restartUnits = ["discourse.service"];
        owner = "discourse";
        group = "discourse";
      };
      # pgadmin_password = {
      #   owner = "pgadmin";
      #   group = "pgadmin";
      # };
      pgbouncer_auth_file = {
        restartUnits = ["pgbouncer.service"];
        owner = "pgbouncer";
        group = "pgbouncer";
      };
      pgcat_settings_file_template = {
        path = "/etc/confd/templates/pgcat.toml.tmpl";
      };

      kubernetes_ca_file = {};
      kubernetes_ca_client_file = {};
      node_yara_rs_runner_tokenfile = {
        owner = "node-yara-rs-runner";
        group = "node-yara-rs-runner";
      };
      "meilisearchKey" = {};
      "mastodon/otp_secret" = {
        restartUnits = [
          "mastodon-sidekiq-all.service"
          "mastodon-streaming-1.service"
          "mastodon-streaming-2.service"
          "mastodon-streaming-3.service"
          "mastodon-streaming-4.service"
          "mastodon-streaming-5.service"
          "mastodon-streaming-6.service"
          "mastodon-streaming-7.service"
          "mastodon-streaming-8.service"
          "mastodon-web.service"
          "redis-mastodon.service"
        ];
        owner = "mastodon";
        group = "mastodon";
      };
      "mastodon/secret_key" = {
        restartUnits = [
          "mastodon-sidekiq-all.service"
          "mastodon-streaming-1.service"
          "mastodon-streaming-2.service"
          "mastodon-streaming-3.service"
          "mastodon-streaming-4.service"
          "mastodon-streaming-5.service"
          "mastodon-streaming-6.service"
          "mastodon-streaming-7.service"
          "mastodon-streaming-8.service"
          "mastodon-web.service"
          "redis-mastodon.service"
        ];
        owner = "mastodon";
        group = "mastodon";
      };
      "mastodon/vapid_private_key" = {
        restartUnits = [
          "mastodon-sidekiq-all.service"
          "mastodon-streaming-1.service"
          "mastodon-streaming-2.service"
          "mastodon-streaming-3.service"
          "mastodon-streaming-4.service"
          "mastodon-streaming-5.service"
          "mastodon-streaming-6.service"
          "mastodon-streaming-7.service"
          "mastodon-streaming-8.service"
          "mastodon-web.service"
          "redis-mastodon.service"
        ];
        owner = "mastodon";
        group = "mastodon";
      };
      "mastodon/vapid_public_key" = {
        restartUnits = [
          "mastodon-sidekiq-all.service"
          "mastodon-streaming-1.service"
          "mastodon-streaming-2.service"
          "mastodon-streaming-3.service"
          "mastodon-streaming-4.service"
          "mastodon-streaming-5.service"
          "mastodon-streaming-6.service"
          "mastodon-streaming-7.service"
          "mastodon-streaming-8.service"
          "mastodon-web.service"
          "redis-mastodon.service"
        ];
        owner = "mastodon";
        group = "mastodon";
      };
      "mastodon/smtp_password" = {
        restartUnits = [
          "mastodon-sidekiq-all.service"
          "mastodon-streaming-1.service"
          "mastodon-streaming-2.service"
          "mastodon-streaming-3.service"
          "mastodon-streaming-4.service"
          "mastodon-streaming-5.service"
          "mastodon-streaming-6.service"
          "mastodon-streaming-7.service"
          "mastodon-streaming-8.service"
          "mastodon-web.service"
          "redis-mastodon.service"
        ];
        owner = "mastodon";
        group = "mastodon";
      };
      "mastodon/db_password" = {
        restartUnits = [
          "mastodon-sidekiq-all.service"
          "mastodon-streaming-1.service"
          "mastodon-streaming-2.service"
          "mastodon-streaming-3.service"
          "mastodon-streaming-4.service"
          "mastodon-streaming-5.service"
          "mastodon-streaming-6.service"
          "mastodon-streaming-7.service"
          "mastodon-streaming-8.service"
          "mastodon-web.service"
          "redis-mastodon.service"
        ];
        owner = "mastodon";
        group = "mastodon";
      };
    };
  };
}
