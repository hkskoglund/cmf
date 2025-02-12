# CMF Watch log to gpx

Converts hex heartrate and GPS data from CMF watch app log file to GPX file.

### Options:
```
    --pull                       Pull watchband log files from mobile phone which contains the hex data for heartrate and GPS.
    --file [log_file]            Specify log file to process.
    --save-temps                 Save temporary files for debugging.
    --hoydedata                  Get elevation data from ws.geonorge.no/hoydedata/v1/punkt and create track-ele.gpx.
    --max-hr                     Maximum heartrate value, default 177.
    --no-heartrate               No heartrate data.
    --avg-over-max-hr            Set 6 measurements after and before HR over max HR to average.
    --force-heartrate [value]    Force heartrate to value.
    --help                       Display help information.
```

## Installation

- Enable USB debugging/developer mode on Android
- Sync CMF Watch app with the watch
- Connect USB cable to PC

## Example

 ./log-gpx.sh  --pull --file ./watchband/log_20250211.txt

## Output
```
log-gpx.sh tested only on CMF Watch Pro 2 Model D398 firmware 1.0.070 and Android CMF Watch App 3.4.3 (with debug/logging enabled), adb required for pulling log files from mobile.
Processing log file: /home/henning/github/cmf/data/watchband/log_20250211.txt cwd: /home/henning/github/cmf/data
Nothing CMF WATCH_05 D398
Found 1 GPS activities in log file
Setting 6 measurements after and before heartrate over 168 to average 124
sport_type: 2 1739270318: 1739270318 2025-02-11T10:38:38Z stop_time: 1739273781 2025-02-11T11:36:21Z
Created track-20250211_103838.gpx
Fetching elevation data from https://ws.geonorge.no/hoydedata/v1/punkt
Created track-ele-20250211_103838.gpx
```