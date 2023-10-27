{ inputs, lib, pkgs, config, ... }:
{
  services.discourse = {
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.discourse;
    enable = true;
    database = {
      host = "postgres.internal.midnightthoughts.space";
      passwordFile = config.sops.secrets."discourse/db_password".path;
    };
    backendSettings = {
      db_port = 5000;
    };
    secretKeyBaseFile = config.sops.secrets."discourse/secret_key_base".path;
    mail = {
      outgoing = {
        port = 465;
        serverAddress = "mail.nordgedanken.dev";
        username = "support@miki.community";
        passwordFile = config.sops.secrets."discourse/mail_password".path;
        authentication = "login";
        forceTLS = true;
      };
      incoming.enable = false;
      contactEmailAddress = "support@miki.community";
    };
    redis = {
      host = "localhost";
    };
    hostname = "personal.midnightthoughts.space";
    plugins = with config.services.discourse.package.plugins; [
      discourse-github
      discourse-solved
      discourse-docs
      discourse-calendar
      discourse-github
      discourse-assign
      discourse-solved
      discourse-chat-integration
      discourse-data-explorer
      pkgs.discourse-footnote
      pkgs.discourse-gamification
      pkgs.discourse-cakeday
      pkgs.discourse-templates
      #pkgs.discourse-spoiler-alert
    ];
    siteSettings = {
      required = {
        title = "MTRNords personal space";
        contact_email = "support@miki.community";
        notification_email = lib.mkForce "noreply@forum.miki.community";
      };
      login = {
        login_required = true;
        must_approve_users = true;
        enable_local_logins = true;
        enable_local_logins_via_email = true;
        allow_new_registrations = false;
      };
      spam = {
        notify_mods_when_user_silenced = true;
      };
      legal = {
        tos_url = "https://docs.draupnir.midnightthoughts.space/docs/code_of_conduct/";
      };
      plugins = {
        calendar_enabled = true;
        chat_enabled = false;
      };
    };
    admin = {
      username = "MTRNord";
      fullName = "Marcel";
      email = "mtrnord@nordgedanken.dev";
      passwordFile = config.sops.secrets."discourse/admin_password".path;
    };
  };

  systemd.services.discourse.environment = { UNICORN_WORKERS = "8"; };
}
