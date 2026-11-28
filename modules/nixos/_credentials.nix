# The `credentials` option every service here takes: one path per credential
# file, read at runtime so the value never enters the Nix store. There is no
# default; the host says where each file comes from.
lib: names:
lib.mkOption {
  description = "Paths to the service's credential files.";
  type = lib.types.submodule {
    options = lib.genAttrs names (name:
      lib.mkOption {
        type = lib.types.str;
        description = "Path to the ${name} credential file.";
      });
  };
}
