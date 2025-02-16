#!/bin/sh
GPX_CREATOR=$(basename "$0")
MAX_HEARTRATE=177
LOG_DIR=${LOG_DIR:-"./watchband"}

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

RECVALUE_HEARTRATE="0053"
RECCMD_HEARTRATE="0001"

cleanup() {
    [ -z "$SAVE_TEMPS" ] && rm -f "$@"
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

convert_hex_to_string()
# convert hex to binary string for output to file
{

    unset _hex_string
    while [ $# -gt 0 ]; do
        _hex_string="$_hex_string""\\x$1"
        shift
    done
    printf "%b" "$_hex_string"
    unset _hex_string
}

read_hex_rec() {
    RECVALUE="$1"
    RECCMD="$2"

    while read -r line; do
        # shellcheck disable=SC2046
        set --  $(echo "$line" | fold --width=2 | paste --serial --delimiter=' ')

        if [ "$RECCMD" = "$RECCMD_OUTDOOR_HEARTRATE" ] && [ "$RECVALUE" = "$RECVALUE_OUTDOOR_HEARTRATE" ]; then
            convert_hex_to_string "$@" >>"heartrate-$RECVALUE-$RECCMD-$LOG_FILE_DATE".hex
            process_heartrate "$@"
        elif [ "$RECCMD" = "$RECCMD_HEARTRATE" ] && [ "$RECVALUE" = "$RECVALUE_HEARTRATE" ]; then
            convert_hex_to_string "$@" >>"heartrate-$RECVALUE-$RECCMD-$LOG_FILE_DATE".hex
            process_heartrate "$@"
        elif [ "$RECCMD" = "$RECCMD_GPS" ] && [ "$RECVALUE" = "$RECVALUE_GPS" ]; then
            convert_hex_to_string "$@" >>gps-"$LOG_FILE_DATE".hex
            process_gps "$@"
        fi
    done
}

process_heartrate() {
   
    while [ $# -ge 8 ]; do
        timestamp=$((0x"$4$3$2$1"))
        # debug echo >&2 "timestamp: $timestamp hex: 0x$4$3$2$1"
        shift 4
        heartrate=$((0x"$4$3$2$1"))
        shift 4
        echo "{ \"timestamp\": $timestamp, \"heartrate\" : $heartrate }"
    done
}

process_gps() {

    while [ $# -ge 12 ]; do
        timestamp=$((0x"$4$3$2$1"))
        shift 4
        lon=$((0x"$4$3$2$1"))
        get_signed_number "$lon"
        lon=$SIGNED_NUMBER
        lon_float_int=$(( "$lon" / 10000000 ))
        lon_float_frac=$(( "$lon" % 10000000 ))
        lon_float="$lon_float_int.$(printf "%07d" $lon_float_frac)"
        shift 4
        lat=$((0x"$4$3$2$1"))
        get_signed_number "$lat"
        lat=$SIGNED_NUMBER
        lat_float_int=$(( "$lat" / 10000000 ))
        lat_float_frac=$(( "$lat" % 10000000 ))
        lat_float="$lat_float_int.$(printf "%07d" $lat_float_frac)"
        shift 4
        echo "{ \"timestamp\": $timestamp, \"lat\" : $lat_float, \"lon\" : $lon_float }"
    done
}

filter_log()
{
    RECVALUE="$1"
    RECCMD="$2"
    recpayload="$3"
    rec_bytecutpos="$4"

    grep -A5 "h0-RecValue：$RECVALUE RecCmd:$RECCMD" "$LOG_FILE" | tee grep-"$RECVALUE-$RECCMD-$recpayload".log | grep -i "$recpayload" | cut --bytes="$rec_bytecutpos"-
    cleanup grep-"$RECVALUE-$RECCMD-$recpayload".log
}

filter_heartrate_cmd_0001()
{
    filter_log $RECVALUE_HEARTRATE $RECCMD_HEARTRATE $RECPAYLOAD_HEARTRATE $RECBYTECUTPOS_HEARTRATE | read_hex_rec $RECVALUE_HEARTRATE $RECCMD_HEARTRATE
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
   
    cleanup heartrate-"$LOG_FILE_DATE".hex
    grep '.*WatchDataUpload-getExeciseDatas_start.*"abilityId":"'$RECVALUE_OUTDOOR_HEARTRATE'"' "$LOG_FILE" |  tee grep-heartrate-"$LOG_FILE_DATE".log | cut -b89- | jq -sr  '.[][] | select(.abilityId=="'$RECVALUE_OUTDOOR_HEARTRATE'") | .startTime+.datas' |  read_hex_rec $RECVALUE_OUTDOOR_HEARTRATE $RECCMD_OUTDOOR_HEARTRATE >heartrate-"$LOG_FILE_DATE".log

    # filter 6*5 seconds after heartrate above MAX_HEARTRATE and 6*5 seconds before
    # this filter was created to remove supurious high heartrate values
    avg_measurement_over_max_hr=6
    if [ -n "$OPTION_AVG_OVER_MAX_HR" ]; then
        cp heartrate-"$LOG_FILE_DATE".log heartrate-"$LOG_FILE_DATE"-original.log
        average_heartrate=$(jq --slurp 'map(.heartrate) | (add / length) | round' heartrate-"$LOG_FILE_DATE"-original.log )
        echo "Setting $avg_measurement_over_max_hr measurements after and before heartrate over $MAX_HEARTRATE to average $average_heartrate"
        jq --slurp --compact-output '
            reduce .[] as $item (
            {skip: 0, result: []};
                if .skip > 0 then 
                    .skip -= 1 | .result += [$item | .heartrate = '"$average_heartrate"'] 
                elif $item.heartrate > '"$MAX_HEARTRATE"' then 
                    ("Forward pass found over max hr "+( $item | tostring) | debug)  as $_ |  # Print $item to stderr
                    .result += [$item] | .skip = '"$avg_measurement_over_max_hr"'
                else 
                    .result += [$item]
                end) | .result | reverse |
            
            reduce .[] as $item (
            {skip: 0, result: []};
                if .skip > 0 then 
                    .skip -= 1 | .result += [$item | .heartrate = '"$average_heartrate"']
                elif $item.heartrate > '"$MAX_HEARTRATE"' then
                    .skip = '"$avg_measurement_over_max_hr"' | .result += [$item | .heartrate = '"$average_heartrate"']
                else 
                    .result += [$item]
                end) | .result | reverse | .[]' "heartrate-$LOG_FILE_DATE-original.log" > "heartrate-$LOG_FILE_DATE.log"
    fi
    if [ -n "$OPTION_FORCE_HEARTRATE" ]; then
        echo "Forcing heartrate to $OPTION_FORCE_HEARTRATE_VALUE"
        cp heartrate-"$LOG_FILE_DATE".log heartrate-"$LOG_FILE_DATE"-original.log
        jq --slurp --compact-output ".[].heartrate = $OPTION_FORCE_HEARTRATE_VALUE | .[]" "heartrate-$LOG_FILE_DATE-original.log" > "heartrate-$LOG_FILE_DATE.log"
    fi
    cleanup grep-heartrate-"$LOG_FILE_DATE".log heartrate-"$LOG_FILE_DATE".hex heartrate-"$LOG_FILE_DATE"-original.log
}

filter_heartrate_strava()
# seems like all heartrate data is available in dataList, so we can just grep that
{
    cleanup heartrate-"$LOG_FILE_DATE".hex
    grep -o 'dataList:.*' "$LOG_FILE" |  tee grep-heartrate-"$LOG_FILE_DATE".log | cut -b10- | jq -s '.[][] | { timestamp : .timeStamp | tonumber, heartrate: .hr }' >heartrate-"$LOG_FILE_DATE".log
    cleanup grep-heartrate-"$LOG_FILE_DATE".log heartrate-"$LOG_FILE_DATE".hex
}


filter_gps()
{
    # One line of all data (It does not contain last 8 bytes of each record/checksum?)
    # it is safer to read one line, than grepping multiple records/lines
    # also this is INFO debug level, which may not be turned off
  
    cleanup  gps-"$LOG_FILE_DATE".hex
    grep ".*l-GpsData" "$LOG_FILE" |  tee grep-gpsdata-"$LOG_FILE_DATE".log | cut -b48- | fold --width=$((24*16)) | read_hex_rec $RECVALUE_GPS $RECCMD_GPS >gps-"$LOG_FILE_DATE".log
    cleanup grep-gpsdata-"$LOG_FILE_DATE".log gps-"$LOG_FILE_DATE".hex
}

create_hoydedata_gpx()
{

    jq -s '[ .[].punkter.[] ]' hoydedata-response-"$FILENAME_POSTFIX".json >hoydedata-response-points-"$FILENAME_POSTFIX".json

    # with help from chatgpt ai
    jq -s 'transpose | map(  add| if .z < 0 then .ele = 0 else .ele = .z end | del(.x, .y, .z, .terreng, .datakilde) )'  track-hrlatlon-"$FILENAME_POSTFIX".json hoydedata-response-points-"$FILENAME_POSTFIX".json >track-hrlatlon-ele-"$FILENAME_POSTFIX".json

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
"        <time>" + (.timestamp | strftime("%Y-%m-%dT%H:%M:%SZ")) + "</time>\n" +
  (if .ele != null then
    "        <ele>" + (.ele | tostring) + "</ele>\n" 
  else "" end) +
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

  cleanup hoydedata-response-"$FILENAME_POSTFIX".json hoydedata-response-points-"$FILENAME_POSTFIX".json track-hrlatlon-"$FILENAME_POSTFIX".json track-hrlatlon-ele-"$FILENAME_POSTFIX".json
}

get_elevation_hoydedata()
{
    #group into array of arrays with 50 in each array, due to api limit
    jq -n '[inputs | . as $arr | range(0; $arr | length; 50) | $arr[.:(. + 50)]]' track-hrlatlon-"$FILENAME_POSTFIX".json >track-hrlatlon-grouped-"$FILENAME_POSTFIX".json

    # add elevation to points, create curl url config pointlist for each group for ws.geonorge.no/hoydedata/v1/punkt
    geonorge_url="https://ws.geonorge.no/hoydedata/v1/punkt"
    #geonorge_url="https://ws.geonorge.no/hoydedata/v1/datakilder/dtm1/punkt" # dtm1 is the only data source
    geonorge_EPSG="4258"
    jq -r '.[] | "url = '"$geonorge_url"'?koordsys='$geonorge_EPSG'&punkter=\\["+ ( map("\\["+(.lon|tostring)+","+(.lat|tostring)+"\\]") |  join(","))+"\\]"' track-hrlatlon-grouped-"$FILENAME_POSTFIX".json >hoydedata-pointlist-urls-"$FILENAME_POSTFIX".txt
    cleanup track-hrlatlon-grouped-"$FILENAME_POSTFIX".json
    echo "Fetching elevation data from $geonorge_url"
    curl --silent --config hoydedata-pointlist-urls-"$FILENAME_POSTFIX".txt >hoydedata-response-"$FILENAME_POSTFIX".json
}    

merge_hr_gps_gemini() {
  GROUP_BY_SECONDS=5
  # watchband logs gps and heartrate data separately each 5 seconds, so we need to merge them
  jq --slurp '
    sort_by(.timestamp) |
    group_by(.timestamp / '$GROUP_BY_SECONDS' | floor) |  # Group by n-second intervals
    map(
      if length == 1 then .[0]
      else reduce .[] as $item ({}; . * $item) # Merge objects within the group
      end
    ) |
    map(select(has("lon") and has("lat"))) | # Remove objects without lat and lon
    map(if has("heartrate") and .heartrate > '"$MAX_HEARTRATE"' then del(.heartrate) else . end) # Remove heartrate values above MAX_HEARATE
  ' heartrate-"$FILENAME_POSTFIX".log gps-"$FILENAME_POSTFIX".log > track-hrlatlon-"$FILENAME_POSTFIX".json
  _exitcode_merge_hr_gps_gemini=$?
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
    "        <time>" + (.timestamp | strftime("%Y-%m-%dT%H:%M:%SZ")) + "</time>\n" +
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

parse_sportmode_times()
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
        echo "sport_type: $sport_type start_time: $start_time $(print_utc_time "$start_time") stop_time: $stop_time $(print_utc_time "$stop_time")" >&2
       
    done <sportmode-times-"$LOG_DATE".log
    IFS="$OIFS"
    SPORTMODE_LINE_COUNTER_MAX=$SPORTMODE_LINE_COUNTER
    cleanup sportmode-times-"$LOG_DATE".log
}

check_log_file_specified() {
    if [ -z "$LOG_FILE" ]; then
        echo "No date specified. Use --date [LOG_DATE] in YYYYMMDD format."
        exit 1
    fi
}

filter_activity()
{
    check_log_file_specified

# find start and end times of gps activity
# it seems that even for multiple acitivities all gps data is in one file, this is also the case for heartrate data
# it could be possible to do automatic session splitting based on time difference between gps timestamps, since normally
# that watch stores a gps position each 5 seconds
#2025-01-30 14:10:16.036 [main] DEBUG t-sportModeValue timeResult:1738241253 support gps:01
#2025-01-30 14:10:16.037 [main] DEBUG t-sportModeValue timeResult:1738241253 sportTimes:1738242550
#                               DEBUG t-sportModeValue gpsAbsolutePath:/storage/emulated/0/Android/data/com.nothing.cmf.watch/files/GPS/1738241253_1738242550.txt

# deepseek: paste Using - - means paste will read from standard input twice, effectively combining every two lines into one
    if ! grep --context=2 't-sportModeValue timeResult.*support gps:01$' "$LOG_FILE" | grep -E "sportType|sportTimes" | paste --delimiters=" " - - >sportmode-times-"$LOG_DATE".log; then 
        echo "No GPS activities found in log file" >&2
        exit 1
    else
    echo "Found $(wc -l <sportmode-times.log) GPS activities in log file"
    fi

    # first filter hex data from log file
    # data/watchband/log_20250202.txt
    LOG_FILE_DATE=$(basename "$LOG_FILE")
    LOG_FILE_DATE=${LOG_FILE_DATE%.txt}
    LOG_FILE_DATE=${LOG_FILE_DATE#"log_"}

    filter_heartrate
    filter_gps
    parse_sportmode_times

    SPORTMODE_LINE_COUNTER=0
    while [ $SPORTMODE_LINE_COUNTER -lt "$SPORTMODE_LINE_COUNTER_MAX" ]; do
        SPORTMODE_LINE_COUNTER=$((SPORTMODE_LINE_COUNTER+1))
        FILENAME_POSTFIX=$(get_filename_postfix "$SPORTMODE_LINE_COUNTER")

        # filter heartate and gps between start and stop time
        FILENAME_POSTFIX=$(get_filename_postfix "$SPORTMODE_LINE_COUNTER")
        start_time=$(eval echo \$SPORTMODE_START_TIME_"$SPORTMODE_LINE_COUNTER")
        stop_time=$(eval echo \$SPORTMODE_STOP_TIME_"$SPORTMODE_LINE_COUNTER")
        jq 'select(.timestamp >='"$start_time"' and .timestamp <='"$stop_time"')' heartrate-"$LOG_FILE_DATE".log >heartrate-"$FILENAME_POSTFIX".log
        jq 'select(.timestamp >='"$start_time"' and .timestamp <='"$stop_time"')' gps-"$LOG_FILE_DATE".log >gps-"$FILENAME_POSTFIX".log

        if [ -n "$OPTION_NO_HEARTRATE" ]; then
            echo "Skipping heartrate data"
            rm heartrate-"$FILENAME_POSTFIX".log
            touch heartrate-"$FILENAME_POSTFIX".log
        fi

        if merge_hr_gps_gemini; then 
            create_gpx

            if [ -n "$ELEVATION_CORRECTION" ]; then
                # device does not provide elevation data, so fetch it from ws.geonorge.no/hoydedata/v1/punkt, and create gpx with elevation
            if get_elevation_hoydedata; then 
                create_hoydedata_gpx
            fi
            cleanup hoydedata-pointlist-urls-"$FILENAME_POSTFIX".txt  hoydedata-response-"$FILENAME_POSTFIX".json hoydedata-response-points-"$FILENAME_POSTFIX".json
            fi

            cleanup track-hrlatlon-"$FILENAME_POSTFIX".json
        else
            echo >&2 "Failed to merge heartrate and gps data exitcode: $?"
        fi
    done

    cleanup heartrate-"$LOG_FILE_DATE".log gps-"$LOG_FILE_DATE".log
}

convert_json_hr_to_csv()
{
    FILE_HR_CSV="${FILE_HR%.json}".csv
    echo "timestamp,heartrate" > "$FILE_HR_CSV"
    if jq -r '.[] | "\(.timestamp * 1000),\(.heartrate)"' "$FILE_HR" >> "$FILE_HR_CSV"; then 
        echo "Created $FILE_HR_CSV"
    fi
}

filter_hr_exercisedata() {
    grep "WatchDataUpload-getExeciseDatas_start\[{\"abilityId\":\"$RECVALUE_HEARTRATE\"" "$LOG_FILE" | cut -b 89- | jq -rs '.[].[] | select(.abilityId=="'$RECVALUE_HEARTRATE'") | .startTime+.datas' | 
    if read_hex_rec $RECVALUE_HEARTRATE $RECCMD_HEARTRATE | jq -s 'map({
        timestamp : .timestamp,
        timestamp_date: (.timestamp | strftime("%Y-%m-%dT%H:%M:%SZ")), # UTC date format
        heartrate : .heartrate
    })' >"$FILE_HR"; then 
        echo "Created $FILE_HR"
    fi
    
    convert_json_hr_to_csv
}

filter_hr_ble() {
     # group_by timestamp, only select first element in group, provided by gemini AI 2.0 Flash

    filter_heartrate_cmd_0001 | jq -s 'group_by(.timestamp)
    | map( 
        {
            timestamp: .[0].timestamp,
            timestamp_date: (.[0].timestamp | strftime("%Y-%m-%dT%H:%M:%SZ")), # UTC date format
            heartrate: .[-1].heartrate,   # last heart rate 
            heartrates: [.[].heartrate] # Array of all heartrates for this timestamp, should be the same hr for same timestamp
        }
    )' >"$FILE_HR"
   convert_json_hr_to_csv
}

printf "%s Tested CMF Watch Pro 2 Model D398 fw. 1.0.070 and Android CMF Watch App 3.4.3 (with debug/logging enabled), adb required for pulling log files from mobile\n" "$GPX_CREATOR"

#dont mess up git source directory with data
if [ -e ".git" ]; then 
    if [ ! -d "data" ]; then
        mkdir --verbose data data/files/watchband
    fi
    # shellcheck disable=SC2164
    cd data && echo "Running from git directory, changed to $(pwd)"
fi

# process options

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            cat <<EOF
Usage: $0 --pull --date YYYYMMDD --gpx
Converts heartrate and gps data from cmf watch app log file to gpx
Options:
   --pull                       pull watchband log files from mobile phone which contains the hex data for heartrate and gps
   --dir                        log file directory
   --date [YYYYMMDD]            specify log date to process
   --gpx                        create gpx from hr and gps data
   --hr                         get measured hr during the day in json (from exercisedata JSON)
   --hr-ble                     get measure hr during the day in json (from ble hex data records)     
   --save-tmp                   save temporary files for debugging
   --clean-tmp                  remove all temporary files
   --hoydedata                  get elevation data from ws.geonorge.no/hoydedata/v1/punkt and create track-ele.gpx
   --max-hr                     maximum heartrate value, default 177
   --no-heartrate               no heartrate data
   --avg-over-max-hr            set 6 measurements after and before hr over max hr to average
   --force-heartrate [value]    force heartrate to value
   --parse-hr-string            parses hr hex string 
   --help                       this information
EOF
            exit 0
            ;;
        --save-tmp)
            SAVE_TEMPS=true
            ;;
        --clean-tmp)
            cleanup track-hrlatlon-*.json track-hrlatlon-grouped-*.json hoydedata-*.json hoydedata-*.txt heartrate-*.log heartrate-*.hex gps-*.hex gps-*.log grep-*.log sportmode-times*.log
            ;;
        --hoydedata)
            ELEVATION_CORRECTION=true
            ;;
        --dir)
            LOG_DIR="$2"
            shift
            ;;
        --date)
            LOG_DATE="$2"
            LOG_FILE="$LOG_DIR/log_$LOG_DATE.txt"
            FILE_HR="heartrate-$LOG_DATE.json"

            if [ ! -f "$LOG_FILE" ]; then
                echo "Log file $LOG_FILE does not exist. Use --pull to fetch log files and --dir to specify directory"
                exit 1
            fi

            echo "Processing log file: $LOG_FILE cwd: $(pwd)"
            nothing_watch=$(grep --only-matching --max-count=1 "{\"deviceId\".*\"isConnect\".*}" "$LOG_FILE" | jq --raw-output '.companyName+" "+.nickname+" "+.typeName')
            if [ -n "$nothing_watch" ]; then 
                echo "$nothing_watch"
            fi
            shift
            ;;
        --pull)
            pull_watchband
            ;;
        --max-hr)
            MAX_HEARTRATE="$2"
            shift
            ;;
        --no-heartrate)
            OPTION_NO_HEARTRATE=true
            ;;
        --avg-over-max-hr)
            OPTION_AVG_OVER_MAX_HR=true
            ;;
        --force-heartrate)
            OPTION_FORCE_HEARTRATE=true
            OPTION_FORCE_HEARTRATE_VALUE="$2"
            shift
            ;;
        --gpx)
            filter_activity
            ;;            
        --parse-hr-string)
           echo "$2" | read_hex_rec $RECVALUE_HEARTRATE $RECCMD_HEARTRATE
           shift
           ;;
        --hr-ble)
            check_log_file_specified
            filter_hr_ble
            ;;
        --hr)
            check_log_file_specified
            filter_hr_exercisedata
            ;;
        *) echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
    shift
done
 