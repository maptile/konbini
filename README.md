# Konbini

`konbini` is a directory-convention-based command dispatcher. Place your shell or JavaScript scripts in a designated directory following a simple naming convention, then invoke them all through a single unified entry point.

The goal is not to replace a full CLI framework, but to organize scattered scripts into a stable, unified, and discoverable command-line toolbox.

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
- Reads your own commands from `custom-commands/commands/`
- Supports both `.sh` and `.js` command files
- Supports subcommand groups via `<command>-commands/` directories
- Lists all available commands with `-h` / `help`
- Checks for duplicate commands and structural issues with `konbini doctor`
- Extracts command descriptions from `DESCRIPTION` comments in command files

## Directory structure

This repository contains a few built-in examples. You can follow the same structure to add your own commands.

- `commands/` — built-in command files provided by this project
- `lib/` — shared library functions available to all commands
- `commands/copy/` — txt files used by the `copy` command

The custom commands directory (specified via `--custom-commands-dir`) must follow this structure:

```
my-custom-commands/
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

## Using a custom commands directory

`konbini` accepts a `--custom-commands-dir` flag to specify where your personal commands live.

Example:

```bash
./konbini --custom-commands-dir ~/projects/my-custom-commands -h
```

## Using konbini in Bash

Passing `--custom-commands-dir` every time is tedious. Here are a few ways to wrap it.

### Wrapper script (recommended)

Create an executable script at `~/bin/konbini` (or any directory on your `PATH`):

```bash
#!/usr/bin/env bash
exec "$HOME/projects/konbini/konbini" --custom-commands-dir "$HOME/projects/my-custom-commands" "$@"
```

```bash
chmod +x ~/bin/konbini
```

This is the most compatible approach — it works in interactive terminals, shell scripts, and **cron jobs** (as long as `~/bin` is on `PATH`, or you use the full path). Tab completion also works through the wrapper automatically.

### Shell function (interactive terminals only)

Add to `.bashrc`:

```bash
konbini() {
  "$HOME/projects/konbini/konbini" --custom-commands-dir "$HOME/projects/my-custom-commands" "$@"
}
```

Only works in shells that have sourced `.bashrc`. Cron jobs and scripts with `#!/usr/bin/env bash` do not source `.bashrc` by default.

### Alias (not recommended)

```bash
alias konbini='~/projects/konbini/konbini --custom-commands-dir ~/projects/my-custom-commands'
```

Same limitation as shell functions, and bash does not trigger custom tab completion for aliases by default.

## Tab completion

`konbini` ships a `completion` command that outputs a shell completion script, enabling tab completion for command and subcommand names.

**Bash** — add to `.bashrc`:

```bash
eval "$(konbini completion bash)"
```

**Zsh** — add to `.zshrc`:

```zsh
eval "$(konbini completion zsh)"
```

Restart your terminal or run `source ~/.bashrc` / `source ~/.zshrc` to apply. Then:

```bash
konbini <Tab>          # complete all available commands
konbini git <Tab>      # complete subcommands under the git group
```

### With a wrapper script

The completion script invokes the command via `${COMP_WORDS[0]}` (the actual entry point you typed), so as long as you use a wrapper script (recommended), completion will automatically go through the wrapper and correctly include commands from your custom directory — no extra configuration needed.

Note: bash does not trigger custom completion functions for aliases. Use a wrapper script or shell function instead.

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
