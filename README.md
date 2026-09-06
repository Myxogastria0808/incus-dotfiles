# linux-dotfiles

Standalone [Home Manager](https://github.com/nix-community/home-manager)
configuration for an **Incus Linux container** — a minimal Ubuntu
container with no desktop and no system-level Nix (Home Manager runs
entirely in user space). It sets up `zsh` + `oh-my-zsh`, `starship`,
`git`/`gh`/`lazygit`, `direnv`, and a set of CLI tools (`eza`, `fd`, `yazi`,
`delta`, `ghq`, `peco`, Graphviz/Mermaid helpers, and a Neovim build from
[`Myxogastria0808/nix-flakes-nixvim`](https://github.com/Myxogastria0808/nix-flakes-nixvim)).

Some choices are container-specific: `zsh.nix` rewrites `TERM=xterm-ghostty`
to `xterm-256color` (the container has no such terminfo entry), clipboard
helpers fall back to OSC 52 since there is no Wayland/X11 display, and a
`FONTCONFIG_FILE` is pinned so Graphviz/Mermaid have fonts on a bare Ubuntu
image.

Everything is driven by the flake output `homeConfigurations.linux`
(user `hello`, system `x86_64-linux`).

## Requirements

- An `x86_64-linux` Incus container
- A non-root user named `hello` with home directory `/home/hello` (this is
  hard-coded in `flake.nix`; see the note in step 2 to use a different name)
- Nix installed **inside the container** via the
  [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer)
  (flakes and `nix-command` are enabled by default) — see step 1
- `git` and `curl`
- A terminal using a **Nerd Font** so the `starship` prompt glyphs render

## Setup

### 1. Install Nix (inside the container)

Recommended (flakes enabled by default):

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

c.f. https://github.com/DeterminateSystems/nix-installer

### 2. Clone this repo

The `hm` alias and Home Manager expect the repo at `~/linux-dotfiles`:

```sh
git clone https://github.com/Myxogastria0808/linux-dotfiles.git ~/linux-dotfiles
cd ~/linux-dotfiles
```

> If your Linux username is not `hello`, edit `username` in `flake.nix` (and
> therefore the `homeDirectory` derived from it in `home/home.nix`) before
> continuing.

### 3. First activation

Home Manager is not installed yet, so run it straight from the flake:

```sh
nix run home-manager/master -- switch --flake ~/linux-dotfiles#linux
```

This builds the profile, installs `home-manager` itself, and links all the
config into `~`. Unfree packages are allowed via `config.allowUnfree = true`
in the flake.

### 4. Switch to zsh

Home Manager installs `zsh` and writes `~/.zshrc`, but it does not change your
login shell (the Ubuntu image defaults to bash). The container keeps bash as the
login shell and hands off to zsh from `~/.bashrc`. Append this block to
`~/.bashrc`:

```sh
# >>> home-manager zsh >>>
# Drop into the home-manager-managed zsh for interactive sessions.
# Guarded so non-interactive shells and `bash` invoked explicitly are unaffected,
# and so login still works if the Nix profile is ever removed.
if [[ $- == *i* && -z "$ZSH_VERSION" && -x "$HOME/.nix-profile/bin/zsh" ]]; then
  exec "$HOME/.nix-profile/bin/zsh" -l
fi
# <<< home-manager zsh <<<
```

Open a new interactive shell afterwards.

### 5. Authenticate GitHub CLI

`gh` is installed and wired up as git's credential helper for `github.com`
(`git.nix`), but the flake cannot log you in — this is a one-time manual step:

```sh
gh auth login
```

Pick **HTTPS** as the git protocol when prompted. After this,
`git clone`/`push` over HTTPS and the `clone` alias (`ghq get`) work without
extra prompts.

## Daily use

Apply changes after editing any `*.nix` file:

```sh
hm          # alias for: home-manager switch --flake path:/home/hello/linux-dotfiles#linux
```

Update inputs (nixpkgs, home-manager, nixvim) and re-apply:

```sh
nix flake update
hm
```

Reclaim disk space from old generations:

```sh
gc          # alias for: nix-collect-garbage --delete-old
```

## Layout

```
.
├── flake.nix              # inputs + homeConfigurations.linux
├── flake.lock
└── home/
    ├── home.nix           # home.* basics, imports apps.nix
    ├── apps.nix           # package list, imports home/config/*
    └── config/
        ├── zsh.nix        # zsh, oh-my-zsh, aliases, shell functions/widgets
        ├── starship.nix   # starship configuration
        ├── git.nix        # git, gh, lazygit
        └── direnv.nix     # direnv + zsh integration
```

## Handy aliases / functions

| Command           | Does                                     |
| ----------------- | ---------------------------------------- |
| `hm`              | Rebuild and switch this configuration    |
| `gc`              | Delete old generations                   |
| `g`               | `lazygit`                                |
| `clone <repo>`    | `ghq get` into `~/src`                   |
| `Ctrl-G`          | Fuzzy-jump to a `ghq` repo via `peco`    |
| `copyfile <file>` | Copy file contents to the clipboard      |
| `copypath`        | Copy `$PWD` to the clipboard             |
| `mmd <in.mmd>`    | Render a Mermaid diagram to an image     |
| `gv <in.dot>`     | Render a Graphviz diagram to an image    |
| `shell`           | Print a zsh keyboard-shortcut cheatsheet |

