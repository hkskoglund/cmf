#!/bin/sh
GPX_CREATOR=$(basename "$0")

# log file in ./files/watchband directory on device
# requires: data must be downloaded from the watchband by the app
# and the log file must be available in the ./files/watchband directory

# heartrate and timestamp is also available as json in
# 2025-01-26 11:13:51.571 [mqt_native_modules] DEBUG WatchDataUpload-getExeciseDatas_start
# gps hex data from http:
# https://d3ggmty0576dru.cloudfront.net/watch_band/1707307855859793920/outdoor_running/outdoor_running_20250126092101.txt?Expires=1737909066&Signature=ffXFhYhuMx-jvGdgUVX5Zv6X5AaO2-Zw9V36dUVdUspNjHJxj0hHg--eBVJhvakXUK94lLCXR0sjTUIHGlM3NYmJ5THneZ9xSqmHu2xwPiJYX75emEu8qWhRE1OYdr6uR4hc55T4xXxHI4bWmLiXcOzmsF6k8xMcmlWs4tV-GgIPTFcCvm7G-3CE-CHUDLlEVqak4i5-Ze~MwRd7Os0vPzTpMl9ANDl8rYJfeQmEdv1Enc9UIlda~ETcrep1pgBgya8Re5LhEE6TdPCUzTIK2pDFXUuRk4gDzz7Tnsk1mQW4WBAhME0rVHs1a1Ehlc-tOg4nRaf6AoxOQjEmoG2tnA__&Key-Pair-Id=K3V0FUNXST87Q
# https://d3ggmty0576dru.cloudfront.net/watch_band/1707307855859793920/outdoor_running/outdoor_running_20250126092101.txt?Expires=1738143031&Signature=rCziFl6h-qehVhw4KOYwbVd8K1pBBltHiOU8DXxvX8sa8RaD0TLWTAVXi9l1F8UhRWfGrALYxYm96wFt1O3TNGcj7KoLYPytPFjazFQ7HkQp7yqMrHZ26VZUlkqWLriD1EAsWjdAKRhhKQEP9I4-jyhkAL~0rwiWy2doLVVI9t23F9OxUp5Yud19u6kk-QvuzAARn8xTG-J-9SJIDqLjPHBZRZHiem3ZHup7CInCV31Th5u83~PlWSNKEupsBtJACNwMQk~iugWe~lTlwzA02H~UjRprRwtiGZ4DP~i2DlWC6rdkuK5FdIlD8RX9s86qUkDdRpLdC18tkbL-xpt22w__&Key-Pair-Id=K3V0FUNXST87Q'

# https://d3ggmty0576dru.cloudfront.net/watch_band/1707307855859793920/outdoor_running/outdoor_running_20250124115220.txt?Expires=1737909543&Signature=o80gOkUGpElSiJxCbejBrBEAVAe-7BMZ1B1Hs-DxPb~T~JWTC8o9szC5psziuC-Fx9Qm-Q2OFJnZYo0gGqWgf4pEtJ1r5rfizYM4frh28p8xxI5FTZiaxQxYLkGz5hxrgbiwY0jivbydHS7WMp18Ti3Q3vtBmJvzzZSL~kYc1C6NazZPwsteQoLfvzuZkG3kwNA~cf1-j3PDl3CpO0zs8NeU7c7i-OsVYWDg69RupwR8c9v3nuqPDntVwGMbSvVBHJd34WcQHcuzuj7doOVN0oin8jX9gy4Ijr1U4yfM-HJmDjmoKmf37wbNc90mqFLMBKDiTyWpe9GW-SxXYZgp5g__&Key-Pair-Id=K3V0FUNXST87Q

RECVALUE_OUTDOOR_HEARTRATE="00e0"
RECCMD_OUTDOOR_HEARTRATE="0001"
RECPAYLOAD_HEARTRATE="heartvalueplayload"
RECBYTECUTPOS_HEARTRATE=61

RECVALUE_GPS="ffff"
RECCMD_GPS="a05a"
RECPAYLOAD_GPS="gpsplayload"
RECBYTECUTPOS_GPS=54

