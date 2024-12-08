#!/usr/bin/liquidsoap

# initial setup
log.stdout.set(true)
enable_replaygain_metadata()
stream_password = environment.get("STREAM_PASSWORD")

# yt-dlp configuration
settings.protocol.youtube_dl.path.set("/usr/bin/yt-dlp")
settings.protocol.youtube_dl.timeout.set(600.)

# Use the telnet server for requests
settings.server.telnet.set(true)
settings.server.telnet.bind_addr.set("0.0.0.0")

# http server for livestream input
settings.harbor.bind_addrs.set(["0.0.0.0"])

# media configuration
default = single("/music/media/Ascent.flac")

shoutouts = amplify(1.5, amplify(1., override="replaygain_track_gain", request.queue(id="shoutouts")))
requests = amplify(1., override="replaygain_track_gain", request.queue(id="request",timeout=120.))

# FYI: `delay(n, ...)`  will wait for n seconds after the **end** of the track

jingles = delay(300., amplify(1., override="replaygain_track_gain", playlist("/var/jingles/jingles.m3u")))

main_playlist = amplify(1., override="replaygain_track_gain", playlist("/music/tss.m3u"))
specials_playlist = delay(3600., amplify(1., override="replaygain_track_gain", playlist("/music/finland/finland.m3u")))
alternate_playlist = delay(120., amplify(1., override="replaygain_track_gain", playlist("/music/lizardnet-edm/lizardnet-edm.m3u")))

christmas = delay(15., amplify(1., override="replaygain_track_gain", playlist("/var/playlists/lrchristmas.m3u")))

radio = fallback([shoutouts, jingles, requests, christmas, specials_playlist, alternate_playlist, main_playlist, default])

livestream = input.harbor("live.ogg", port=8080, password=stream_password)

full = fallback.skip(livestream, fallback=radio)

output.icecast(%mp3,
  host="icecast", port=8000,
  password=stream_password,
  mount="radio", public=false, full)
