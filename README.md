# agents.nix

Nix modules for running AI agents and the services they use.

Apply the overlays, from this flake and from
[packages.nix](https://github.com/zoldt/packages.nix):

```nix
nixpkgs.overlays = [
  inputs.zoldt-pkgs.modules.overlays.default
  inputs.zoldt-agents.overlays.default
];
```

Then import what you want:

- `modules.homeManager`: `ai` (agent CLIs), `claude`, `pi`, `paseo`, and either `magpie-cli` (headless gateway) or `magpie-desktop`.
- `modules.nixos`: `hermes`, `honcho`, `magpie`, `paseo`.

The NixOS services read credentials from files. Each one has a `zoldt.agents.<service>.credentials` option (or `webKeyFile` for Magpie) that defaults to `/run/secrets/<name>`.
