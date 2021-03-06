{ config, lib, ... }:
let
  cfg = config.services.jormungandr-explorer;
  cfgJormungandr = config.services.jormungandr;

  inherit (lib) mkEnableOption mkOption types mkIf;
  inherit (builtins) toFile toJSON;
in {
  options = {
    services.jormungandr-explorer = {
      enable = mkEnableOption "Jörmungandr Explorer";

      package = mkOption {
        type = types.package;
        default = (import ../. { }).explorerFrontend {
          configJSON = cfg.configFile;
        };
        defaultText = "explorerFrontend";
        description = ''
          The Jörmungandr explorer-frontend package that should be used.
        '';
      };

      jormungandrApi = mkOption {
        type = types.str;
        default = "http://localhost/explorer/graphql";
      };

      configFile = mkOption {
        type = types.path;
        default = toFile "config.json" (toJSON {
          explorerUrl = cfg.jormungandrApi;
          networkSettings = {
            genesisTimestamp = 1569335341;
            slotsPerEpoch = 5000;
            slotDuration = 2;
          };
          assuranceLevels = {
            low = 3;
            medium = 7;
            high = 9;
          };
          currency = {
            symbol = "ADA";
            decimals = 6;
          };
        });
      };

      virtualHost = mkOption {
        type = types.str;
        default = "jormungandr-explorer.localhost";
      };

      enableSSL = mkOption {
        type = types.bool;
        description = "Force HTTPS and get letsencrypt certificate";
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.jormungandr.enable = true;
    services.jormungandr.enableExplorer = true;

    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      serverTokens = false;

      commonHttpConfig = ''
        log_format x-fwd '$remote_addr - $remote_user [$time_local] '
                          '"$request" $status $body_bytes_sent '
                          '"$http_referer" "$http_user_agent" "$http_x_forwarded_for"';
        access_log syslog:server=unix:/dev/log x-fwd;
      '';

      virtualHosts = {
        ${cfg.virtualHost} = let
          headers = ''
            add_header 'Vary' 'Origin' always;
            add_header 'access-control-allow-origin' $origin always;
            add_header 'Access-Control-Allow-Methods' 'POST, OPTIONS, GET' always;
            add_header 'Access-Control-Allow-Headers' 'User-Agent,X-Requested-With,Content-Type' always;
          '';
        in {
          forceSSL = cfg.enableSSL;
          enableACME = cfg.enableSSL;

          locations."/" = {
            root = cfg.package;
            index = "index.html";
            tryFiles = "$uri $uri/ /index.html?$args";
          };

          locations."/explorer/graphql" = {
            extraConfig = ''
              if ($request_method = OPTIONS) {
                ${headers}
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain; charset=utf-8';
                add_header 'Content-Length' 0;
                return 204;
                break;
              }

              if ($request_method = POST) {
                ${headers}
              }

              proxy_pass http://${config.services.jormungandr.rest.listenAddress};
              proxy_set_header Host $host:$server_port;
              proxy_set_header X-Real-IP $remote_addr;
            '';
          };
          locations."/api/v0/settings" = {
            extraConfig = ''
              if ($request_method = OPTIONS) {
                ${headers}
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain; charset=utf-8';
                add_header 'Content-Length' 0;
                return 204;
                break;
              }

              if ($request_method = GET) {
               ${headers}
              }

              proxy_pass http://${config.services.jormungandr.rest.listenAddress};
              proxy_set_header Host $host:$server_port;
              proxy_set_header X-Real-IP $remote_addr;
            '';
          };
        };
      };
    };
  };
}
