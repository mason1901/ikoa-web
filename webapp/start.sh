#!/bin/bash


if [[ -n $TEAM_DRIVE_ID && -n $RCLONE_DESTINATION && -n $LOG_PATH && -n $SA_JSON_1 && -n $SA_JSON_2 && -n $SERIAL_CODE && -n $MERGE_BOOL ]]; then
    sed -i "/^serial/c\serial = \'$SERIAL_CODE\'" /app/fanza/config.toml   
    echo "team_drive = $TEAM_DRIVE_ID" >> /app/fanza/rclone_1.conf
    echo "team_drive = $TEAM_DRIVE_ID" >> /app/fanza/rclone_2.conf
    echo "$SA_JSON_1" > /app/fanza/service_account_1.json
    echo "$SA_JSON_2" > /app/fanza/service_account_2.json
    if [[ $MERGE_BOOL == "false" ]]; then
        sed -i -e "/^merge/c\merge = false" -e "/^m3u_merge/c\m3u_merge = false" /app/fanza/config.toml
    fi
    if [[ $OUTPUT_FILENAME == "pid" || $OUTPUT_FILENAME == "num" ]]; then
        sed -i "/^filename/c\filename = \'$OUTPUT_FILENAME\'" /app/fanza/config.toml  
    fi
else
    echo "Warning: Please make sure there exist all of the needed config vars!"
    exit 1
fi





# $PORT is set by Heroku            
gunicorn --worker-class eventlet -w 1 -c gunicorn.conf.py --bind 0.0.0.0:"$PORT" wsgi --preload