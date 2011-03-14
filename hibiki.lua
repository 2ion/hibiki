-- hibiki
-- Music Player Daemon integration for the awesome window manager
-- Version 0.0.0
--
-- Copyright (c) 2011 by Jens Oliver John (2ion) <jens.o.john@gmail.com>
-- Licensed under the GNU General Public License v3.
-- Distributed through http://github.com/2ion/hibiki

local awful = require("awful")
local naughty = require("naughty")
local io = io
local string = string
module("hibiki")

local mpd = {}

function init(atable)
	mpd["server"] = atable["server"] and atable["server"] or "127.0.0.1"
	mpd["port"] = atable["port"] and atable["port"] or 6600
	mpd["curl"] = "curl -fsm1 telnet://" .. mpd["server"] .. ":" .. mpd["port"]
end

function gplaylist()
	return mpd["playlist"]
end

function gcurrentsong()
	return mpd["playlist"][lcurrentsong()]
end

local function lplaylist()
	-- parse playlist
	local pos = 0
	local file = io.popen("echo playlistinfo |" .. mpd["curl"])
	for line in file:lines() do
		for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
			if key=="file" then
				pos=pos+1
				mpd["playlist"][pos] = { pos=pos, file=value }
			elseif key=="Time" then mpd["playlist"][pos]["time"]=tonumber(value)
			elseif key=="Artist" then mpd["playlist"][pos]["artist"]=value
			elseif key=="Title" then mpd["playlist"][pos]["title"]=value
			elseif key=="Album" then mpd["playlist"][pos]["album"]=value
			elseif key=="Track" then mpd["playlist"][pos]["track"]=tonumber(value)
			elseif key=="Date" then mpd["playlist"][pos]["date"]=tonumber(value)
			elseif key=="Composer" then mpd["playlist"][pos]["composer"]=value
			elseif key=="Id" then mpd["playlist"][pos]["composer"]=tonumber(value)
			end
		end
	end
	file:close()
	mpd["playlist"]["last"]=pos
end

local function lcurrentsong()
	local position = nil
	local file = io.popen("echo currentsong |" .. mpd["curl"])
	for line in file:lines() do
		for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
			if key=="Pos" then
				position=tonumber(value)
				break
			end
		end
	end
	file:close()
	return position
end


