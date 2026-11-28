{inputs, ...}: {
  # Packages from this flake's inputs, as `pkgs.<name>`. The Home Manager modules
  # also need zoldt/packages.nix's overlay (openwiki-cli, magpie-cli, magpie-desktop).
  flake.overlays.default = final: _prev: let
    inherit (final.stdenv.hostPlatform) system;
  in {
    # Prebuilt against llm-agents.nix's own nixpkgs, so they hit the numtide cache.
    llm-agents = inputs.llm-agents.packages.${system};
    autolith = inputs.autolith.packages.${system}.default;
    hermes-agent = inputs.hermes-agent.packages.${system}.default;
  };
}