cleanup() {
    [ -n "$DELETE_FILES" ] && rm -f "$@"
}

print_utc_time()
# $1 timestamp
{
   date --utc -d @"$1" +"%Y-%m-%dT%H:%M:%SZ"
}

get_signed_number()
# adapted from deepseek/handling two complements signed 32-bit numbers
# $1 number
# set SIGNED_NUMBER
{
    _masked_number=$(( "$1" & 0xFFFFFFFF ))     # Mask to 32-bit
    if [ $(( ( "$_masked_number" >> 31 ) & 1 )) -eq 1 ]; then
        SIGNED_NUMBER=$(( "$1" - 0x100000000 ))
    else
        SIGNED_NUMBER="$1"
    fi
    unset _masked_number
}

read_hex_rec()
# debug info should be written to stderr
{
    recvalue="$1"
    reccmd="$2"

    #echo "reccmd: $reccmd recvalue: $recvalue" >&2

    while read -r line; do
        #echo "read: $line" >&2
        #shellcheck disable=SC2046
        set --  $(echo "$line" | fold --width=2 | paste --serial --delimiter=' ')
        while [ $# -ge 8 ]; do

            if [ "$reccmd" = "$RECCMD_OUTDOOR_HEARTRATE" ] && [ "$recvalue" = "$RECVALUE_OUTDOOR_HEARTRATE" ]; then
                #echo read timestamp: "$1 $2 $3 $4" >&2
                timestamp=$((0x"$4$3$2$1"))
                timestamp_date=$(print_utc_time "$timestamp")
                shift 4
                #echo read heartrate: "$1 $2 $3 $4"
                heartrate=$((0x"$4$3$2$1"))
                shift 4
                #echo "$timestamp_date $heartrate" >&2
                echo "{ \"timestamp\": $timestamp, \"timestamp_date\": \"$timestamp_date\", \"heartrate\" : $heartrate }" 
            elif [ "$reccmd" = "$RECCMD_GPS" ] && [ "$recvalue" = "$RECVALUE_GPS" ]; then
                # gps track
                #echo gps read timestamp: "$1 $2 $3 $4"
                timestamp=$((0x"$4$3$2$1"))
                timestamp_date=$(print_utc_time "$timestamp")
                shift 4
                #echo "gps read lon: $1 $2 $3 $4"
                lon=$((0x"$4$3$2$1"))
                get_signed_number "$lon"
                lon=$SIGNED_NUMBER
                lon_float=$(echo "scale=7; $lon / 10000000" | bc)
                shift 4
                #echo "gps read lat: $1 $2 $3 $4"
                lat=$((0x"$4$3$2$1"))
                get_signed_number "$lat"
                lat=$SIGNED_NUMBER
                lat_float=$(echo "scale=7; $lat / 10000000" | bc)
                shift 4
                #echo "$timestamp_date $lat $lon" >&2
                echo "{ \"timestamp\": $timestamp, \"timestamp_date\": \"$timestamp_date\", \"lat\" : $lat_float, \"lon\" : $lon_float }" 

            fi
        
        done

         #echo "remaining checksum?: $# $*" >&2

    done
}

filter_log()
{
    recvalue="$1"
    reccmd="$2"
    recpayload="$3"
    rec_bytecutpos="$4"

    grep -A5 "h0-RecValue：$recvalue RecCmd:$reccmd" "$log_file" | tee grep-"$recpayload".log | grep -i "$recpayload" | cut --bytes="$rec_bytecutpos"-
    cleanup grep-"$recpayload".log
}

filter_heartrate_rec()
{
    filter_log $RECVALUE_OUTDOOR_HEARTRATE $RECCMD_OUTDOOR_HEARTRATE $RECPAYLOAD_HEARTRATE $RECBYTECUTPOS_HEARTRATE | read_hex_rec $RECVALUE_OUTDOOR_HEARTRATE $RECCMD_OUTDOOR_HEARTRATE
}

filter_gps_rec()
{
    filter_log $RECVALUE_GPS $RECCMD_GPS "$RECPAYLOAD_GPS" "$RECBYTECUTPOS_GPS" | read_hex_rec $RECVALUE_GPS $RECCMD_GPS
}

filter_heartrate()
{
    # try using one line on json data
    # reconstruct ble data from json data
    # why are json not converted to heartrate: and ordinary timestamp: before upload?
    # logfile typo in ExeciseDatas -> ExerciseDatas
   
    grep '.*WatchDataUpload-getExeciseDatas_start.*"abilityId":"'$RECVALUE_OUTDOOR_HEARTRATE'"' "$log_file" |  tee grep-heartrate.log | cut -b89- | jq -sr  '.[][] | select(.abilityId=="'$RECVALUE_OUTDOOR_HEARTRATE'") | .startTime+.datas' |  read_hex_rec $RECVALUE_OUTDOOR_HEARTRATE $RECCMD_OUTDOOR_HEARTRATE >heartrate.log
    cleanup grep-heartrate.log
}

filter_gps()
{
    # One line of all data (It does not contain last 8 bytes of each record/checksum?)
    # it is safer to read one line, than grepping multiple records/lines
    # also this is INFO debug level, which may not be turned off
  
    grep ".*l-GpsData" "$log_file" |  tee grep-gpsdata.log | cut -b48- | fold --width=$((24*16)) | read_hex_rec $RECVALUE_GPS $RECCMD_GPS >gps.log
    cleanup grep-gpsdata.log
}

create_hoydedata_gpx()
{

    jq -s '[ .[].punkter.[] ]' curl-hoydedata-response-"$FILENAME_POSTFIX".json >curl-hoydedata-response-points-"$FILENAME_POSTFIX".json

    # with help from chatgpt ai
    jq -s 'transpose | map(add | del(.x, .y, .datakilde, .terreng) | .ele = .z | del(.z))'  track-hrlatlon-"$FILENAME_POSTFIX".json curl-hoydedata-response-points-"$FILENAME_POSTFIX".json >track-hrlatlon-ele-"$FILENAME_POSTFIX".json

    if jq --raw-output '
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
"<gpx version=\"1.1\" creator=\"'"$GPX_CREATOR"'\" xmlns=\"http://www.topografix.com/GPX/1/1\" xmlns:gpxtpx=\"http://www.garmin.com/xmlschemas/TrackPointExtension/v1\">\n" +
"  <trk>\n" +
"    <trkseg>\n" +
(. | map(
"      <trkpt lat=\"" + 
  (.lat | tostring) + 
  "\" lon=\"" + 
  (.lon | tostring) + 
  "\">\n" +
"        <time>" + .timestamp_date + "</time>\n" +
"        <ele>" + (.ele | tostring) + "</ele>\n" +
    (if .heartrate != null then
        "        <extensions>\n" +
        "          <gpxtpx:TrackPointExtension >\n" +
        "            <gpxtpx:hr>" + (.heartrate | tostring) + "</gpxtpx:hr>\n" +
        "          </gpxtpx:TrackPointExtension>\n" +
        "        </extensions>\n" 
    else "" end) +
"      </trkpt>"
) | join("\n") ) +
"    </trkseg>\n" +
"  </trk>\n" +
"</gpx>\n"
' track-hrlatlon-ele-"$FILENAME_POSTFIX".json >track-ele-"$FILENAME_POSTFIX".gpx; then 
    echo "Created track-ele-$FILENAME_POSTFIX.gpx"
    else
        echo "Failed to create track-ele-$FILENAME_POSTFIX.gpx"
    fi

  cleanup curl-hoydedata-response-"$FILENAME_POSTFIX".json curl-hoydedata-response-points-"$FILENAME_POSTFIX".json track-hrlatlon-"$FILENAME_POSTFIX".json track-hrlatlon-ele-"$FILENAME_POSTFIX".json
}

get_elevation_hoydedata()
{
    #group into array of arrays with 50 in each array, due to api limit
    jq -n '[inputs | . as $arr | range(0; $arr | length; 50) | $arr[.:(. + 50)]]' track-hrlatlon-"$FILENAME_POSTFIX".json >track-hrlatlon-grouped-"$FILENAME_POSTFIX".json

    # add elevation to points, create curl url config pointlist for each group for ws.geonorge.no/hoydedata/v1/punkt
    jq -r '.[] | "url = https://ws.geonorge.no/hoydedata/v1/punkt?koordsys=4258&punkter=\\["+ ( map("\\["+(.lon|tostring)+","+(.lat|tostring)+"\\]") |  join(","))+"\\]"' track-hrlatlon-grouped-"$FILENAME_POSTFIX".json >curl-hoydedata-pointlist-urls-"$FILENAME_POSTFIX".txt
    cleanup track-hrlatlon-grouped-"$FILENAME_POSTFIX".json
    echo "Fetching elevation data from ws.geonorge.no/hoydedata/v1/punkt"
    curl --silent --config curl-hoydedata-pointlist-urls-"$FILENAME_POSTFIX".txt >curl-hoydedata-response-"$FILENAME_POSTFIX".json
}    

merge_hr_gps_gemini() {
  GROUP_BY_SECONDS=5
  # watchband logs gps and heartrate data separately each 5 seconds, so we need to merge them
  set -x
  jq --slurp '
    sort_by(.timestamp) |
    group_by(.timestamp / '$GROUP_BY_SECONDS' | floor) |  # Group by n-second intervals
    map(
      if length == 1 then .[0]
      else reduce .[] as $item ({}; . * $item) # Merge objects within the group
      end
    ) |
    map(select(has("lon") and has("lat"))) # Filter complete entries
  ' heartrate-"$FILENAME_POSTFIX".log gps-"$FILENAME_POSTFIX".log > track-hrlatlon-"$FILENAME_POSTFIX".json
  _exitcode_merge_hr_gps_gemini=$?
  set +x
  cleanup heartrate-"$FILENAME_POSTFIX".log gps-"$FILENAME_POSTFIX".log
  return $_exitcode_merge_hr_gps_gemini
}

merge_hr_gps()
{

    # Merge and sort by timestamp
    jq --slurp 'sort_by(.timestamp)' heartrate-"$FILENAME_POSTFIX".log gps-"$FILENAME_POSTFIX".log > merged_sorted-"$FILENAME_POSTFIX".json

    # Deduplicate or merge entries with close timestamps
    jq '[reduce .[] as $entry (
        [];
        if (. | map(select((.timestamp - $entry.timestamp | abs) <= 2)) | length) == 0 then
            . + [$entry]
        else
            map(if (.timestamp - $entry.timestamp | abs) <= 2 then . * $entry else . end)
        end
    )] | .[]' merged_sorted-"$FILENAME_POSTFIX".json > track-"$FILENAME_POSTFIX".json

    # Remove objecs without heartrate,lat and lon

    jq '[.[] | select(has("heartrate") and has("lon") and has("lat"))]' track-"$FILENAME_POSTFIX".json > track-hrlatlon-"$FILENAME_POSTFIX".json
    cleanup heartrate-"$FILENAME_POSTFIX".log gps-"$FILENAME_POSTFIX".log merged_sorted-"$FILENAME_POSTFIX".json track-"$FILENAME_POSTFIX".json
}

