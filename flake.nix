{
  description = "Zoldt's agent platform: Home Manager and NixOS modules for AI agents and their services";

  outputs = inputs: import ./outputs inputs;

  inputs = {
    # Core
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    import-tree.url = "github:denful/import-tree";

    # Own nixpkgs (no follows) so packages hit the numtide binary cache.
    llm-agents.url = "github:numtide/llm-agents.nix";
    autolith.url = "github:lambda-symbolics/autolith";
    hermes-agent.url = "github:NousResearch/hermes-agent";
    hermes-webui.url = "github:nesquena/hermes-webui";
    hermex-push = {
      url = "github:uzairansaruzi/hermex-push";
      flake = false;
    };
    honcho = {
      url = "github:plastic-labs/honcho";
      flake = false;
    };
    oh-my-hermes = {
      url = "github:rlaope/oh-my-hermes";
      flake = false;
    };
    paseo = {
      url = "github:getpaseo/paseo";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
  };
}
