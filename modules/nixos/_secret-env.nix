# Turn value-only credential files into an env file for systemd and Quadlet at
# service start, without the values entering the Nix store.
{
  lib,
  pkgs,
}: name: vars: {
  file = "/run/${name}.env";
  ExecStartPre = [
    "+${pkgs.writeShellScript "${name}-env" ''
      umask 077
      {
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (var: file: ''printf '%s=%s\n' ${var} "$(<${file})"'') vars)}
      } > /run/${name}.env
    ''}"
  ];
}