create_gpx()
{
    if jq --raw-output '
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<gpx version=\"1.1\" creator=\"'"$GPX_CREATOR"'\" xmlns=\"http://www.topografix.com/GPX/1/1\" xmlns:gpxtpx=\"http://www.garmin.com/xmlschemas/TrackPointExtension/v1\">\n" +
    "  <trk>\n" +
    "    <trkseg>\n" +
    (. | map(
    "      <trkpt lat=\"" + 
    (.lat | tostring) + 
    "\" lon=\"" + 
    (.lon | tostring) + 
    "\">\n" +
    "        <time>" + .timestamp_date + "</time>\n" +
    (if .heartrate != null then
        "        <extensions>\n" +
        "          <gpxtpx:TrackPointExtension >\n" +
        "            <gpxtpx:hr>" + (.heartrate | tostring) + "</gpxtpx:hr>\n" +
        "          </gpxtpx:TrackPointExtension>\n" +
        "        </extensions>\n" 
    else "" end) +
    "      </trkpt>"
    ) | join("\n") ) +
    "    </trkseg>\n" +
    "  </trk>\n" +
    "</gpx>\n"
    ' track-hrlatlon-"$FILENAME_POSTFIX".json >track-"$FILENAME_POSTFIX".gpx; then 
         echo "Created track-$FILENAME_POSTFIX.gpx"
    else
        echo "Failed to create track-$FILENAME_POSTFIX.gpx"
        return 1
    fi
}

