--[[
	hibiki
	Music Player Daemon integration with the awesome window manager
	Version 1.3

	Copyright (C) 2011 Jens Oliver John (twoion) <jens.o.john@gmail.com>.

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

	This file is obtainable through https://github.com/2ion/hibiki.

    TODO for 1.3:
    * Operatable submenus in playlistmenu
    * Use icons in notifications and playlistmenu
    
    TODO for 2.0:
    * Rewrite the eventloops using coroutines
    * Fix random locks

--]]

local socket = require("socket")

local HIBIKI = {
    host = "127.0.0.1",
    port = 6600,
    password = nil,
    timeout = 0.5,
    terminator = "OK"
}

function HIBIKI:new(host,port,timeout,password)
    local n = {}
    setmetatable(n, self)
    self.__index = self

    if host then n.host = host end
    if port then n.port = port end
    if password then n.password = password end
    if timeout then n.timeout = timeout end

    local tcp = socket.connect(n.host,n.port)
    if not tcp then
        return nil
    else
        n.tcp = tcp
        n.tcp:settimeout(1)
    end

    --[[
    n.timer = timer({ timeout = n.timeout })
    timer:add_signal("timeout", n.loop)
    timer:emit_signal("timeout")
    timer:start()
    --]]
    return n
end

function HIBIKI:send(data)
    return self.tcp:send(data)
end

function HIBIKI:read(data)
    if self:send(data) then
        local lines = {}
        local line = nil
        print(self.tcp:receive(22222))
        print(self.tcp:receive(22222))
    end
    return nil
end


function HIBIKI:loop()

end

local m = HIBIKI:new()
m:read("playlistinfo")
