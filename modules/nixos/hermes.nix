{inputs, ...}: {
  flake.modules.nixos.hermes = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (inputs) hermes-agent hermes-webui;
    cfg = config.services.hermes-agent;
    inherit (config.zoldt.agents.hermes) credentials;
    secretEnv = import ./_secret-env.nix {inherit lib pkgs;};
    gateway = secretEnv "hermes-agent" {
      DEEPSEEK_API_KEY = credentials.deepseek-api-key;
      OPENCODE_GO_API_KEY = credentials.opencode-api-key;
      API_SERVER_KEY = credentials.hermes-api-server-key;
    };
    backend = secretEnv "hermes-backend" {
      HERMES_DASHBOARD_BASIC_AUTH_PASSWORD = credentials.hermes-dashboard-password;
    };
    # plugin.yaml must sit at the package root.
    plugin = name: src: pkgs.runCommand name {} "cp -r ${src} $out";
  in {
    imports = [hermes-agent.nixosModules.default hermes-webui.nixosModules.default];

    options.zoldt.agents.hermes.credentials = import ./_credentials.nix lib ["deepseek-api-key" "opencode-api-key" "hermes-api-server-key" "hermes-dashboard-password"];

    config = {
      systemd.services = {
        hermes-agent.serviceConfig = {
          inherit (gateway) ExecStartPre;
          EnvironmentFile = "-${gateway.file}";
        };
        hermes-backend.serviceConfig = {
          inherit (backend) ExecStartPre;
          EnvironmentFile = "-${backend.file}";
        };
      };

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;
        extraPackages = with pkgs; [ffmpeg nodejs ripgrep];
        # Upstream reports 0.0.0, failing plugins' requires_hermes checks.
        package = pkgs.hermes-agent.override {version = "0.22.2";};

        backend = {
          mode = "dashboard";
          host = lib.mkDefault "127.0.0.1";
          port = 9119;
        };

        extraPlugins = [
          (plugin "honcho" "${inputs.honcho}/hermes-plugin-honcho")
          (plugin "omh" "${inputs.oh-my-hermes}/src/plugin_bundle/omh")
          (plugin "hermex-push" "${inputs.hermex-push}/plugin")
        ];
        extraPythonPackages = [
          (cfg.package.python.pkgs.callPackage ./_honcho-ai.nix {inherit (pkgs) fetchPypi;})
        ];
        hermesHomeFiles."honcho.json" = lib.mkDefault (builtins.toJSON {
          baseUrl = "http://127.0.0.1:8000";
        });

        environment = {
          API_SERVER_ENABLED = "true";
          API_SERVER_HOST = lib.mkDefault "127.0.0.1";
          API_SERVER_PORT = "8642";
        };

        settings = {
          approvals.deny = ["git push --force*" "*curl*|*sh*" "*wget*|*sh*"];
          checkpoints.enabled = true;
          memory = {
            write_approval = true;
            # extraPlugins are linked as nix-managed-<name>.
            provider = "nix-managed-honcho";
          };
          plugins.enabled = ["omh" "hermex-push"];
          privacy.redact_pii = true;
          skills = {
            guard_agent_created = true;
            write_approval = true;
          };
        };
      };

      services.hermes-webui = {
        enable = true;
        host = lib.mkDefault "127.0.0.1";
        port = 8787;
        inherit (cfg) user group;
        hermesHome = "${cfg.stateDir}/.hermes";
        stateDir = "${cfg.stateDir}/.hermes-webui";
        agent.package = cfg.package;
      };
    };
  };
}