check_adb_installed()
{
    # Check if adb is installed
    if ! command -v adb 1>/dev/null 2>/dev/null; then
        echo "adb could not be found. Please ensure adb is installed and added to your PATH."
        exit 1
    fi
}

pull_watchband()
{
    check_adb_installed

    # Check if a device is connected
    if adb get-state 1>/dev/null 2>&1; then
        echo "Pulling log files from /storage/emulated/0/Android/data/com.nothing.cmf.watch/files/watchband/ "
        adb pull /storage/emulated/0/Android/data/com.nothing.cmf.watch/files/watchband/ .
    else
        echo "No device is connected. Log files not pulled from /storage/emulated/0/Android/data/com.nothing.cmf.watch/files/watchband/ "
    fi
}

get_filename_postfix()
{
    # $1 counter
    date --utc -d @"$(eval echo \$SPORTMODE_START_TIME_"$1")" +%Y%m%d_%H%M%S
}

split_heartrate_gps()
{
    OIFS="$IFS"
    IFS="$IFS:>"
    #two log lines combined by | paste -d" " - -
    #2025-01-30 14:10:15.980 [main] DEBUG t-sportType==>2 2025-01-30 14:10:15.980 [main] DEBUG t-sportModeValue timeResult:1738239834 sportTimes:1738241193
    SPORTMODE_LINE_COUNTER=0
    while read -r sportmode_line; do 
        SPORTMODE_LINE_COUNTER=$((SPORTMODE_LINE_COUNTER+1))
        # shellcheck disable=SC2086
        set -- $sportmode_line
        sport_type=$8
        start_time=${17}
        stop_time=${19}
        eval SPORTMODE_SPORT_TYPE_$SPORTMODE_LINE_COUNTER="$sport_type"
        eval SPORTMODE_START_TIME_$SPORTMODE_LINE_COUNTER="$start_time"
        eval SPORTMODE_STOP_TIME_$SPORTMODE_LINE_COUNTER="$stop_time"
        echo "sport_type: $sport_type $start_time: $start_time $(print_utc_time "$start_time") stop_time: $stop_time $(print_utc_time "$stop_time")" >&2
        FILENAME_POSTFIX=$(get_filename_postfix "$SPORTMODE_LINE_COUNTER")
        jq 'select(.timestamp >='"$start_time"' and .timestamp <='"$stop_time"')' heartrate.log >heartrate-"$FILENAME_POSTFIX".log
        jq 'select(.timestamp >='"$start_time"' and .timestamp <='"$stop_time"')' gps.log >gps-"$FILENAME_POSTFIX".log
    done <sportmode-times.log
    IFS="$OIFS"
    SPORTMODE_LINE_COUNTER_MAX=$SPORTMODE_LINE_COUNTER
    cleanup sportmode-times.log
}

