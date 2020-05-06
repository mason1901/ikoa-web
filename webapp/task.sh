#!/bin/bash

ID=$1
TYPE=$2
TaskId=$3
TAG=$4
IFS="," read -r -a idList <<< "$ID"
idListLen=${#idList[@]}
RcloneConf="rclone_1.conf"
DownloadCount=0
cd /app/fanza || exit
codeQuota=$(./iKOA -E cid:118abp12345 | grep -oP '(?<=剩余\s)[0-9]+(?=\s次)')

if [[ $codeQuota -gt 0 ]]; then
    echo "序列码额度剩余 ${codeQuota} 次"
else
    echo "序列码额度为0，不能下载!"
    exit 1
fi

updateWaitTime() {
    if [[ $codeQuota -ge 1 && $codeQuota -lt 10 ]]; then
        waitTime=3600
    elif [[ $codeQuota -ge 10 && $codeQuota -lt 45 ]]; then
        waitTime=1800
    elif [[ $codeQuota -ge 45 && $codeQuota -lt 90 ]]; then
        waitTime=300
    elif [[ $codeQuota -ge 90 ]]; then
        waitTime=0
    else
        echo "序列码额度为0，不能下载!"
        exit 1
    fi
}

sleepHandler() {
    local elapsedTime
    updateWaitTime
    test -e TIME_VAR.txt && read -r elapsedTime < TIME_VAR.txt || elapsedTime=0
    if [[ $elapsedTime -le $waitTime && $elapsedTime -ne 0 ]]; then
        local sleepTime=$((waitTime - elapsedTime))
        while [[ $sleepTime -ge 0 ]]; do
            printf '请求过快，需要等待 %02dh:%02dm:%02ds\n' $((sleepTime/3600)) $((sleepTime%3600/60)) $((sleepTime%60))
            sleepTime=$((sleepTime - 1))
            sleep 1
        done
    fi
}

if [[ $TaskId -eq 0 ]]; then
    NAME="$(date +"%Y-%m-%dT%H:%M:%SZ")-download_info.csv"
    echo "id,cid,taskid,status,size,bitrate,multipart,tag,monthly" >> "$NAME"
    echo "$NAME" > FILENAME_VAR.txt
    mkdir -p backup
fi
test -e FILENAME_VAR.txt && read -r fileName < FILENAME_VAR.txt || exit 1
test -n "$TAG" && dirArgs="downloads/${TAG}" || dirArgs="downloads"

for i in "${!idList[@]}"; do
    FLAG=0
    sleep 2
    isMonthly=$(curl -sL --retry 5 "https://v2.mahuateng.cf/isMonthly/${idList[i]}" | grep -oP '(?<=\"monthly\":)(true|false)(?=\,)' || echo "queryfailed")
    echo "Current id:${idList[i]} taskid:${TaskId} Current task progress:$((i + 1))/${idListLen} tag:${TAG:-None} Monthly:${isMonthly}"
    sleep 1
    if [[ $isMonthly == "true" ]]; then
        sleepHandler
        startTime=$SECONDS
        ikoaOutput=$(./iKOA -E -d "$dirArgs" "$TYPE":"${idList[i]}" | tail)
    elif [[ $isMonthly == "false" ]]; then
        if [[ $MONTHLY_ONLY_BOOL == "true" ]]; then
            echo "id:${idList[i]} taskid:${TaskId} status:pass tag:${TAG:-None} Monthly:${isMonthly}"
            echo "${idList[i]},,${TaskId},pass,,,,${TAG},${isMonthly}" >> "$fileName"
            continue
        else
            sleepHandler
            startTime=$SECONDS
            ikoaOutput=$(./iKOA -E -d "$dirArgs" "$TYPE":"${idList[i]}" | tail)
            FLAG=1         
        fi
    else
        echo "id:${idList[i]} taskid:${TaskId} status:pass tag:${TAG:-None} Monthly:${isMonthly}"
        echo "${idList[i]},,${TaskId},pass,,,,${TAG},${isMonthly}" >> "$fileName"
        continue
    fi
      
    if [[ $ikoaOutput =~ "已下载" ]]; then
        DownloadCount=$((DownloadCount + 1))
        bitrate=$(echo "$ikoaOutput" | grep -oE '[0-9]+kbps')
        multipart=$(echo "$ikoaOutput" | grep -oP '(?<=部分=\[)[0-9]+(,[0-9]+)*(?=\])' | awk 'BEGIN {FS=","} {print $NF}')
        if [[ $FLAG -eq 1 ]]; then
            if [[ $multipart -eq 0 || $MERGE_BOOL == "true" ]]; then
                codeQuota=$((codeQuota - 1))
            else
                codeQuota=$((codeQuota - multipart))
            fi
        fi
        filePath=$(find "$dirArgs" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -k1 -r -n | head -1 | cut -d ' ' -f2)
        cid=$(basename "$filePath")
        fileSize=$(du -m "$filePath" | cut -f1)
        echo "${idList[i]},${cid},${TaskId},succeed,${fileSize}M,${bitrate},${multipart},${TAG},${isMonthly}" >> "$fileName"
        echo "id:${idList[i]} cid:${cid} taskid:${TaskId} status:succeed size:${fileSize}M bitrate:${bitrate} multipart:${multipart} tag:${TAG:-None} Monthly:${isMonthly}"   
        if [[ $((DownloadCount % 4)) -eq 0 || $i -eq $((idListLen - 1)) || $codeQuota -lt 45 ]]; then 
            sleep 2
            while true
            do
                rclone --config="$RcloneConf" move downloads "DRIVE:$RCLONE_DESTINATION" --drive-stop-on-upload-limit --drive-chunk-size 64M --exclude-from rclone-exclude-file.txt -v --stats-one-line --stats=1s
                rc=$?
                if [[ $rc -ne 7 ]]; then
                    break
                else
                    if [[ $RcloneConf == "rclone_1.conf" ]]; then
                        RcloneConf="rclone_2.conf"
                    else
                        RcloneConf="rclone_1.conf"
                    fi
                fi
                sleep 10
            done
        fi    
        elapsed=$((SECONDS - startTime))
        echo "$elapsed" > TIME_VAR.txt
    elif [[ $ikoaOutput =~ "序列码额度为0" ]]; then
        echo "序列码额度为0，不能下载!"
        break
    elif [[ $ikoaOutput =~ "查询无结果" ]]; then
        echo "${idList[i]},,${TaskId},notfound,,,,${TAG},${isMonthly}" >> "$fileName"
        echo "id:${idList[i]} taskid:${TaskId} status:notfound tag:${TAG:-None} Monthly:${isMonthly}"
        elapsed=0
        echo "$elapsed" > TIME_VAR.txt
    else
        test $FLAG -eq 1 && codeQuota=$((codeQuota - 1))
        echo "${idList[i]},,${TaskId},failed,,,,${TAG},${isMonthly}" >> "$fileName"
        echo "id:${idList[i]} taskid:${TaskId} status:failed tag:${TAG:-None} Monthly:${isMonthly}"
        elapsed=$((SECONDS - startTime))
        echo "$elapsed" > TIME_VAR.txt
    fi
done

csvOutput=$(awk 'BEGIN {FS=","; OFS=":"; ORS=" "} NR > 1 { array[$4]++; number=number+1; total=total+$5; } END { printf "ID in all:%d ", number; for (i in array) print i,array[i]; total=total/1024; printf "totalDownload:%.1fG",total }' "$fileName")
taskStatus=$(ts | awk 'BEGIN {OFS=":"; ORS=" "} NR > 1 { array[$2]++;total+=1; } END { for (i in array) print i,array[i]; print "totalTask:" total }')

if [[ -e $fileName && -d backup ]]; then
    totalTask=$(($(ts | wc -l) - 1))
    cp "$fileName" backup
    if [[ $((TaskId + 1)) -eq $totalTask ]]; then
         echo "All ${totalTask} tasks finished ===>>> ${csvOutput} 序列码额度剩余 ${codeQuota} 次"
         echo "Summary ===>>> ${csvOutput} 序列码额度剩余 ${codeQuota} 次 totalTask:${totalTask}" >>  "./backup/${fileName}"      
    else
        echo "Until Now ===>>> ${csvOutput} 序列码额度剩余 ${codeQuota} 次"
        sleep 3  
        echo "taskStatus ===>>> ${taskStatus}"
        echo "Until Now ===>>> ${csvOutput} 序列码额度剩余 ${codeQuota} 次 ${taskStatus}" >>  "./backup/${fileName}"
    fi
    rclone --config="$RcloneConf" copy "./backup/${fileName}" "DRIVE:$LOG_PATH"                     
fi