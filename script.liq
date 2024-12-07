#!/usr/bin/liquidsoap

log.stdout.set(true)

settings.protocol.youtube_dl.path.set("/usr/bin/yt-dlp")
settings.protocol.youtube_dl.timeout.set(600.)

# Use the telnet server for requests
settings.server.telnet.set(true)
settings.server.telnet.bind_addr.set("0.0.0.0")

settings.harbor.bind_addrs.set(["0.0.0.0"])


default = single("/music/media/Ascent.flac")

shoutouts = request.queue(id="shoutouts")
requests = request.queue(id="request",timeout=120.)

# FYI: `delay(n, ...)`  will wait for n seconds after the **end** of the track

tss = playlist("/music/tss.m3u")
jingles = delay(300., playlist("/music/jingle/jingles.m3u8"))
finland = delay(3600., playlist("/music/finland/finland.m3u"))
edm = delay(120., playlist("/music/lizardnet-edm/lizardnet-edm.m3u"))

radio = fallback([shoutouts, jingles, requests, finland, edm, tss, default])


livestream = input.harbor("live.ogg", port=8080, password="...")

# full = fallback(track_sensitive=false, [livestream, radio])
full = fallback.skip(livestream, fallback=radio)

output.icecast(%mp3,
  host="icecast",port=8000,password="...",
  mount="radio", full)
