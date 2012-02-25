<html>
<head>
<meta name="author" content="Jens Oliver John <jens.o.john@gmail.com>">
<style type="text/css">
body 		{ color:black; background-color:white; font-family:sans-serif;}
a:link		{ text-decoration:none; color:black; }
a:visited	{ text-decoration:none; color:black; }
a:hover		{ text-decoration:underline; color:blue; }
h1		{ text-align:center; background-color:#ccffcc; padding:0.2em; display:block; }
h2		{ text-align:left; background-color:#ccffcc; padding:0.2em; display:block; }
h6		{ text-align:center; background-color:#ccffcc; padding:0.2em; display:block; }
div:greenbox	{ background-color:#ccffcc; }
div:centerbox	{ text-align:center; font-style:italic; display:block; }
</style>
<title>hibiki</title>
</head>
<body>

<h1>hibiki</h1>
	<div style="text-align:center; font-style:italic;">
	<a href="http://musicpd.org">Music Player Daemon</a> integration with the <a href="https://awesome.naquadah.org">awesome window manager</a>.
	</div>

<h2>Project outline</h2>
	<ul>
		<li>Firstly, <i>hibiki</i> shall provide a Lua library giving access to all capabilities of the MPD protocol.</li>
		<li>Secondly, it shall offer methods one can use to construct a graphical MPD client based off the awesome window manager's Lua API.</li>
		<li>Thirdly, it shall provide MPD status displays by the means of awesome's <i>naughty</i> nofification and <i>vicious</i> widget library.</li>
	</ul>
	In its implementation, <i>hibiki</i> shant use any library or tool that hant been already put to use by the <i>awesome</i> developers and depend on more things as necessary. With <i>hibiki</i>, I set out both to master the Lua programming language (the earlier, the better, I assume), so in any part of the code, there might be a crux ... well, participants are welcome.



<hr>
<div style="text-align:center; font-style:italic; font-size:10pt;">
Written by <a href="https://github.com/2ion">Jens Oliver John (2ion)</a>. This site has been published on <a href="https://github.com/2ion/hibiki">github.com</a> as part of the <i>hibiki</i> open source project and will be revisioned as it seems necessary to the author. To this document, the current <i>hibiki</i> project's license applies.
</div>
</body>
</html>
