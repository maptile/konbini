# Konbini

`konbini` is a directory-convention-based command dispatcher. Place your shell or JavaScript scripts in a designated directory following a simple naming convention, then invoke them all through a single unified entry point.

The goal is not to replace a full CLI framework, but to organize scattered scripts into a stable, unified, and discoverable command-line toolbox.

## Installation

Clone the repository to wherever you want to keep it:

```bash
git clone https://github.com/maptile/konbini.git ~/.konbini
```

Create a wrapper script on your `PATH` so you can call `konbini` from anywhere and bake in your custom commands directory:

```bash
mkdir -p ~/.local/bin
cat > ~/.local/bin/konbini << 'EOF'
#!/usr/bin/env bash
exec "$HOME/.konbini/konbini" --custom-commands-dir "$HOME/projects/custom-commands" "$@"
EOF
chmod +x ~/.local/bin/konbini
```

`~/.local/bin` is automatically added to `PATH` by Ubuntu's default `~/.profile` when the directory exists. If it's not on your `PATH` yet, restart your shell or run `source ~/.profile`.

This assumes your custom commands live at `~/projects/custom-commands` — adjust the path if yours is elsewhere. The directory does not need to exist yet.

The wrapper script is the recommended approach — it works in interactive terminals, shell scripts, and cron jobs, and tab completion works through it automatically.

<details>
<summary>Alternative: shell function or alias</summary>

**Shell function** (interactive terminals only) — add to `.bashrc`:

```bash
konbini() {
  "$HOME/.konbini/konbini" --custom-commands-dir "$HOME/projects/custom-commands" "$@"
}
```

**Alias** (not recommended) — bash does not trigger custom tab completion for aliases:

```bash
alias konbini='~/.konbini/konbini --custom-commands-dir ~/projects/custom-commands'
```

Both only work in shells that have sourced `.bashrc`. Cron jobs and non-interactive scripts do not source `.bashrc` by default.

</details>

Optionally enable tab completion. Add one of the following to your shell rc file:

```bash
# ~/.bashrc
eval "$(konbini completion bash)"
```

```zsh
# ~/.zshrc
eval "$(konbini completion zsh)"
```

Then reload your shell:

```bash
source ~/.bashrc   # or source ~/.zshrc
```

## Minimal example

Place a file `hello.sh` in the `commands/` directory:

```bash
#!/usr/bin/env bash
# DESCRIPTION: print hello

echo "hello"
```

Make it executable:

```bash
chmod +x commands/hello.sh
```

Then run it:

```bash
./konbini hello
```

Output:

```text
hello
```

That's the core usage: drop scripts into a directory, run them through a single entry point.

## What it does

- Reads built-in commands from `commands/`
- Reads your own commands from a custom commands directory you specify
- Supports both `.sh` and `.js` command files
- Supports subcommand groups via `<command>-commands/` directories
- Lists all available commands with `-h` / `help`
- Checks for duplicate commands and structural issues with `konbini doctor`
- Extracts command descriptions from `DESCRIPTION` comments in command files

## Dependencies

> Currently developed and tested on **Ubuntu / Debian** only.

### Core framework

`konbini` itself requires only:

| Requirement | Notes |
|---|---|
| `bash` 4.0+ | Ubuntu 20.04+ ships with bash 5 — no action needed |
| `node` / Node.js | Required only if you use `.js` command files |

### Built-in commands

Each built-in command has its own external dependencies. Install only what you use.

| Command | Tool required |
|---|---|
| `claude` | `docker` + custom image `claudecode` |
| `codex` | `docker` + custom image `codex` |
| `node` | `docker` + `node:24` image |
| `dcd` `dce` `dci` `dcl` `dcp` `dcr` `dcu` | `docker compose` (bundled with Docker Engine) |
| `copy` | `xclip` |
| `convertheic` | `heif-convert` (from `libheif-examples`) |
| `down` | `aria2c` |
| `pwgen` | `pwgen`, `shuf` (`shuf` is part of `coreutils`) |
| `savekey` | `secret-tool` (from `libsecret-tools`) |
| `install-calibre` | `tar`, `sudo` (pre-installed) |
| `git pullrecursive` / `statusrecursive` | `git` |
| `verse` | `node`, internet access; falls back to `diatheke` (optional) |

