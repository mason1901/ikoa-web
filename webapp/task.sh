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

if [[ $TaskId -eq 0 ]]; then
    remainCode=$(./iKOA -E cid:118abp12345 | grep "剩余")
    echo "serialCode:${remainCode}"
    sleep 2
    NAME="$(date +"%Y-%m-%dT%H:%M:%SZ")-download_info.csv"
    echo "id,cid,taskid,status,size,bitrate,multipart,tag" >> "$NAME"
    echo "$NAME" > FILELOG.txt
    mkdir -p backup
fi
read -r fileName < FILELOG.txt
test -n "$TAG" && dirArgs="downloads/${TAG}" || dirArgs="downloads"

for i in "${!idList[@]}"; do
    sleep 2
    echo "Current id:${idList[i]} taskid:${TaskId} Current task progress:$((i + 1))/${idListLen} tag:${TAG}"
    sleep 2
    ikoaOutput=$(./iKOA -E -d "$dirArgs" "$TYPE":"${idList[i]}" | tail)
    
    if [[ $ikoaOutput =~ "已下载" ]]; then
        DownloadCount=$((DownloadCount + 1))
        bitrate=$(echo "$ikoaOutput" | grep -o '6000kbps\|3000kbps\|300kbps\|500kbps\|1000kbps\|1500kbps\|2000kbps\|4000kbps')
        multipart=$(echo "$ikoaOutput" | grep -o "部分=\[0\]" | grep -o "0" || echo 1)
        filePath=$(find "$dirArgs" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -k1 -r -n | head -1 | cut -d ' ' -f2)
        cid=$(basename "$filePath")
        fileSize=$(du -m "$filePath" | cut -f1)
        echo "${idList[i]},${cid},${TaskId},succeed,${fileSize}M,${bitrate},${multipart},${TAG}" >> "$fileName"
        echo "id:${idList[i]} cid:${cid} taskid:${TaskId} status:succeed size:${fileSize}M bitrate:${bitrate} multipart:${multipart} tag:${TAG}"
        if [[ $((DownloadCount % 4)) -eq 0 || $i -eq $((idListLen - 1)) ]]; then 
            sleep 2
            while true
            do
                rclone --config="$RcloneConf" move downloads "DRIVE:$RCLONE_DESTINATION" --drive-stop-on-upload-limit --exclude-from rclone-exclude-file.txt -v --stats-one-line --stats=1s
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
                sleep 60               
            done
        fi  
    elif [[ $ikoaOutput =~ "序列码配额不足" ]]; then
        echo "${idList[i]},,${TaskId},codenotenough,,,,${TAG}" >> "$fileName"
        echo "id:${idList[i]} taskid:${TaskId} status:serialCodeNotEnough tag:${TAG}"
    elif [[ $ikoaOutput =~ "查询无结果" ]]; then
        echo "${idList[i]},,${TaskId},notfound,,,,${TAG}" >> "$fileName"
        echo "id:${idList[i]} taskid:${TaskId} status:notfound tag:${TAG}"
    else
        echo "${idList[i]},,${TaskId},failed,,,,${TAG}" >> "$fileName"
        echo "id:${idList[i]} taskid:${TaskId} status:failed tag:${TAG}"
    fi
done

csvOutput=$(awk 'BEGIN {FS=","; OFS=":"; ORS=" "} NR > 1 { array[$4]++; number=number+1; total=total+$5; } END { printf "ID in all:%d ", number; for (i in array) print i,array[i]; total=total/1024; printf "totalDownload:%.1fG",total }' "$fileName")
taskStatus=$(ts | awk 'BEGIN {OFS=":"; ORS=" "} NR > 1 { array[$2]++;total+=1; } END { for (i in array) print i,array[i]; print "totalTask:" total }')

if [[ -e $fileName && -d backup ]]; then
    remainCode=$(./iKOA -E cid:118abp12345 | grep "剩余")
    totalTask=$(($(ts | wc -l) - 1))
    cp "$fileName" backup
    if [[ $((TaskId + 1)) -eq $totalTask ]]; then
         echo "All ${totalTask} tasks finished ===>>> ${csvOutput} serialCode:${remainCode}."
         echo "Summary ===>>> ${csvOutput} serialCode:${remainCode} totalTask:${totalTask}" >>  "./backup/${fileName}"      
    else
        echo "Until Now ===>>> ${csvOutput} serialCode:${remainCode}"
        sleep 3  
        echo "taskStatus ===>>> ${taskStatus}"
        echo "Until Now ===>>> ${csvOutput} serialCode:${remainCode}  ${taskStatus}" >>  "./backup/${fileName}"
    fi
    rclone --config="$RcloneConf" copy "./backup/${fileName}" "DRIVE:$LOG_PATH"                     
fi