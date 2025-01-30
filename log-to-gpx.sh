#!/bin/sh

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

print_utc_time()
# $1 timestamp
{
   date --utc -d @"$1" +"%Y-%m-%dT%H:%M:%SZ"
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
                timestamp=$(printf "%d" 0x"$4$3$2$1")
                timestamp_date=$(print_utc_time "$timestamp")
                shift 4
                #echo read heartrate: "$1 $2 $3 $4"
                heartrate=$(printf "%d" 0x"$4$3$2$1")
                shift 4
                #echo "$timestamp_date $heartrate" >&2
                echo "{ \"timestamp\": $timestamp, \"timestamp_date\": \"$timestamp_date\", \"heartrate\" : $heartrate }" 
            elif [ "$reccmd" = "$RECCMD_GPS" ] && [ "$recvalue" = "$RECVALUE_GPS" ]; then
                # gps track
                #echo gps read timestamp: "$1 $2 $3 $4"
                timestamp=$(printf "%d" 0x"$4$3$2$1")
                timestamp_date=$(print_utc_time "$timestamp")
                shift 4
                #echo "gps read lon: $1 $2 $3 $4"
                lon=$(printf "%d" 0x"$4$3$2$1")
                lon_float=$(echo "scale=7; $lon / 10000000" | bc)
                shift 4
                #echo "gps read lat: $1 $2 $3 $4"
                lat=$(printf "%d" 0x"$4$3$2$1")
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
    [ -n "$DELETE_FILES" ] && rm grep-"$recpayload".log
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
    grep ".*WatchDataUpload-getExeciseDatas_start" "$log_file"| tee grep-heartrate.log | cut -b89- | jq -sr '.[][] | select(.abilityId=="00e0") | .startTime+.datas' |  read_hex_rec $RECVALUE_OUTDOOR_HEARTRATE $RECCMD_OUTDOOR_HEARTRATE
    [ -n "$DELETE_FILES" ] && rm grep-heartrate.log
}

filter_gps()
{
    # One line of all data (It does not contain last 8 bytes of each record/checksum?)
    # it is safer to read one line, than grepping multiple records/lines
    # also this is INFO debug level, which may not be turned off
    grep ".*l-GpsData" "$log_file" | tee grep-gpsdata.log | cut -b48- | fold --width=$((24*16)) | read_hex_rec $RECVALUE_GPS $RECCMD_GPS 
    [ -n "$DELETE_FILES" ] && rm grep-gpsdata.log
}
create_hoydedata_gpx()
{

    jq -s '[ .[].punkter.[] ]' curl-hoydedata-response.json >curl-hoydedata-response-points.json

    # with help from chatgpt ai
    jq -s 'transpose | map(add | del(.x, .y, .datakilde, .terreng) | .ele = .z | del(.z))'  merged-hrlatlon.json curl-hoydedata-response-points.json >merged-hrlatlon-ele.json

    if jq --raw-output '
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
"<gpx version=\"1.1\" creator=\"jq\" xmlns=\"http://www.topografix.com/GPX/1/1\" xmlns:gpxtpx=\"http://www.garmin.com/xmlschemas/TrackPointExtension/v1\">\n" +
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
"        <extensions>\n" +
"          <gpxtpx:TrackPointExtension >\n" +
"            <gpxtpx:hr>" + (.heartrate | tostring) + "</gpxtpx:hr>\n" +
"          </gpxtpx:TrackPointExtension>\n" +
"        </extensions>\n" +
"      </trkpt>"
) | join("\n") ) +
"    </trkseg>\n" +
"  </trk>\n" +
"</gpx>\n"
' merged-hrlatlon-ele.json >merged-ele.gpx; then 
    echo "Created merged-ele.gpx"
    else
        echo "Failed to create merged-ele.gpx"
    fi

  [ -n "$DELETE_FILES" ] && rm curl-hoydedata-response.json curl-hoydedata-response-points.json merged-hrlatlon.json merged-hrlatlon-ele.json
}

get_elevation_hoydedata()
{
    #group into array of arrays with 50 in each array, due to api limit
    jq -n '[inputs | . as $arr | range(0; $arr | length; 50) | $arr[.:(. + 50)]]' merged-hrlatlon.json >merged-hrlatlon-grouped.json

    # add elevation to points, create curl url config pointlist for each group for ws.geonorge.no/hoydedata/v1/punkt
    jq -r '.[] | "url = https://ws.geonorge.no/hoydedata/v1/punkt?koordsys=4258&punkter=\\["+ ( map("\\["+(.lon|tostring)+","+(.lat|tostring)+"\\]") |  join(","))+"\\]"' merged-hrlatlon-grouped.json >curl-hoydedata-pointlist-urls.txt
    [ -n "$DELETE_FILES" ] && rm merged-hrlatlon-grouped.json
    echo "Fetching elevation data from ws.geonorge.no/hoydedata/v1/punkt"
    curl --silent --config curl-hoydedata-pointlist-urls.txt >curl-hoydedata-response.json
}    

