#!/bin/bash
#adb shell 'logcat --pid=$(pgrep cmf)' | cut --bytes=49- >outdoor-22-january.log
# download log files from device
# cd ./files && adb pull /storage/emulated/0/Android/data/com.nothing.cmf.watch/files/watchband/ .
# GPSCorrectUtil

gpx_creator="logcat-to-gpx.sh"
gpx_file="test.gpx"

print_gpx_header()
# $1 timestamp
{
cat <<EOF  
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="$gpx_creator" xmlns="http://www.topografix.com/GPX/1/1">
<metadata><time>$(print_utc_time "$1")</time></metadata>
<trk><trkseg>
EOF
}

print_gpx_trkpt()
# $1 timestamp
# $2 latitude
# $3 longitude
{
  echo "<trkpt lat=\"$2\" lon=\"$3\"><time>$(print_utc_time "$1")</time></trkpt>"
}

print_utc_time()
# $1 timestamp
{
   date --utc -d @"$1" +"%Y-%m-%dT%H:%M:%SZ"
}

OIFS="$IFS"
 grep -A2 "'.*gps.*'" "$1" | while read -r line; do 
   # echo "read: $line"
    case "$line" in
     *gps*) set -- $line
            longitude=${10%,}
            ;;
    *latitude:\ [0-9]*) set -- $line
            latitude=${8%,}
            ;;
    *timeStamp*)
            # remove single qoutes around timeStamp
            IFS=" '" 
            set -- $line
            IFS="$OIFS"
            timestamp=$(printf "%d" 0x"$8")
            if [ -z "$firsttimestamp" ]; then
                print_gpx_header "$timestamp" >"$gpx_file"
                firsttimestamp="$timestamp"
            fi
            ;;
# -- is grep group separator
    --) 

        echo "$(print_utc_time "$timestamp") $latitude $longitude"
        print_gpx_trkpt "$timestamp" "$latitude" "$longitude" >>"$gpx_file"
        ;;
    esac
done 

echo "</trkseg></trk>
</gpx>" >>"$gpx_file"
 
