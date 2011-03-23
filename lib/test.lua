require("hibiki")
daemon={1}
hibiki.init({{host="127.0.0.1", port=6600 }})
hibiki.retrieve_playlist_co({1})
hibiki.retrieve_daemon_status({1})
hibiki.print_daemon(1)

