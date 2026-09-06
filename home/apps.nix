{ pkgs, inputs, system, ... }:
{
  imports = [
    ./config/git.nix
    ./config/starship.nix
    ./config/zsh.nix
    ./config/direnv.nix
  ];

  home.packages =
    (with pkgs; [
      yazi
      bubblewrap
      tdf
      chafa
      ghq
      peco
      cowsay
      lolcat
      eza
      fd
      delta
      fastfetch
      tty-clock
      wl-clipboard
      xclip
      graphviz
      mermaid-cli
    ])
    ++ [
      # nixvim (external flake, not in pkgs)
      inputs.nixvim-config.packages.${system}.default
    ];
  # Fonts for Graphviz and Mermaid on minimal Ubuntu installations.
  home.sessionVariables.FONTCONFIG_FILE = pkgs.makeFontsConf {
    fontDirectories = [ pkgs.dejavu_fonts ];
  };
}
