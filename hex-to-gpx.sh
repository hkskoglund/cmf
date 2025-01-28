#!/bin/sh

# log file in ./files/watchband directory on device
# requires: data must be downloaded from the watchband by the app
# and the log file must be available in the ./files/watchband directory

# heartrate and timestamp is also available as json in
# 2025-01-26 11:13:51.571 [mqt_native_modules] DEBUG WatchDataUpload-getExeciseDatas_start
# gps hex data from http:
# https://d3ggmty0576dru.cloudfront.net/watch_band/1707307855859793920/outdoor_running/outdoor_running_20250126092101.txt?Expires=1737909066&Signature=ffXFhYhuMx-jvGdgUVX5Zv6X5AaO2-Zw9V36dUVdUspNjHJxj0hHg--eBVJhvakXUK94lLCXR0sjTUIHGlM3NYmJ5THneZ9xSqmHu2xwPiJYX75emEu8qWhRE1OYdr6uR4hc55T4xXxHI4bWmLiXcOzmsF6k8xMcmlWs4tV-GgIPTFcCvm7G-3CE-CHUDLlEVqak4i5-Ze~MwRd7Os0vPzTpMl9ANDl8rYJfeQmEdv1Enc9UIlda~ETcrep1pgBgya8Re5LhEE6TdPCUzTIK2pDFXUuRk4gDzz7Tnsk1mQW4WBAhME0rVHs1a1Ehlc-tOg4nRaf6AoxOQjEmoG2tnA__&Key-Pair-Id=K3V0FUNXST87Q
# https://d3ggmty0576dru.cloudfront.net/watch_band/1707307855859793920/outdoor_running/outdoor_running_20250124115220.txt?Expires=1737909543&Signature=o80gOkUGpElSiJxCbejBrBEAVAe-7BMZ1B1Hs-DxPb~T~JWTC8o9szC5psziuC-Fx9Qm-Q2OFJnZYo0gGqWgf4pEtJ1r5rfizYM4frh28p8xxI5FTZiaxQxYLkGz5hxrgbiwY0jivbydHS7WMp18Ti3Q3vtBmJvzzZSL~kYc1C6NazZPwsteQoLfvzuZkG3kwNA~cf1-j3PDl3CpO0zs8NeU7c7i-OsVYWDg69RupwR8c9v3nuqPDntVwGMbSvVBHJd34WcQHcuzuj7doOVN0oin8jX9gy4Ijr1U4yfM-HJmDjmoKmf37wbNc90mqFLMBKDiTyWpe9GW-SxXYZgp5g__&Key-Pair-Id=K3V0FUNXST87Q


log_file=${1:-./files/watchband/log_20250127.txt}

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
{
    recvalue="$1"
    reccmd="$2"

    #echo "reccmd: $reccmd recvalue: $recvalue"

    while read -r line; do
        echo "read: $line" >&2
        #shellcheck disable=SC2046
        set --  $(echo "$line" | fold --width=2 | paste --serial --delimiter=' ')
        while [ $# -gt 8 ]; do

            if [ "$reccmd" = "$RECCMD_OUTDOOR_HEARTRATE" ] && [ "$recvalue" = "$RECVALUE_OUTDOOR_HEARTRATE" ]; then
                #echo read timestamp: "$1 $2 $3 $4"
                timestamp=$(printf "%d" 0x"$4$3$2$1")
                timestamp_date=$(print_utc_time "$timestamp")
                shift 4
                #echo read heartrate: "$1 $2 $3 $4"
                heartrate=$(printf "%d" 0x"$4$3$2$1")
                shift 4
                echo "$timestamp_date $heartrate" >&2
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
                #echo "$timestamp_date $lat $lon"
                echo "{ \"timestamp\": $timestamp, \"timestamp_date\": \"$timestamp_date\", \"lat\" : $lat_float, \"lon\" : $lon_float }" 

            fi
        
        done

        # echo "remaining checksum?: $*"

    done
}

filter_log()
{
    recvalue="$1"
    reccmd="$2"
    recpayload="$3"
    rec_bytecutpos="$4"

    grep -A4 "h0-RecValue：$recvalue RecCmd:$reccmd" "$log_file" | tee grep-"$recpayload".log | grep -i "$recpayload" | cut --bytes="$rec_bytecutpos"-
}

filter_heartrate()
{
    filter_log $RECVALUE_OUTDOOR_HEARTRATE $RECCMD_OUTDOOR_HEARTRATE $RECPAYLOAD_HEARTRATE $RECBYTECUTPOS_HEARTRATE | read_hex_rec $RECVALUE_OUTDOOR_HEARTRATE $RECCMD_OUTDOOR_HEARTRATE
}

filter_gps()
{
    filter_log $RECVALUE_GPS $RECCMD_GPS "$RECPAYLOAD_GPS" "$RECBYTECUTPOS_GPS" | read_hex_rec $RECVALUE_GPS $RECCMD_GPS
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
}

filter_heartrate >heartrate.log
filter_gps >gps.log
#jq --slurp 'sort_by(.timestamp)' heartrate.log gps.log >merged_sorted.json
#jq '[. as $in | 
#    reduce range(0; length) as $i (
#        [];
#        if (. | map(select((.timestamp - $in[$i].timestamp | abs) <= 2)) | length) == 0 then
#            . + [$in[$i]]
#        else
#            map(if (.timestamp - $in[$i].timestamp | abs) <= 2 then 
#                . * $in[$i] 
#            else 
##                . 
 #           end)
#        end
#    )]' merged_sorted.json >merged.json

# guided by code from chatgpt

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

#jq '.[] | select(has("heartrate") and has("lon") and has ("lat")) ' merged.json >merged-hrlatlon.json
jq '[.[] | select(has("heartrate") and has("lon") and has("lat"))]' merged.json > merged-hrlatlon.json

jq --raw-output '
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
' merged-hrlatlon.json >merged.gpx


#group into array of arrays with 50 in each array
jq -n '[inputs | . as $arr | range(0; $arr | length; 50) | $arr[.:(. + 50)]]' merged-hrlatlon.json >merged-hrlatlon-grouped.json

# add elevation to points, create curl url config pointlist for each group for ws.geonorge.no/hoydedata/v1/punkt
jq -r '.[] | "url = https://ws.geonorge.no/hoydedata/v1/punkt?koordsys=4258&punkter=\\["+ ( map("\\["+(.lon|tostring)+","+(.lat|tostring)+"\\]") |  join(","))+"\\]"' merged-hrlatlon-grouped.json >curl-hoydedata-pointlist-urls.txt
echo "Fetching elevation data from ws.geonorge.no/hoydedata/v1/punkt"
if curl --silent --config curl-hoydedata-pointlist-urls.txt >curl-hoydedata-response.json; then 
    create_hoydedata_gpx
fi

rm merged-hrlatlon-grouped.json merged-hrlatlon.json merged_sorted.json merged.json merged-hrlatlon-ele.json heartrate.log gps.log grep-heartvalueplayload.log grep-gpsplayload.log curl-hoydedata-pointlist-urls.txt curl-hoydedata-response.json curl-hoydedata-response-points.json curl-hoydedata-pointlist-urls.txt




