require("io")
require("string")

-- TODO:escape value strings!

local playlist = {}
local pos = 0;
local f = io.popen("echo playlistinfo | curl -fsm1 telnet://127.0.0.1:6600")
for line in f:lines() do
    for key,value in string.gmatch(line, "([%w]+):[%s](.*)") do
	if key=="file" then
	    pos=pos+1
	    playlist[pos] = { pos=pos, file=value }
	elseif key=="Time" then playlist[pos]["time"]=value
	elseif key=="Artist" then playlist[pos]["artist"]=value
	elseif key=="Title" then playlist[pos]["title"]=value
	elseif key=="Album" then playlist[pos]["album"]=value
	elseif key=="Track" then playlist[pos]["track"]=value
	elseif key=="Date" then playlist[pos]["date"]=tonumber(value)
	elseif key=="Composer" then playlist[pos]["composer"]=value
	elseif key=="Id" then playlist[pos]["id"]=tonumber(value)
	end
    end
end
playlist["last"]=pos
f:close()