#dont mess up git source directory with data
if [ "$(pwd)" = "/home/henning/github/cmf" ]; then
    [ ! -d "data" ] && mkdir data && mkdir data/files/watchband
    # shellcheck disable=SC2164
    cd data
fi

# process options

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            cat <<EOF
Usage: $0 [log_file]
Converts hex data from cmf watch app log file to gpx file
Options:
   --pull              pull watchband log files from mobile phone which contains the hex data for heartrate and gps
   --file [log_file]   specify log file to process
   --delete            delete intermediary files, used for debugging
   --hoydedata         get elevation data from ws.geonorge.no/hoydedata/v1/punkt and create track-ele.gpx
EOF
            exit 0
            ;;
        --delete)
            # delete intermediary files
            DELETE_FILES=true
            ;;
        --hoydedata)
            ELEVATION_CORRECTION=true
            ;;

        --file)
            log_file=$(realpath "$2")
            shift
            ;;
        --pull)
            pull_watchband
            ;;
        --pull-gps)
            # try to capture GPS files from watch
            # use case: if debug log is not available, maybe GPS data is still available during upload
            # 2025-01-30 14:10:16.039 [main] DEBUG t-sportModeValue gpsAbsolutePath:/storage/emulated/0/Android/data/com.nothing.cmf.watch/files/GPS/1738241253_1738242550.txt
            pull_timeout=60
            pull_sleep=0.1
            echo "Pulling log files from /storage/emulated/0/Android/data/com.nothing.cmf.watch/files/watchband/GPS for $pull_timeout seconds"
            timeout $pull_timeout bash -c "while true; do 
                    adb pull /storage/emulated/0/Android/data/com.nothing.cmf.watch/files/watchband/GPS .
                    sleep $pull_sleep
                done"
            ;;

        *) echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
    shift
