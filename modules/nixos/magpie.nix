{inputs, ...}: {
  flake.modules.nixos.magpie = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.zoldt.agents.magpie;
    secretEnv = import ./_secret-env.nix {inherit lib pkgs;};
    magpie = secretEnv "magpie" {MAGPIE_WEB_KEY = cfg.credentials.magpie-web-key;};
  in {
    imports = [inputs.quadlet-nix.nixosModules.quadlet];

    options.zoldt.agents.magpie = {
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host address for the Magpie web service.";
      };
      publicUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:3430";
        description = "Base URL clients use to reach the Magpie web service.";
      };
      credentials = import ./_credentials.nix lib ["magpie-web-key"];
    };

    config = {
      virtualisation.podman.enable = true;
      virtualisation.quadlet = {
        autoUpdate.enable = true;
        volumes.magpie = {};
        containers.magpie = {
          serviceConfig = {
            inherit (magpie) ExecStartPre;
            Restart = "always";
          };
          containerConfig = {
            name = "magpie";
            image = "ghcr.io/yetone/magpie:latest";
            environmentFiles = [magpie.file];
            volumes = ["${config.virtualisation.quadlet.volumes.magpie.ref}:/config"];
            exec = "web --addr 0.0.0.0:3430 --no-open";
            publishPorts = ["${cfg.listenAddress}:3430:3430"];
            environments.MAGPIE_PUBLIC_URL = cfg.publicUrl;
            autoUpdate = "registry";
            timezone = "local";
          };
        };
      };
    };
  };
}
