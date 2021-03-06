-- hibiki
-- Music Player Daemon integration for the awesome window manager
-- Version 0.1.0

-- Copyright (c) 2011 by Jens Oliver John <jens.o.john@gmail.com>
-- Licensed under the GNU General Public License v3.
-- Obtainable through https://github.com/2ion/hibiki

-- {{{ separate environment
local math = require("math")
local coroutine = coroutine
local io = io
local string = string
local table = table
local io = io
local type = type
local print = print
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local awful = require("awful")
local timer = timer
local naughty = require("naughty")
module("hibiki")
-- }}}

-- {{{ private and public
local DAEMONS = {}
local WORKERS = {}
local DAEMON_STATUS_KEYS = {}
FLAGS = {
	ready=false
}
local STYLE = {
	title = { open='<span font_desc="DejaVu Sans 12" color="#aaaaaa">', close='</span>' },
	body  = { open='<span font_desc="DejaVu Sans 10" color "#aaaaaa">', close='</span>' },
	timeout = 3
}
-- }}}

local function dbg_notify(text)
	naughty.notify({ title="hibiki",text=text })
end

function retrieve_playlist(daemon_handle)
	local coroutines = {}
	for thread_handle=1,#daemon_handle do
		table.insert(coroutines, coroutine.create(
			function (daemon)
				local position = 0
				local stream = io.popen("echo playlistinfo |" .. daemon.telnet)
				daemon.playlist = {}
				for line in stream:lines() do
					for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
						if key=="file" then
							position = position + 1
							daemon.playlist[position] = { pos=position, file=value }
						else daemon.playlist[position][key] = value
						end
					end
				end
				stream:close()
				daemon.playlist.last = position
			end
		))
	end

	for key,routine in ipairs(coroutines) do
		coroutine.resume(routine, DAEMONS[table.remove(daemon_handle)])
	end
end

function retrieve_position(daemon_handle)
    if not DAEMONS[daemon_handle] then return nil end
    local position = nil
    local stream = io.popen("echo currentsong |" .. DAEMONS[daemon_handle].telnet)
    for line in stream:lines() do
        for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
            if key=="Pos" then
                position=tonumber(value)
                break
            end
        end
    end
    stream:close()
    return position
end

function control_playback(daemon_handle, cmd, positional_argument)
	local cry
	if positional_argument then
		cry = cmd .. " " .. tostring(positional_argument)
	else
		cry = cmd
	end

	if tonumber(daemon_handle)==0 then
		for key,daemon in ipairs(DAEMONS) do
			io.popen("echo " .. cry .. " |"	.. daemon.telnet)
		end
	elseif DAEMONS[daemon_handle] then
			io.popen("echo " .. cry .. " |" .. DAEMONS[daemon_handle].telnet)
	end
	return cmd
end

function retrieve_daemon_status(daemon_handle)
	local coroutines = {}
	for counter=1,#daemon_handle do
		table.insert(coroutines, coroutine.create(
			function (daemon)
				daemon.status = {}
				local stream = io.popen("echo status |" .. daemon.telnet)
				for line in stream:lines() do
					for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
						daemon.status[key]=value
					end
				end
				stream:close()
			end
		))
	end

	for key,routine in ipairs(coroutines) do
		coroutine.resume(routine, DAEMONS[table.remove(daemon_handle)])
	end
end

function retrieve_daemon_status_keylist()
	local daemon = DAEMONS[1]
	local stream = io.popen("echo status |" .. daemon.telnet)
	for line in stream:lines() do
		for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
			table.insert(DAEMON_STATUS_KEYS, key)
		end
	end
	stream:close()
end

function daemon_status_diff(daemon_handle)
	local daemon = DAEMONS[daemon_handle]
	local old = awful.table.clone(daemon.status)
	local diff = {}
	retrieve_daemon_status({daemon_handle})
	for key,field in ipairs(DAEMON_STATUS_KEYS) do
		if daemon.status[field]~=old[field] then
			table.insert(diff, field)	
			diff[field]={ new=daemon.status[field], old=old[field] }
		end
	end
	if #diff>0 then return true,diff
	else return false
	end
end

function playlist_menu_items(daemon_handle)
	local items = {}
	for key,value in ipairs(DAEMONS[daemon_handle].playlist) do
		table.insert(items,
			{
				value.Pos .. "\t" .. value.Artist .. ": " .. value.Title,
				function() control_playback(daemon_handle, "play", value.Pos) end,
				nil, --submenu table or function
				nil --item icon				
			})
	end
	return items
end

function popup_playlist(daemon_handle)
	retrieve_playlist({daemon_handle})
	local menu_items = playlist_menu_items(daemon_handle)
	local menu = { items=menu_items, width=350, height=20}
	local awesome_menu = awful.menu.new(MENU)
	awful.menu.show(awesome_menu, { keygrabber=true })
