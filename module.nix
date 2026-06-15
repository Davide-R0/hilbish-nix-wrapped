{
  config,
  wlib,
  lib,
  pkgs,
  options,
  ...
}:
{
  # NOTE: quando i moduli saranno integrati nella libreria Nix-wrapper-modules: `wlib.wrapperModules.hilbish`
  imports = [ ./wrapperModules/module.nix ];

  options.settings = {
    greeting = lib.mkOption {
      type = lib.types.str;
      default = "Welcome to Nix-wrapped Hilbish!";
      description = "The greeting message on shell startup";
    };
    prompt_char = lib.mkOption {
      type = lib.types.str;
      default = "🚀 >";
      description = "The character to use for the prompt";
    };
    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        ll = "ls -l";
        la = "ls -la";
      };
      description = "Shell aliases";
    };
  };

  config = {
    luaInfo = {
      greeting = config.settings.greeting;
      prompt_char = config.settings.prompt_char;
      aliases = config.settings.aliases;
      lua_dir = "${./lua}";
    };

    "hilbish.lua".path = ./init.lua;
    runtimePkgs = [
      pkgs.eza
      pkgs.bat
    ];
  };
}
