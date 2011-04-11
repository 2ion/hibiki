require("hibiki")
--register daemons
hibiki.init({
	{ host="192.168.42.1", port="6600", password="nonsense" }, --mpd runs on another box
	{							}, --defaults to mpd at 127.0.0.1:6600 with no password set
	{ host="127.0.0.1", port="9966" }},
	0.5) --update frequency
--get a table with daemon objects, each will have a fully interface
local mpdaemons = hibiki.daemons()
--do something
mpdaemons[1].playback.Play() --sets mpd state to 'play'
mpdaemons[2].playback.Play(5) --plays song at playlist position 5 (counts from zero)
mpdaemons[1].ui.playlistmenu() --under the cursor, displays the playlist menu

