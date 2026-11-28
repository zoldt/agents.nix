{
  flake.modules.homeManager.ai =
    # Shared agent tools.
    {pkgs, ...}: {
      home.packages =
        [
          # openwiki CLI; its pi extension is installed by pi ("npm:openwiki" in config/pi/agent/settings.json).
          pkgs.openwiki-cli
          pkgs.rtk
          pkgs.agent-browser
        ]
        ++ (with pkgs.llm-agents; [
          codegraph
          qmd # local document search
          beads # bd CLI for projects that use it
          plannotator # plan and code review for agents
          ralph-tui # agent loop orchestrator
        ]);
    };
}
