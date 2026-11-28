# agents.nix

Nix modules for running AI agents and the services they use.

Apply the overlays, from this flake and from
[packages.nix](https://github.com/zoldt/packages.nix):

```nix
nixpkgs.overlays = [
  inputs.zoldt-pkgs.overlays.default
  inputs.zoldt-agents.overlays.default
];
```

Then import what you want:

- `modules.homeManager`: `ai` (agent CLIs), `claude`, `pi`, `paseo`, and either `magpie-cli` (headless gateway) or `magpie-desktop`.
- `modules.nixos`: `hermes`, `honcho`, `magpie`, `paseo`.

The NixOS services read their credentials from files at runtime. Each one takes
`zoldt.agents.<service>.credentials.<name>`, the path to that file, with no
default:

```nix
zoldt.agents.magpie.credentials.magpie-web-key = config.sops.secrets.magpie-web-key.path;
```
