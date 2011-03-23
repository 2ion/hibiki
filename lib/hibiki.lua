-- hibiki
-- Music Player Daemon integration for the awesome window manager
-- Version 0.1.0

-- Copyright (c) 2011 by Jens Oliver John <jens.o.john@gmail.com>
-- Licensed under the GNU General Public License v3.
-- Obtainable through https://github.com/2ion/hibiki

-- {{{ separate environment
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
--local awful = require("awful")
--local naughty = require("naughty")
module("hibiki")
-- }}}

-- {{{ private and public tables
local DAEMONS = {}
FLAGS = {
	ready=false
}
-- }}}

function retrieve_playlist_co(daemon_handle)
	local coroutines = {}
	for thread_handle=1,table.maxn(daemon_handle) do
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
						elseif key=="Time" then daemon.playlist[position][key] = value
						elseif key=="Artist" then daemon.playlist[position][key] = value
						elseif key=="Title" then daemon.playlist[position][key] = value
						elseif key=="Album" then daemon.playlist[position][key] = value
						elseif key=="Track" then daemon.playlist[position][key] = value
						elseif key=="Date" then daemon.playlist[position][key] = value
						elseif key=="Composer" then daemon.playlist[position][key] = value
						elseif key=="Id" then daemon.playlist[position][key] = value
						end
					end
				end
				stream:close()
				daemon.playlist.last = position
			end
		))
	end

	for key,routine in ipairs(coroutines) do
		print(coroutine.resume(routine, DAEMONS[table.remove(daemon_handle)]))
	end
end

function retrieve_playlist(daemon_handle)
    local queue = {}
    if type(daemon_handle)=="number" then
        if not DAEMONS[daemon_handle] then
			print("here")
            return nil
        else
            table.insert(queue, DAEMONS[daemon_handle])
        end
    elseif type(daemon_handle)=="table" then
        for key,value in ipairs(daemon_handle) do
            table.insert(queue, DAEMONS[tonumber(value)])
        end
    else return nil
    end    
    for key,daemon in ipairs(queue) do
        local position = 0
        local stream = io.popen("echo playlistinfo |" .. daemon.telnet)
        for line in stream:lines() do
            for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
                if key=="file" then
                    daemon.playlist = {}
                    position = position + 1
                    daemon.playlist[position] = { pos=position, file=value }
                elseif key=="Time" then daemon.playlist[position][key] = tonumber(value)
                elseif key=="Artist" then daemon.playlist[position][key] = value
                elseif key=="Title" then daemon.playlist[position][key] = value
                elseif key=="Album" then daemon.playlist[position][key] = value
                elseif key=="Track" then daemon.playlist[position][key] = value
                elseif key=="Date" then daemon.playlist[position][key] = value
                elseif key=="Composer" then daemon.playlist[position][key] = value
                elseif key=="Id" then daemon.playlist[position][key] = value
                end
            end
        end
        stream:close()
        daemon.playlist.last = position
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
	--TODO:Use all the nice coroutines!!!
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
            daemon.telnet="curl -fsm1 telnet://" .. daemon.password .. "@" .. daemon.host .. ":" .. daemon.port
        else
            daemon.telnet="curl -fsm1 telnet://" .. daemon.host .. ":" .. daemon.port
        end
    end
	FLAGS.ready=true
end

