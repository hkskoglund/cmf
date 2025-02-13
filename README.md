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

 ./log-gpx.sh  --pull --file ./watchband/log_20250212.txt

## Output
```
log-gpx.sh Testet only on CMF Watch Pro 2 Model D398 firmware 1.0.070 and Android CMF Watch App 3.4.3 (with debug/logging enabled), adb required for pulling log files from mobile
Running from git directory, changed to /home/henning/github/cmf/data
Pulling log files from /storage/emulated/0/Android/data/com.nothing.cmf.watch/files/watchband/ 
/storage/emulated/0/Android/data/com.nothing.cmf.watch/files/watchband/: 6 files pulled, 0 skipped. 33.9 MB/s (50428420 bytes in 1.421s)
Processing log file: /home/henning/github/cmf/data/watchband/log_20250212.txt cwd: /home/henning/github/cmf/data
Nothing CMF WATCH_05 D398
Found 1 GPS activities in log file
sport_type: 2 start_time: 1739353024 2025-02-12T09:37:04Z stop_time: 1739356642 2025-02-12T10:37:22Z
Created track-20250212_093704.gpx
```