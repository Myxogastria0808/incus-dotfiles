{ username, ... }:
{
  programs.zsh = {
    enable = true;
    # This is a minimal Ubuntu Incus container reached over SSH from Ghostty.
    # It has no `xterm-ghostty` terminfo entry, and even once one is copied in,
    # zsh 5.9's mid-line redraw mishandles its `ich1` capability against Ghostty
    # and duplicates the tail of the line on screen (e.g. typing `clear` shows
    # as `clear areaaar`; keystrokes themselves are fine). `xterm-256color` is
    # always present here and renders correctly — Ghostty exports
    # COLORTERM=truecolor so colours are unaffected; only extensions like
    # coloured underlines / synchronized output are given up.
    envExtra = ''
      [[ $TERM == xterm-ghostty ]] && export TERM=xterm-256color
    '';
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ ];
    };
    shellAliases = {
      ".." = "cd ../";
      "..." = "cd ../../";
      "...." = "cd ../../../";
      ls = "eza";
      ll = "eza -l";
      tree = "eza --tree";
      size = "fd --size";
      diff = "delta --side-by-side";
      neofetch = "fastfetch";
      hm = "home-manager switch --flake path:/home/${username}/incus-dotfiles#incus";
      gc = "nix-collect-garbage --delete-old";
      clock = "tty-clock -c -s";
      g = "lazygit";
      clone = "ghq get";
      pdf = "tdf";
    };
    initContent = ''
      distro_name=$( . /etc/os-release; printf '%s' "$NAME" )
      cowsay "Welcome to $distro_name!!!" | lolcat
      unset distro_name
      ZSH_CUSTOM="$HOME/.config/oh-my-zsh"
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#586e75"
      autoload -Uz edit-command-line
      zle -N edit-command-line
      bindkey '^[e' edit-command-line

      # Prefer a local graphical clipboard; otherwise forward to the terminal via OSC 52.
      __copy_to_clipboard() {
          if [[ -n "$WAYLAND_DISPLAY" ]]; then
              wl-copy
          elif [[ -n "$DISPLAY" ]]; then
              xclip -selection clipboard
          elif [[ -t 1 ]]; then
              local encoded=$(base64 --wrap=0)
              printf '\e]52;c;%s\a' "$encoded"
          else
              print -u2 'Clipboard unavailable: use an OSC 52 capable terminal or a graphical session.'
              return 1
          fi
      }

      # copyfile: copy file contents to clipboard
      copyfile() {
          if [[ -z "''${1:-}" ]]; then
              echo "Usage: copyfile <file>"
              return 1
          fi
          if [[ ! -f "$1" ]]; then
              echo "Error: File not found: $1"
              return 1
          fi
          cat "$1"
          __copy_to_clipboard < "$1"
      }

      # copypath: copy current directory path to clipboard
      copypath() {
          local result=$(pwd)
          echo "''${result}"
          echo "''${result}" | __copy_to_clipboard
      }


      # mmd: compile Mermaid diagram (.mmd) to image
      mmd() {
          local input=""
          local output=""

          __mmd_usage() {
              cat <<EOM
      Usage: mmd <input.mmd> [-o|--output <output>]

      Arguments:
          <input.mmd>        Mermaid diagram file
      Options:
          -o, --output <file>  Output file (.png, .svg, .pdf; default: <input>.png)
          -h, --help           Show this help message
      EOM
          }

          case "''${1:-}" in
          -h|--help)
              __mmd_usage
              return 0
              ;;
          "")
              echo "Error: No input file specified."
              __mmd_usage
              return 1
              ;;
          esac

          input="$1"
          output="''${input%.*}.png"

          case "''${2:-}" in
          -o|--output)
              if [[ -z "''${3:-}" ]]; then
                  echo "Error: No output file specified."
                  __mmd_usage
                  return 1
              fi
              output="$3"
              ;;
          esac

          if [[ "$input" != *.mmd ]]; then
              echo "Error: Input file must be a .mmd file: $input"
              return 1
          fi

          if [[ ! -f "$input" ]]; then
              echo "Error: File not found: $input"
              return 1
          fi

          if [[ "$output" != *.png && "$output" != *.svg && "$output" != *.pdf ]]; then
              echo "Error: Output must be .png, .svg, or .pdf: $output"
              return 1
          fi

          if [[ -f "$output" ]]; then
              echo "$output already exists. Overwrite? (y/N)"
              read -r answer
              if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
                  echo "Overwrite cancelled."
                  return 0
              fi
          fi

          echo "Generating diagram: $output"
          mmdc -i "$input" -o "$output"
      }

      # gv: compile Graphviz diagram (.dot) to image
      gv() {
          local input=""
          local output=""

          __gv_usage() {
              cat <<EOM
      Usage: gv <input.dot> [-o|--output <output>]

      Arguments:
          <input.dot>          Graphviz DOT file
      Options:
          -o, --output <file>  Output file (.png, .svg, .pdf; default: <input>.png)
          -h, --help           Show this help message
      EOM
          }

          case "''${1:-}" in
          -h|--help)
              __gv_usage
              return 0
              ;;
          "")
              echo "Error: No input file specified."
              __gv_usage
              return 1
              ;;
          esac

          input="$1"
          output="''${input%.*}.png"

          case "''${2:-}" in
          -o|--output)
              if [[ -z "''${3:-}" ]]; then
                  echo "Error: No output file specified."
                  __gv_usage
                  return 1
              fi
              output="$3"
              ;;
          esac

          if [[ "$input" != *.dot ]]; then
              echo "Error: Input file must be a .dot file: $input"
              return 1
          fi

          if [[ ! -f "$input" ]]; then
              echo "Error: File not found: $input"
              return 1
          fi

          if [[ "$output" != *.png && "$output" != *.svg && "$output" != *.pdf ]]; then
              echo "Error: Output must be .png, .svg, or .pdf: $output"
              return 1
          fi

          if [[ -f "$output" ]]; then
              echo "$output already exists. Overwrite? (y/N)"
              read -r answer
              if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
                  echo "Overwrite cancelled."
                  return 0
              fi
          fi

          local format="''${output##*.}"
          echo "Generating diagram: $output"
          dot -T"$format" "$input" -o "$output"
      }


      # shell: zsh keyboard shortcuts cheatsheet
      shell() {
          local BOLD="\e[1m"
          local RESET="\e[0m"
          local CYAN="\e[36m"
          local YELLOW="\e[33m"
          local GREEN="\e[32m"
          local MAGENTA="\e[35m"
          local DIM="\e[2m"
          echo ""
          echo -e "''${BOLD}''${CYAN}╔══════════════════════════════════════════════════════╗''${RESET}"
          echo -e "''${BOLD}''${CYAN}║           zsh Keyboard Shortcuts Cheatsheet          ║''${RESET}"
          echo -e "''${BOLD}''${CYAN}╚══════════════════════════════════════════════════════╝''${RESET}"
          # ── Cursor Movement ──────────────────────────────────────────
          echo ""
          echo -e "''${BOLD}''${YELLOW}  Cursor Movement''${RESET}"
          echo -e "''${DIM}  ──────────────────────────────────────────────────────''${RESET}"
          echo ""
          echo -e "  ''${BOLD}Ctrl+A''${RESET}  Move to beginning of line"
          echo -e "  ''${DIM}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${GREEN}    ^''${RESET}"
          echo -e "  ''${GREEN}    Ctrl+A moves here''${RESET}"
          echo ""
          echo -e "  ''${BOLD}Ctrl+E''${RESET}  Move to end of line"
          echo -e "  ''${DIM}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${GREEN}                           ^''${RESET}"
          echo -e "  ''${GREEN}                           Ctrl+E moves here''${RESET}"
          echo ""
          echo -e "  ''${BOLD}Alt+F / Alt+B''${RESET}  Move forward / backward one word"
          echo -e "  ''${DIM}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${GREEN}    ^   ^       ^  ^   ^   ''${RESET}"
          echo -e "  ''${GREEN}    Jump word by word''${RESET}"
          echo ""
          echo -e "  ''${BOLD}Alt+>''${RESET}  Insert history entry at cursor position"
          echo -e "  ''${DIM}  \$ git commit  \"fix bug\"''${RESET}"
          echo -e "  ''${GREEN}               ^''${RESET}"
          echo -e "  ''${GREEN}               Selected history entry is inserted here''${RESET}"
          # ── Text Editing ──────────────────────────────────────────
          echo ""
          echo -e "''${BOLD}''${YELLOW}  Text Editing''${RESET}"
          echo -e "''${DIM}  ──────────────────────────────────────────────────────''${RESET}"
          echo ""
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Ctrl+K" "Delete from cursor to end of line"
          echo -e "  ''${DIM}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${DIM}            ^''${RESET}"
          echo -e "  ''${MAGENTA}            ├──────────────┤ ← deleted''${RESET}"
          echo ""
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Ctrl+U" "Delete entire line"
          echo -e "  ''${DIM}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${MAGENTA}   ├───────────────────────┤ ← all deleted''${RESET}"
          echo ""
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Ctrl+T" "Swap the two characters before cursor"
          echo -e "  ''${DIM}  \$ git commit -m \"fxi bug\"''${RESET}"
          echo -e "  ''${DIM}                    ^^ cursor''${RESET}"
          echo -e "  ''${GREEN}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${GREEN}                    ^^''${RESET}"
          echo ""
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Alt+T" "Swap the two words before cursor"
          echo -e "  ''${DIM}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${DIM}    ^───^ cursor''${RESET}"
          echo -e "  ''${GREEN}  \$ commit git -m \"fix bug\"''${RESET}"
          echo -e "  ''${GREEN}    ^──────^''${RESET}"
          echo ""
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Ctrl+_" "Undo last edit"
          # ── Other ──────────────────────────────────────────────
          echo ""
          echo -e "''${BOLD}''${YELLOW}  Other''${RESET}"
          echo -e "''${DIM}  ──────────────────────────────────────────────────────''${RESET}"
          echo ""
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Ctrl+L" "Clear screen (history preserved)"
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Alt+E" "Edit current input in editor"
          echo ""
      }

      # Ctrl+G: choose a ghq repository; quote paths before accepting the command.
      peco-src() {
          local selected_dir
          selected_dir=$(ghq list -p | peco --prompt="repositories >" --query "$LBUFFER")
          if [[ -n "$selected_dir" ]]; then
              BUFFER="cd -- ''${(q)selected_dir}"
              zle accept-line
          fi
          zle clear-screen
      }
      zle -N peco-src
      bindkey '^g' peco-src
    '';
  };
}
