#!/bin/bash
source /run/secrets/*

exec ffmpeg -re -ac 1 -f lavfi -i anullsrc -acodec libmp3lame -ab 32k -ac 1 -content_type audio/mpeg -f mp3 icecast://source:${STREAM_PASSWORD}@icecast:8000/fallback
