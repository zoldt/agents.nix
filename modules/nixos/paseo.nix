{inputs, ...}: {
  flake.modules.nixos.paseo = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.paseo.nixosModules.default];

    # Paseo inherits the service user's profiles; keep the enabled provider CLIs available without Home Manager.
    environment.systemPackages = [
      pkgs.llm-agents.prime-agent
      pkgs.autolith
    ];
    users.users.${config.services.paseo.user}.packages = lib.mkBefore [
      pkgs.llm-agents.claude-code
      pkgs.llm-agents.codex
      pkgs.llm-agents.pi
      pkgs.gh
    ];

    services.paseo = {
      enable = true;
      listenAddress = lib.mkDefault "127.0.0.1";
      port = 6767;
      openFirewall = false;

      relay = {
        enable = true;
        mode = "hosted";
        host = "";
        port = 443;
        useTls = true;
        publicUseTls = null;
      };

      settings = {
        version = 1;
        daemon = {
          cors.allowedOrigins = ["https://app.paseo.sh"];
          relay.enabled = false;
        };
        app.baseUrl = "https://app.paseo.sh";
        agents.providers = {
          prime-agent = {
            extends = "acp";
            label = "Prime Agent";
            description = "Prime Intellect self-improving RLM agent";
            command = ["prime-agent" "--mode" "acp"];
          };
          autolith = {
            extends = "acp";
            label = "Autolith";
            description = "Live, self-modifying Common Lisp agent";
            command = ["autolith" "acp"];
          };
          muse.enabled = false;
          antigravity.enabled = false;
          opencode.enabled = false;
          copilot.enabled = false;
        };
      };
    };
  };
}