merge_hr_gps()
{

    # Merge and sort by timestamp
    jq --slurp 'sort_by(.timestamp)' heartrate.log gps.log > merged_sorted.json

    # Deduplicate or merge entries with close timestamps
    jq '[reduce .[] as $entry (
        [];
        if (. | map(select((.timestamp - $entry.timestamp | abs) <= 2)) | length) == 0 then
            . + [$entry]
        else
            map(if (.timestamp - $entry.timestamp | abs) <= 2 then . * $entry else . end)
        end
    )] | .[]' merged_sorted.json > merged.json

    # Remove objecs without heartrate,lat and lon

    jq '[.[] | select(has("heartrate") and has("lon") and has("lat"))]' merged.json > merged-hrlatlon.json
    [ -n "$DELETE_FILES" ] && rm heartrate.log gps.log merged_sorted.json merged.json
}

create_gpx()
{
    if jq --raw-output '
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<gpx version=\"1.1\" creator=\"jq\" xmlns=\"http://www.topografix.com/GPX/1/1\" xmlns:gpxtpx=\"http://www.garmin.com/xmlschemas/TrackPointExtension/v1\">\n" +
    "  <trk>\n" +
    "    <trkseg>\n" +
    (. | map(
    "      <trkpt lat=\"" + 
    (.lat | tostring) + 
    "\" lon=\"" + 
    (.lon | tostring) + 
    "\">\n" +
    "        <time>" + .timestamp_date + "</time>\n" +
    "        <extensions>\n" +
    "          <gpxtpx:TrackPointExtension >\n" +
    "            <gpxtpx:hr>" + (.heartrate | tostring) + "</gpxtpx:hr>\n" +
    "          </gpxtpx:TrackPointExtension>\n" +
    "        </extensions>\n" +
    "      </trkpt>"
    ) | join("\n") ) +
    "    </trkseg>\n" +
    "  </trk>\n" +
    "</gpx>\n"
    ' merged-hrlatlon.json >merged.gpx; then 
         echo "Created merged.gpx"
    else
        echo "Failed to create merged.gpx"
        return 1
    fi
}

pull_watchband()
{
    #  Check if adb is installed
    if ! command -v adb 1>/dev/null 2>/dev/null; then
        echo "adb could not be found, please install it first."
        exit 1
    fi

    # Check if a device is connected
    if adb get-state 1>/dev/null 2>&1; then
        echo "Pulling log files from /storage/emulated/0/Android/data/com.nothing.cmf.watch/files/watchband/ "
        adb pull /storage/emulated/0/Android/data/com.nothing.cmf.watch/files/watchband/ .
    else
        echo "No device is connected. Log files not pulled from /storage/emulated/0/Android/data/com.nothing.cmf.watch/files/watchband/ "
    fi
}

filter_hr_gps()
{
    # show first 10 lines of filtered data to see time difference between heartrate and gps start time
    filter_heartrate >heartrate.log
    echo "Head of filtering heartrate:" && head heartrate.log
    filter_gps >gps.log
    # watch probably starts gps logging before heartrate logging, also timestamps may differ between the two
    echo "Head of filtering gps:" && head -n 20 gps.log 
   
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
   --hoydedata         get elevation data from ws.geonorge.no/hoydedata/v1/punkt and create merged-ele.gpx
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



# first filter hex data from log file
filter_hr_gps

# then merge and sort by timestamp
merge_hr_gps

# finally create gpx file
create_gpx

if [ -n "$ELEVATION_CORRECTION" ]; then
    # device does not provide elevation data, so fetch it from ws.geonorge.no/hoydedata/v1/punkt, and create gpx with elevation
   if get_elevation_hoydedata; then 
        create_hoydedata_gpx
   fi
   [ -n "$DELETE_FILES" ] && rm curl-hoydedata-pointlist-urls.txt  curl-hoydedata-response.json curl-hoydedata-response-points.json
fi

[ -n "$DELETE_FILES" ] && rm merged-hrlatlon.json





