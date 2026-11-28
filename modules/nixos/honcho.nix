{inputs, ...}: {
  flake.modules.nixos.honcho = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.virtualisation.quadlet) networks volumes;
    inherit (config.zoldt.agents.honcho) credentials;
    secretEnv = import ./_secret-env.nix {inherit lib pkgs;};
    db = secretEnv "honcho-db" {POSTGRES_PASSWORD = credentials.honcho-db-password;};
    apiEnv = secretEnv "honcho-api" {PGPASSWORD = credentials.honcho-db-password;};
    keys = secretEnv "honcho-models" {
      DEEPSEEK_API_KEY = credentials.deepseek-api-key;
      LLM_OPENAI_API_KEY = credentials.openrouter-api-key;
    };

    deepseek = prefix: {
      "${prefix}__TRANSPORT" = "openai";
      "${prefix}__MODEL" = "deepseek-flash";
      "${prefix}__OVERRIDES__BASE_URL" = "https://api.deepseek.com";
      "${prefix}__OVERRIDES__API_KEY_ENV" = "DEEPSEEK_API_KEY";
    };
    api = {
      networks = [networks.honcho.ref];
      image = "ghcr.io/plastic-labs/honcho:latest";
      environmentFiles = [keys.file apiEnv.file];
      environments =
        {
          DB_CONNECTION_URI = "postgresql+psycopg://honcho@honcho-db:5432/honcho";
          CACHE_URL = "redis://honcho-cache:6379/0?suppress=true";
          CACHE_ENABLED = "true";
          EMBEDDING_MODEL_CONFIG__TRANSPORT = "openai";
          EMBEDDING_MODEL_CONFIG__MODEL = "qwen/qwen3-embedding-8b";
          EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL = "https://openrouter.ai/api/v1";
          # Request Honcho's 1536 dimensions instead of Qwen3's native 4096.
          EMBEDDING_MODEL_CONFIG__DIMENSIONS_MODE = "always";
        }
        // lib.mergeAttrsList (map deepseek [
          "DERIVER_MODEL_CONFIG"
          "SUMMARY_MODEL_CONFIG"
          "DREAM_DEDUCTION_MODEL_CONFIG"
          "DREAM_INDUCTION_MODEL_CONFIG"
          "DIALECTIC_LEVELS__minimal__MODEL_CONFIG"
          "DIALECTIC_LEVELS__low__MODEL_CONFIG"
          "DIALECTIC_LEVELS__medium__MODEL_CONFIG"
          "DIALECTIC_LEVELS__high__MODEL_CONFIG"
          "DIALECTIC_LEVELS__max__MODEL_CONFIG"
        ]);
    };
    apiService = {
      ExecStartPre = keys.ExecStartPre ++ apiEnv.ExecStartPre;
      Restart = "always";
    };
    containers = {
      honcho-db = {
        serviceConfig = {
          inherit (db) ExecStartPre;
          Restart = "always";
        };
        containerConfig = {
          name = "honcho-db";
          networks = [networks.honcho.ref];
          image = "docker.io/pgvector/pgvector:pg18";
          environmentFiles = [db.file];
          volumes = ["${volumes.honcho_pgdata.ref}:/var/lib/postgresql"];
          environments = {
            POSTGRES_USER = "honcho";
            POSTGRES_DB = "honcho";
          };
        };
      };

      honcho-cache.containerConfig = {
        name = "honcho-cache";
        networks = [networks.honcho.ref];
        image = "docker.io/valkey/valkey:9";
        exec = "valkey-server --save ''";
      };

      # Restarts until PostgreSQL is ready. Podman's DNAT bypasses the host firewall.
      honcho-api = {
        serviceConfig = apiService;
        containerConfig =
          api
          // {
            name = "honcho-api";
            exec = "sh docker/entrypoint.sh";
            publishPorts = ["127.0.0.1:8000:8000"];
          };
      };

      honcho-deriver = {
        serviceConfig = apiService;
        containerConfig =
          api
          // {
            name = "honcho-deriver";
            exec = "/app/.venv/bin/python -m src.deriver";
          };
      };
    };
  in {
    imports = [inputs.quadlet-nix.nixosModules.quadlet];

    options.zoldt.agents.honcho.credentials = import ./_credentials.nix lib ["honcho-db-password" "deepseek-api-key" "openrouter-api-key"];

    config = {
      virtualisation.podman.enable = true;
      virtualisation.quadlet = {
        autoUpdate.enable = true;
        networks.honcho = {};
        volumes.honcho_pgdata = {};
        containers = lib.mapAttrs (_: container:
          container
          // {
            containerConfig =
              container.containerConfig
              // {
                autoUpdate = "registry";
                timezone = "local";
              };
          })
        containers;
      };
    };
  };
}
