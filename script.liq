#!/usr/bin/liquidsoap

# initial setup
log.stdout.set(true)
stream_password = environment.get("STREAM_PASSWORD")
stream_name = environment.get("STREAM_NAME")
stream_host = environment.get("STREAM_HOST")

# Disabled due to rollback to 2.2.5
# enable_replaygain_metadata()

def announcements_protocol(~rlog,~maxtime,arg) = 
  [process.uri(extname="mp3", "/opt/announcement-generator/LizardNetRadio.RailAnnouncer /opt/announcement-generator/data.yml $(output)")]
end
protocol.add("railannounce", announcements_protocol)

# yt-dlp configuration
settings.protocol.youtube_dl.path.set("/usr/bin/yt-dlp")
settings.protocol.youtube_dl.timeout.set(600.)

# Use the telnet server for requests
settings.server.telnet.set(true)
settings.server.telnet.bind_addr.set("0.0.0.0")

# http server for livestream input
settings.harbor.bind_addrs.set(["0.0.0.0"])

# media configuration
default = single("/var/music-local/partypioneers.mp3")

shoutouts = amplify(1.5, request.queue(id="shoutouts"))
requests = request.queue(id="request",timeout=120.)

# FYI: `delay(n, ...)`  will wait for n seconds after the **end** of the track


####### Main radio setup #######
jingles = delay(300., playlist("/var/jingles/jingles.m3u", prefix="annotate:title=\"This is Radio LizardNet\",artist=\"Radio LizardNet\":"))

main_playlist = playlist("/var/playlists/main.m3u")
specials_playlist = delay(900., playlist("/var/playlists/specials.m3u"))
alternate_playlist = delay(120., playlist("/var/playlists/edm.m3u"))

radio = fallback([shoutouts, jingles, requests, specials_playlist, alternate_playlist, main_playlist, default])
livestream = input.harbor("live.ogg", port=8080, password=stream_password)
full = fallback.skip(livestream, fallback=radio)

output.icecast(%mp3,
  host=stream_host, port=8000,
  password=stream_password,
  mount=stream_name, public=false, full)


####### Station radio setup #######
chillout_playlist = fallback([playlist("/var/playlists/chillout.m3u"), blank(duration=1.)])

# Announcements
announcements = single("railannounce:")
announcements = fallback([delay(10., announcements), blank(duration=1.)])
announcements = ladspa.freeverb3(announcements, wet_level=0.3, dry_level=0.6, room_size=0.9, damping=0.9)

station_radio = add(
    [chillout_playlist, announcements],
    weights = [0.6, 1.],  # volume levels for aria and announcements
    normalize = false  # disable normalization to keep original volume levels
)

output.icecast(%mp3,
  host=stream_host, port=8000,
  password=stream_password,
  mount="stationradio", public=false, station_radio)