### Optional library utilities (`lib/common.sh`)

These degrade gracefully when absent — missing tools are silently skipped.

| Tool | Function |
|---|---|
| `toilet` or `figlet` | `echoLargeText()` — large terminal text |
| `notify-send` | `send_notification()` — desktop notifications |
| `kitten` | Tab title/color control in [Kitty](https://sw.kovidgoyal.net/kitty/) terminal |

## Installing system dependencies

> **Ubuntu / Debian only.** See [macOS notes](#macos-notes) if you are on macOS.

Install all apt-managed dependencies in one shot:

```bash
sudo apt install nodejs git xclip aria2 pwgen libsecret-tools libheif-examples
```

Optionally, for large text output and desktop notifications in `lib/common.sh`:

```bash
sudo apt install toilet libnotify-bin
```

### Docker

Docker Engine is installed separately. Follow the official guide for your distro:
[https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)

The `claude`, `codex`, and `node` commands also require their respective Docker images to be built or pulled before use.

## macOS notes

`konbini` works on macOS with a few adjustments.

### Critical: upgrade bash

macOS ships with bash 3.2 (due to licensing). `konbini` uses associative arrays (`declare -A`) which require bash 4+. Install a modern bash and use it as the interpreter:

```bash
brew install bash
```

Then make sure your wrapper script uses the Homebrew bash explicitly:

```bash
#!/opt/homebrew/bin/bash   # Apple Silicon
# or
#!/usr/local/bin/bash      # Intel Mac
exec "$HOME/.konbini/konbini" --custom-commands-dir "$HOME/projects/custom-commands" "$@"
```

Or update `konbini`'s shebang line from `#!/usr/bin/env bash` to point at the Homebrew bash.

### PATH setup

Unlike Ubuntu, macOS does not automatically add `~/.local/bin` to `PATH`. Add it manually in `~/.zshrc` (or `~/.bash_profile`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Built-in commands that need adaptation on macOS

| Command | Issue | Fix |
|---|---|---|
| `copy` | Uses `xclip`, not available on macOS | Replace `xclip -selection clipboard -i` with `pbcopy <` in a custom override |
| `savekey` | Uses `secret-tool` (GNOME Keyring), not available on macOS | Replace with `security add-generic-password` / `security find-generic-password` in a custom override |
| `pwgen` | Uses `shuf` (GNU coreutils), not available by default | `brew install coreutils` (provides `gshuf`), then adjust the script |

### Tools available via Homebrew

Most other dependencies install cleanly:

```bash
brew install aria2 pwgen figlet libheif node git
brew install --cask docker
```

`notify-send` has no direct macOS equivalent, but `send_notification()` in `lib/common.sh` silently skips if `notify-send` is not found — no action needed.

## Directory structure

This repository contains a few built-in examples. You can follow the same structure to add your own commands.

- `commands/` — built-in command files provided by this project
- `lib/` — shared library functions available to all commands
- `commands/copy/` — txt files used by the `copy` command

The custom commands directory (specified via `--custom-commands-dir`) must follow this structure:

```
custom-commands/
  commands/        ← your command files go here (.sh or .js)
    mycommand.sh
    git-commands/  ← subcommand groups go here too
      mysubcmd.sh
    copy/          ← txt files for the copy command
      mysnippet.txt
  lib/             ← your personal library functions (optional)
    common.sh
```

## How command lookup works

When executing a command, `konbini` does not pre-register all files into a complete command table. Instead, it searches for candidate files on demand based on what you typed.

### Top-level commands

For example, when you run:

```bash
konbini claude
```

`konbini` searches for candidate files in both `commands/` and `custom-commands/commands/`:

- `claude.sh`
- `claude.js`
- `claude.*.sh`
- `claude.*.js`

This means:

- `claude.sh` provides the command `claude`
- `claude.code.sh` also provides the command `claude`
- `claude.danger.js` also provides the command `claude`

The rule is: strip the file extension, then take everything before the first `.` as the logical command name.

If multiple candidates are found — for example both of these exist:

- `commands/claude.sh`
- `custom-commands/commands/claude.sh`

or:

- `commands/claude.sh`
- `commands/claude.code.sh`

If the matches all come from the same directory tree (e.g. both in `commands/`, or both in `custom-commands/commands/`), `konbini` will report an error about duplicate commands.

If the same command name appears in both `commands/` and `custom-commands/commands/`, that is allowed — the one in `custom-commands/commands/` takes priority.

### Subcommand groups

Subcommand directories follow the `<command>-commands/` naming convention. For example:

- `commands/git-commands/pullrecursive.sh`
- `commands/git-commands/statusrecursive.sh`

These are invoked as:

```bash
konbini git pullrecursive
konbini git statusrecursive
```

For subcommands, `konbini` looks in:

- `<dir>/<command>-commands/<subcommand>.sh`
- `<dir>/<command>-commands/<subcommand>.js`
- `<dir>/<command>-commands/<subcommand>.*.sh`
- `<dir>/<command>-commands/<subcommand>.*.js`

If multiple candidates are found in the same directory tree, a duplicate error is reported.

If the same subcommand appears in both `commands/` and `custom-commands/commands/`, the one in `custom-commands/commands/` takes priority.

### Top-level commands vs. subcommand groups

When you run:

```bash
konbini code claude
```

`konbini` resolves it as follows:

- First, look for a top-level command named `code`
- If found, execute it and pass `claude` as an argument
- Only if no top-level command exists does it look for `code-commands/claude.sh`

In other words, top-level commands take priority over subcommand groups.

To check whether any top-level command is shadowing a same-named subcommand group, run:

```bash
konbini doctor
```

### Hidden files

Files and directories whose names start with `_` or `.` are ignored by `konbini`.

## Tab completion

After setting up the wrapper and adding the `eval` line to your rc file, tab completion works like this:

```bash
konbini <Tab>          # complete all available commands
konbini git <Tab>      # complete subcommands under the git group
```

The completion script invokes the command via `${COMP_WORDS[0]}` (whatever you typed at the prompt), so it automatically goes through your wrapper and includes commands from your custom directory — no extra configuration needed.

## doctor

`konbini doctor` scans the current command tree and checks for:

- Duplicate top-level commands
- Duplicate subcommands
- Top-level commands shadowing a same-named subcommand group

If everything is clean:

```text
Konbini doctor

OK: no duplicate commands, no duplicate subcommands, no shadowed command groups.
```

## Command descriptions

Each command can have a description shown in `konbini -h`.

For `.sh` files, add a comment line starting with `# DESCRIPTION:`:

```bash
#!/usr/bin/env bash
# DESCRIPTION: An AI coding tool
```

For `.js` files, use `// DESCRIPTION:`:

```js
// DESCRIPTION: An AI coding tool
```

The description appears in the help output:

```text
  ...
  claude         An AI coding tool [built-in]
  ...
```

## Using library functions

`lib/common.sh` provides utility functions — for example, printing large text with figlet, changing tab titles in kitty, or renaming buffers in Emacs eat/vterm.

Load it in a command file with:

```bash
import common
```

`import` is automatically injected into every command by konbini. It loads modules in order:

1. `lib/common.sh` (built-in)
2. `custom-commands/lib/common.sh` (if it exists)

Functions defined in the custom lib override same-named functions from the built-in lib.

You can have multiple library files — each file is one module:

```bash
import common   # loads lib/common.sh, then custom-commands/lib/common.sh
import utils    # loads lib/utils.sh, then custom-commands/lib/utils.sh
```

## Copying txt file contents to clipboard

The built-in `copy` command reads a txt file and copies its contents to the clipboard — useful for snippets you paste frequently.

`konbini copy s1` looks for `s1.txt` in this order:

1. `custom-commands/commands/copy/s1.txt` (takes priority)
2. `commands/copy/s1.txt` (built-in fallback)
