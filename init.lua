local nixInfo = require('nix-info')

local lua_dir = nixInfo(nil, "lua_dir")
if lua_dir then
    package.path = package.path .. ";" .. lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua"
end

local hilbish = require('hilbish')
local commander = require('commander')
local lunacolors = require('lunacolors')
local bait = require('bait')

require('options').apply(hilbish)
require('prompt_style').apply(hilbish, lunacolors, bait)
require('aliases').apply(hilbish)
require('highlighting').apply(hilbish, lunacolors)
require('integrations').apply(commander)
require('commands').apply(commander)
require('externals').apply()
