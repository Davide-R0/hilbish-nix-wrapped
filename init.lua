-- Hilbish init.lua

-- Carichiamo il modulo generato automaticamente dal wrapper per i valori Nix
local nixInfo = require('nix-info')

-- Aggiungiamo la nostra directory ./lua al package.path in modo da poter usare require
local lua_dir = nixInfo(nil, "lua_dir")
if lua_dir then
  package.path = package.path .. ";" .. lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua"
end

-- Hilbish usa l'oggetto globale `hilbish` per le API
local hilbish = require 'hilbish'
local commander = require 'commander'
local lunacolors = require 'lunacolors'

-- Estraiamo i nostri valori da Nix
local greeting = nixInfo("Welcome to Hilbish!", "greeting")
local prompt_char = nixInfo(">", "prompt_char")
local custom_aliases = nixInfo({}, "aliases")

-- Configuriamo il messaggio di benvenuto
hilbish.greeting = lunacolors.green(greeting)

-- Configuriamo il prompt interattivo
hilbish.prompt(lunacolors.blue("%u") .. " at " .. lunacolors.cyan("%d") .. "\n" .. lunacolors.magenta(prompt_char) .. " ")

-- Registriamo gli aliases presi da Nix
for alias_name, command in pairs(custom_aliases) do
    hilbish.alias(alias_name, command)
end

-- Aggiungiamo un comando personalizzato puramente in Lua
commander.register("hello", function(args)
    print("Hello from Hilbish custom command!")
end)