end


function setup_workers()
	--WORKERS.timer = awful.timer

	for X=1,#DAEMONS do
		DAEMONS[X].retrieve_playlist = coroutine.wrap(
			function (daemon)
				while true do
					local position = 0
					local stream = io.popen("echo playlistinfo |" .. daemon.telnet)
					daemon.playlist = {}
					for line in stream:lines() do
						for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
							if key=="file" then
								position = position + 1
								daemon.playlist[position] = { pos=position, file=value }
							else daemon.playlist[position][key] = value
							end
						end
					end
					stream:close()
					daemon.playlist.last = position
					coroutine.yield()
				end
			end
		)

		DAEMONS[X].notify_current_song = coroutine.wrap(
			function (daemon)
				while true do
					local song = daemon.playlist[tonumber(daemon.status["song"])]
					local text = 	STYLE.title.open..
									song.Title..
									STYLE.title.close..
									STYLE.body.open..
									song.Album..
									' ('..
									song.Date..
									')<br>'..
									song.Artist..
									STYLE.body.close
					coroutine.yield(text)
				end
			end
		)

		DAEMONS[X].notify_state = coroutine.wrap(
			function (daemon)
				while true do
					if daemon.status.state == "stop" then
						coroutine.yield("Stopped.")
					elseif daemon.status.state == "play" then
						coroutine.yield("Playing.")
					elseif daemon.status.state == "pause" then
						coroutine.yield("Paused.")
					end
				end
			end
		)

		table.insert(WORKERS, coroutine.wrap(
			function (daemon)
				while true do
					daemon.status_old = awful.table.clone(daemon.status)
					daemon.status = {}
					daemon.status_diff = {}

					local stream = io.popen("echo status |" .. daemon.telnet)
					for line in stream:lines() do
						for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
							daemon.status[key] = value
						end
					end
					stream:close()

					for key,field in ipairs(DAEMON_STATUS_KEYS) do
						if daemon.status[field] ~= daemon.status_old[field] then
							table.insert(daemon.status_diff, field)
							if field == "playlist" then
								table.insert(daemon.status_diff, "songid")
							end
						end
					end

					for key,field in ipairs(daemon.status_diff) do
						if field == "volume" then break
						elseif field == "repeat" then break
						elseif field == "random" then break
						elseif field == "single" then break
						elseif field == "consume" then break
						elseif field == "playlist" then	--playlist version number differs
							daemon.retrieve_playlist(daemon)
						elseif field == "playlistlength" then break
						elseif field == "xfade" then break
						elseif field == "mixrampdb" then break
						elseif field == "mixrampdelay" then break
						elseif field == "state" then
							naughty.notify({ text=daemon.notify_state(daemon) })
						elseif field == "song" then break
						elseif field == "songid" then
							naughty.notify({ text=daemon.notify_current_song(daemon) })
						elseif field == "time" then break
						elseif field == "elapsed" then break
						elseif field == "bitrate" then break
						elseif field == "audio" then break
						elseif field == "nextsong" then break
						elseif field == "nextsongid" then break
						end
					end

					coroutine.yield()
				end
			end
		))
	end

	WORKERS.timer:add_signal("timeout",
		function()
			for key,routine in ipairs(WORKERS) do
				routine(DAEMONS[key])
			end
		end
	)
end

function exec(timeout)
	WORKERS.timer = timer({ timeout=timeout })
	setup_workers()
	WORKERS.timer:start()
	WORKERS.timer:emit_signal("timeout")
	return true
end

function stop()
	timer.stop()
	return WORKERS.timer.started
end

function init(servers)
    for key, server in ipairs(servers) do
	print("init(): server { host=" .. server.host .. ", port=" .. server.port .. " } to register.")
        table.insert(DAEMONS,
            {
                host=server.host and server.host or "127.0.0.1",
                port=server.port and server.port or "6600",
                password=server.password and server.password or nil
            })   
    end
    for key, daemon in ipairs(DAEMONS) do
        if daemon.password then
--            daemon.telnet="curl -fsm1 telnet://" .. daemon.password .. "@" .. daemon.host .. ":" .. daemon.port
	    	daemon.telnet="netcat " .. daemon.host .. " " .. daemon.port
        else
--	    daemon.telnet="curl -fsm1 telnet://" .. daemon.host .. ":" .. daemon.port
            	daemon.telnet="netcat " .. daemon.host .. " " .. daemon.port
        end
    end
	if #DAEMONS>0 then	
		FLAGS.ready=true
		retrieve_daemon_status_keylist()
	else
		return nil
	end
end

