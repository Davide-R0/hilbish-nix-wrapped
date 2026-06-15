# Hilbish Module Template

This is a demonstration of how to configure the
[Hilbish shell](https://github.com/Rosettea/Hilbish) using
`nix-wrapper-modules`.

It showcases the powerful feature of injecting Nix options directly into a
standalone Lua configuration, specifically tailored for the Hilbish environment.

## File Structure

- `flake.nix`: The entry point that defines inputs and outputs.
- `module.nix`: The Nix module where you define custom options (like
  `myConfig.greeting`), pass them to `luaInfo`, and specify the path to your Lua
  entrypoint.
- `lua/init.lua`: Your pure Lua Hilbish configuration. It pulls in the Nix
  values dynamically using `require('nix-info')`.

## Usage

To initialize this template flake into an empty directory, run:

```bash
nix flake init -t github:BirdeeHub/nix-wrapper-modules#hilbish
```

To build and run it from this directory:

```bash
nix build .
./result/bin/hilbish
```
