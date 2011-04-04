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
	TODO: -escape naughty notifications
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
local awful = require("awful")
local naughty = require("naughty")
module("hibiki")
--}}}

local DAEMONS = {}
local TIMER = nil
local WORKERS = {}

local function table_setfenv(table,envt)
	for key,value in pairs(table) do
		if type(value)=="function" then
			setfenv(value, envt)
		elseif type(value)=="table" then
			table_setfenv(value, envt)
		end
	end
end

local function table_clone(table)
	local t = {}
	for key,value in pairs(table) do
		t[key] = value
	end
	return t
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
			local stream = read_reply(command .. (boolean and " 1" or " 0"))
			stream:close()
		end
	mpd.set = 
		function (option, value)
			local stream = read_reply(command .. " " .. value)
			stream:close()
		end
	
	mpd.notify = {}
	mpd.notify.conf = daemon_table.noteconf and daemon_table.noteconf or
		{
			title = "mpd@" .. mpd.host .. ":" .. mpd.port,
			timeout = 3
		}
	mpd.notify.playlist = 
		function ()
			local text = ""
			local first = true
			for key,lied in ipairs(playlist.items) do
				if first then
					text = lied.Pos .. "\t" .. lied.Artist .. " ~ " .. lied.Title
					first = false
				else
					text = text .. "\n" .. lied.Pos .. "\t" .. lied.Artist .. " ~ " ..
						lied.Title
				end
			end
			local noteconf = notify.conf
			noteconf.text = text
			noteconf.timeout = 5
			naughty.notify(noteconf)
		end
	mpd.notify.state = 
		function ()
			local lied = mpd.playlist.items[tonumber(mpd.status.new.song)+1]
			local text = lied.Pos .. "  <span font_desc=\"DejaVu Sans 13\">"..lied.Title.."</span>".."<span font_desc=\"DejaVu Sans 11\"><br>" .. 
				lied.Album.." ("..lied.Date..")\n"..lied.Artist .. "</span>"
			local title = ""
			if mpd.status.new.state == "play" then
				title = "Playing"
			elseif mpd.status.new.state == "stop" then
				title = "Stopped at"
			elseif mpd.status.new.state == "pause" then
				title = "Paused at"
			end
			local noteconf = notify.conf
			noteconf.text = text
			noteconf.title = title
			naughty.notify(noteconf)
		end
	
	mpd.ui = {}
	mpd.ui.playlistmenu = 
		function ()
			local menu_items = {}
			for key,lied in pairs(playlist.items) do
				table.insert(menu_items, {
					lied.Pos .. "\t" .. lied.Artist .. " ~ " .. lied.Title,
					function ()
						playback.Play(lied.Pos)
					end,
					nil, -- submenu table or function
					nil -- icon
				})
			end
			local awe_menu = awful.menu.new({
				items = menu_items,
				width = 350,
				height = 20
			})
			awful.menu.show(awe_menu, { keygrabber = true })
		end

	mpd.status = {}
	mpd.status.diff = 
		function ()
			if status.new then
				status.old = table_clone(status.new)
			else
				status.old = {}
			end
			status.new = {}
			local stream = read_reply("status")
			status.noneq = {}

			for line in stream:lines() do
				for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
					status.new[key] = value
					if status.new[key]~=status.old[key] then
						table.insert(status.noneq, key)
						if 	key == "volume" then break
						elseif 	key == "repeat" then break
						elseif	key == "random" then break
						elseif	key == "single" then break
						elseif	key == "consume" then break
						elseif	key == "playlist" then
							playlist.read()
							notify.playlist()
						elseif	key == "playlistlength" then break
						elseif	key == "xfade" then break
						elseif	key == "mixrampdb" then break
						elseif	key == "mixrampdelay" then break
						elseif	key == "state" then
							notify.state()
						elseif	key == "song" then
							notify.state()
						elseif	key == "songid" then break
						elseif	key == "time" then break
						elseif	key == "elapsed" then break
						elseif	key == "bitrate" then break
						elseif	key == "audio" then break
						elseif	key == "nextsong" then break
						elseif	key == "nextsongid" then break
						end
					end
				end
			end
			stream:close()
		end

	mpd.playlist = {}
	mpd.playlist.read = 
		function ()
			playlist.items = {}
			local index = 0
			local stream = read_reply("playlistinfo")
			for line in stream:lines() do
				--[[
				for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
					if key == "file" then
						if lied then table.insert(playlist.items, lied) end
						lied = {}
						lied[key] = value
					elseif lied then
						lied[key] = value
					end
				end
				--]]
				for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
					if key == "file" then
						index = index + 1
						playlist.items[index] = { file = value }
					else
						playlist.items[index][key] = value
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
	mpd.playback.Volume = 
		function (percent)
			set("setvol", percend and percent or 0)
		end
	mpd.playback.Crossfade = 
		function (seconds)
			set("crossfade", seconds and seconds or 0)
		end
	mpd.playback.ReplayGain = 
		function (mode)
			set("replay_gain_mode", mode and mode or "off")
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
	mpd.playback.Single = 
		function (boolean)
			toggle("single", boolean)
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


function exec()
	TIMER:start()
	TIMER:emit_signal("timeout")
end

function unexec()
	TIMER:stop()
end

function serial()
	for key,daemon in ipairs(DAEMONS) do
		daemon.status.diff()
	end
end

function init(mpds, timeout)
	for key,daemon_table in ipairs(mpds) do
		register_daemon(daemon_table)
	end
	TIMER = timer({ timeout = timeout and timeout or 0.5 })
	TIMER:add_signal("timeout", serial)	

end

function daemons()
	local daemons = DAEMONS
	return daemons
end

