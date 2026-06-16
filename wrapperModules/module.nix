{
  config,
  wlib,
  lib,
  pkgs,
  ...
}:
{
  imports = [ wlib.modules.default ];

  options = {
    luaInfo = lib.mkOption {
      type = wlib.types.structuredValueWith {
        typeName = "lua";
        extraValueTypes = lib.types.luaInline;
      };
      default = { };
      description = ''
        Defines attributes which are converted to Lua.
        The converted values are made available to the Hilbish config as the result of calling `require('nix-info')`.
        The conversion to Lua uses `lib.generators.toLua` which accepts anything other than uncalled nix functions.
      '';
    };

    "hilbish.lua" = lib.mkOption {
      type = wlib.types.file {
        path = lib.mkOptionDefault config.constructFiles.generatedConfig.path;
        content = lib.mkOptionDefault "return require('nix-info')";
      };
      default = { };
      description = ''
        The hilbish config file (init.lua).
      '';
    };
  };

  config = {
    package = lib.mkDefault pkgs.hilbish;

    # Injecting the nix-info setup into the beginning of the hilbish config
    constructFiles.generatedConfig = {
      relPath = "${config.binName}-init.lua";
      content = ''
        package.preload["nix-info"] = function()
          return setmetatable(${lib.generators.toLua { } config.settings}, {
            __call = function(self, default, ...)
              if select('#', ...) == 0 then return default end
              local tbl = self;
              for _, key in ipairs({...}) do
                if type(tbl) ~= "table" then return default end
                tbl = tbl[key]
              end
              return tbl
            end
          })
        end

        -- Load the actual user config
        local user_config = dofile(${builtins.toJSON config."hilbish.lua".path})
        return user_config
      '';
    };

    # Hilbish doesn't have a direct flag for config file, but uses XDG_CONFIG_HOME
    # However, it expects the config in hilbish/init.lua inside that path.
    # A cleaner way to override config is via the --config flag if available (it has -c/--config)
    flags."--config" = config.constructFiles.generatedConfig.path;

    meta.maintainers = [ ]; # Add your maintainer name if desired
  };
}
