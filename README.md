# CMF Watch log to gpx

Converts heartrate and gps data from cmf watch app log file to gpx

### Options:
```
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
    --pick-every-nth             pick every nth heartrate/gps point for merging
    --help                       this information
```

## Installation

- Enable USB debugging/developer mode on Android
- Sync CMF Watch app with the watch
- Connect USB cable to PC

## Example

 ./log-gpx.sh  --pull --date 20250212 --gpx

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