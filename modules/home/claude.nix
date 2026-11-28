{
  flake.modules.homeManager.claude =
    # Claude Code, from llm-agents.nix (prebuilt binary; numtide cache) via this flake's overlay.
    #
    # mutableSettings keeps ~/.claude/settings.json a writable file: anything
    # declared in `settings` (none yet) is merged into it at activation, while
    # values written by the CLI's /config or other tools are preserved. Declared
    # values win on collisions.
    #
    # configDir is pinned to the upstream ~/.claude: this tree enables
    # home.preferXdgDirectories with stateVersion 26.11, whose default would move
    # the directory to ~/.config/claude and orphan the credentials, sessions and
    # settings already under ~/.claude. Drop the pin when that data moves.
    {
      config,
      pkgs,
      ...
    }: {
      programs.claude-code = {
        enable = true;
        package = pkgs.llm-agents.claude-code;
        mutableSettings = true;
        configDir = "${config.home.homeDirectory}/.claude";
      };
    };
}
