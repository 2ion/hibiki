--[[
	hibiki
	Music Player Daemon integration with the awesome window manager
	Version 1.0

    Copyright (C) 2011 Jens Oliver John (2ion) <jens.o.john@gmail.com>.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

	The sourcecode is obtainable through https://github.com/2ion/hibiki.
--]]

--{{{ module environment
local io = io
local coroutine = coroutine
local string = string
local table = table
local setfenv = setfenv
local type = type
local print = print
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local timer = timer
--local awful = require("awful")
--local naughty = require("naughty")
module("hibiki")
--}}}

local DAEMONS = {}

local function table_setfenv(table,envt)
	for key,value in pairs(table) do
		if type(value)=="function" then
			setfenv(value, envt)
		elseif type(value)=="table" then
			table_setfenv(value, envt)
		end
	end
end

local function register_daemon(daemon_table)
	local mpd = {}
	mpd.host = daemon_table.host and daemon_table.host or "127.0.0.1"
	mpd.port = daemon_table.port and daemon_table.port or "6600"
	mpd.password = daemon_table.password and daemon_table.password or nil
	mpd.telnet = mpd.password and
		"|netcat " .. mpd.host .. " " .. mpd.port or
		"|netcat " .. mpd.host .. " " .. mpd.port	
	mpd.read_reply =
		function (command)
			local stream = io.popen("echo " .. command .. telnet)
			return stream
		end
	mpd.toggle = 
		function (command, boolean)
			local stream = read_reply(command .. (boolean and "1" or "0"))
			stream:close()
		end

	mpd.playlist = {}
	mpd.playlist.read = 
		function ()
			playlist.items = {}
			local lied = nil
			local position = 0
			local stream = read_reply("playlistinfo")
			for line in stream:lines() do
				for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
					if key == "file" then
						if lied then table.insert(playlist.items, lied) end
						lied = {}
					else
						lied[key] = value
					end
				end
			end
			stream:close()
		end
	
	mpd.playback = {}
	mpd.playback.control = 
		function (command, position)
			local stream
			if position then
				stream = read_reply(command .. " " .. position)
			else
				stream = read_reply(command)
			end
			stream:close()
		end
	mpd.playback.Consume = 
		function (boolean)
			toggle("consume", boolean)
		end
	mpd.playback.Random = 
		function (boolean)
			toggle("random", boolean)
		end
	mpd.playback.Repeat = 
		function (boolean)
			toggle("repeat", boolean)
		end
	mpd.playback.Play =
		function (position)
			playback.control("play", position)
		end
	mpd.playback.Next = 
		function ()
			playback.control("next")
		end
	mpd.playback.Previous = 
		function ()
			playback.control("previous")
		end
	mpd.playback.Pause = 
		function ()
			playback.control("pause")
		end
	mpd.playback.Stop = 
		function ()
			playback.control("stop")
		end
	
	
	table_setfenv(mpd,mpd)
	table.insert(DAEMONS, mpd)
end

register_daemon({})
local stream = DAEMONS[1].read_reply("playlist")
for line in stream:lines() do
	print(line)
end
DAEMONS[1].playback.Next()
DAEMONS[1].playlist.read()
for key,value in ipairs(DAEMONS[1].playlist.items) do
	print(value.Title)
end
	


