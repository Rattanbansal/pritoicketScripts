SELECT start_from,end_to,season_start_date,season_end_date,timezone,UNIX_TIMESTAMP(DATE_ADD(from_unixtime(season_start_date, '%Y-%m-%d %H:%i:%s'), INTERVAL timezone HOUR)) as new_start_date,TIME_FORMAT(ADDTIME(end_to,CONCAT(timezone,':00')),"%H:%i:%s") as new_time FROM `standardticketopeninghours` WHERE shared_capacity_id = "16513" and season_start_date = "1675206000"
 
SELECT end_to, timezone,TIME_FORMAT(ADDTIME(end_to,replace(CONCAT(timezone,':00:00'), '+', '')),"%H:%i:%s") as new_time,replace(CONCAT(timezone,':00:00'), '+', '') as new  FROM `standardticketopeninghours` where shared_capacity_id = "20322"
 
SELECT start_from,end_to,season_start_date,season_end_date,timezone,UNIX_TIMESTAMP(DATE_ADD(from_unixtime(season_start_date, '%Y-%m-%d %H:%i:%s'), INTERVAL timezone HOUR)) as new_start_date,TIME_FORMAT(ADDTIME(end_to,replace(CONCAT(timezone,':00:00'), '+', '')),"%H:%i:%s") as new_time FROM `standardticketopeninghours` WHERE shared_capacity_id = "16513" and season_start_date = "1675206000"
 
explain update standardticketopeninghours set season_start_date = UNIX_TIMESTAMP(DATE_ADD(from_unixtime(season_start_date, '%Y-%m-%d %H:%i:%s'), INTERVAL timezone HOUR)), season_end_date = UNIX_TIMESTAMP(DATE_ADD(from_unixtime(season_end_date, '%Y-%m-%d %H:%i:%s'), INTERVAL timezone HOUR)),start_from = TIME_FORMAT(ADDTIME(replace(start_from,'-',''),replace(CONCAT(timezone,':00:00'), '+', '')),"%H:%i:%s"), end_to = TIME_FORMAT(ADDTIME(replace(end_to,'-',''),replace(CONCAT(timezone,':00:00'), '+', '')),"%H:%i:%s") WHERE shared_capacity_id = "16513" and season_start_date = "1675206000"
 
-------------------steps--------------
 
explain update standardticketopeninghours set season_start_date = UNIX_TIMESTAMP(DATE_ADD(from_unixtime(season_start_date, '%Y-%m-%d %H:%i:%s'), INTERVAL timezone HOUR)), season_end_date = UNIX_TIMESTAMP(DATE_ADD(from_unixtime(season_end_date, '%Y-%m-%d %H:%i:%s'), INTERVAL timezone HOUR)),start_from = TIME_FORMAT(ADDTIME(replace(start_from,'-',''),replace(CONCAT(timezone,':00:00'), '+', '')),"%H:%i:%s"), end_to = TIME_FORMAT(ADDTIME(replace(end_to,'-',''),replace(CONCAT(timezone,':00:00'), '+', '')),"%H:%i:%s") WHERE shared_capacity_id = "16513" and season_start_date = "1675206000"
 
update standardticketopeninghours set timezone = "0" WHERE shared_capacity_id = "16513" and season_start_date = "1675206000"
 
 
 
 
https://docs.google.com/spreadsheets/d/134NHLmcmwOByMoioZXQU2hSF-yaSFnClCNVfrRtqsHA/edit#gid=0.
Google Sheets: Sign-in
Access Google Sheets with a personal Google account or Google Workspace account (for business use).
 
SELECT from_unixtime(max(createdOn)), from_unixtime(min(createdOn)) FROM `hotel_ticket_overview` where last_modified_at >= date_sub(CURRENT_TIMESTAMP, interval 31 day);
 
SELECT from_unixtime(max(createdOn)), from_unixtime(min(createdOn)), max(last_modified_at) as max_last_modified_at, min(last_modified_at) as min_last_modified_at FROM `hotel_ticket_overview` where last_modified_at >= date_sub(CURRENT_TIMESTAMP, interval 31 day);
 

select * from (SELECT mec.mec_id, replace(mec.timezone,'+', '') as timezone, tps.ticket_id, replace(tps.timezone, '+','') as tpstimezone FROM modeventcontent mec join ticketpriceschedule tps on mec.mec_id = tps.ticket_id where mec.deleted = '0' and tps.deleted = '0') as base where ABS(timezone-tpstimezone) > '0.03' 