done

if [ -z "$log_file" ]; then
    echo "No log file specified. Use --file [log_file] to specify the log file."
    exit 1
fi

if [ ! -f "$log_file" ]; then
    echo "Log file $log_file does not exist."
    exit 1
fi

echo "Processing log file: $log_file cwd: $(pwd)"

# find start and end times of gps activity
# it seems that even for multiple acitivities all gps data is in one file, this is also the case for heartrate data
# it could be possible to do automatic session splitting based on time difference between gps timestamps, since normally
# that watch stores a gps position each 5 seconds
#2025-01-30 14:10:16.036 [main] DEBUG t-sportModeValue timeResult:1738241253 support gps:01
#2025-01-30 14:10:16.037 [main] DEBUG t-sportModeValue timeResult:1738241253 sportTimes:1738242550
#                               DEBUG t-sportModeValue gpsAbsolutePath:/storage/emulated/0/Android/data/com.nothing.cmf.watch/files/GPS/1738241253_1738242550.txt

# deepseek: paste Using - - means paste will read from standard input twice, effectively combining every two lines into one
if ! grep --context=2 't-sportModeValue timeResult.*support gps:01$' "$log_file" | grep -E "sportType|sportTimes" | paste --delimiters=" " - - >sportmode-times.log; then 
    echo "No GPS activities found in log file" >&2
    exit 1
else
  echo "Found $(wc -l <sportmode-times.log) GPS activities in log file"
fi

# first filter hex data from log file

filter_heartrate
filter_gps
split_heartrate_gps

SPORTMODE_LINE_COUNTER=0
while [ $SPORTMODE_LINE_COUNTER -lt "$SPORTMODE_LINE_COUNTER_MAX" ]; do
    SPORTMODE_LINE_COUNTER=$((SPORTMODE_LINE_COUNTER+1))
    FILENAME_POSTFIX=$(get_filename_postfix "$SPORTMODE_LINE_COUNTER")

    if merge_hr_gps_gemini; then 
        create_gpx

        if [ -n "$ELEVATION_CORRECTION" ]; then
            # device does not provide elevation data, so fetch it from ws.geonorge.no/hoydedata/v1/punkt, and create gpx with elevation
        if get_elevation_hoydedata; then 
            create_hoydedata_gpx
        fi
        cleanup curl-hoydedata-pointlist-urls-"$FILENAME_POSTFIX".txt  curl-hoydedata-response-"$FILENAME_POSTFIX".json curl-hoydedata-response-points-"$FILENAME_POSTFIX".json
        fi

        cleanup track-hrlatlon-"$FILENAME_POSTFIX".json
    else
        echo >&2 "Failed to merge heartrate and gps data exitcode: $?"
    fi
done

