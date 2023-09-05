{ lib, pkgs, config, ... }:
{
  services = {
    envoy = {
      enable = true;
      settings = {
        admin = {
          access_log_path = "/dev/null";
          address = {
            socket_address = {
              protocol = "TCP";
              address = "127.0.0.1";
              port_value = "9901";
            };
          };
        };
        static_resources = {
          listeners = [
            {
              name = "postgres";
              address = {
                socket_address = {
                  address = "10.100.12.1";
                  port_value = 5000;
                };
              };
              filter_chains = [
                {
                  filters = [
                    # {
                    #   name = "envoy.filters.network.postgres_proxy";
                    #   typed_config = {
                    #     "@type" = "type.googleapis.com/envoy.extensions.filters.network.postgres_proxy.v3alpha.PostgresProxy";
                    #     stat_prefix = "destination";
                    #   };
                    # }
                    {
                      name = "envoy.filters.network.tcp_proxy";
                      typed_config = {
                        "@type" = "type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy";
                        stat_prefix = "destination";
                        cluster = "postgres_cluster";
                      };
                    }
                  ];
                }
              ];
            }
            {
              name = "postgres_100.64.0.1";
              address = {
                socket_address = {
                  address = "100.64.0.1";
                  port_value = 5000;
                };
              };
              filter_chains = [
                {
                  filters = [
                    # {
                    #   name = "envoy.filters.network.postgres_proxy";
                    #   typed_config = {
                    #     "@type" = "type.googleapis.com/envoy.extensions.filters.network.postgres_proxy.v3alpha.PostgresProxy";
                    #     stat_prefix = "destination";
                    #   };
                    # }
                    {
                      name = "envoy.filters.network.tcp_proxy";
                      typed_config = {
                        "@type" = "type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy";
                        stat_prefix = "destination";
                        cluster = "postgres_cluster";
                      };
                    }
                  ];
                }
              ];
            }
            {
              name = "postgres_127.0.0.1";
              address = {
                socket_address = {
                  address = "127.0.0.1";
                  port_value = 5000;
                };
              };
              filter_chains = [
                {
                  filters = [
                    # {
                    #   name = "envoy.filters.network.postgres_proxy";
                    #   typed_config = {
                    #     "@type" = "type.googleapis.com/envoy.extensions.filters.network.postgres_proxy.v3alpha.PostgresProxy";
                    #     stat_prefix = "destination";
                    #   };
                    # }
                    {
                      name = "envoy.filters.network.tcp_proxy";
                      typed_config = {
                        "@type" = "type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy";
                        stat_prefix = "destination";
                        cluster = "postgres_cluster";
                      };
                    }
                  ];
                }
              ];
            }
          ];
          clusters = [
            {
              name = "postgres_cluster";
              connect_timeout = "0.5s";
              type = "STRICT_DNS";
              lb_policy = "LEAST_REQUEST";
              load_assignment = {
                cluster_name = "postgres_cluster";
                endpoints = [
                  {
                    lb_endpoints = [
                      {
                        endpoint = {
                          health_check_config = {
                            port_value = 8008;
                          };
                          address = {
                            socket_address = {
                              address = "10.100.0.2";
                              port_value = 5432;
                            };
                          };
                        };
                      }
                      {
                        endpoint = {
                          health_check_config = {
                            port_value = 8008;
                          };
                          address = {
                            socket_address = {
                              address = "10.100.0.1";
                              port_value = 5432;
                            };
                          };
                        };
                      }
                    ];
                  }
                ];
              };
              health_checks = [
                {
                  timeout = "1s";
                  interval = "5s";
                  unhealthy_threshold = 3;
                  healthy_threshold = 2;
                  http_health_check = {
                    path = "/";
                  };
                }
              ];
            }
          ];
        };
      };
    };
  };
}
