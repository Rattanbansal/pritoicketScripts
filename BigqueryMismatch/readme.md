--- Query to fetch record with rn 1, 2 as per the last_modified_at

with qr_codesl as (select *,row_number() over(partition by cod_id order by last_modified_at desc ) as rn from prio_olap.qr_codes), qr_codeslrn as (select * from qr_codesl where rn in (1) and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY)) AS STRING), ' 00:00:00'))), distinctcod_id as (select distinct(cod_id) from qr_codeslrn) select * from qr_codesl where cod_id in (select cod_id from distinctcod_id) and rn in (1,2) order by cod_id desc

bq query --use_legacy_sql=False --max_rows=1000000 --format=prettyjson \
"with qr_codesl as (select *,row_number() over(partition by cod_id order by last_modified_at desc ) as rn from prio_olap.qr_codes), qr_codeslrn as (select * from qr_codesl where rn in (1) and last_modified_at > TIMESTAMP(CONCAT(CAST(DATE(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY)) AS STRING), ' 00:00:00'))), distinctcod_id as (select distinct(cod_id) from qr_codeslrn) select * from qr_codesl where cod_id in (select cod_id from distinctcod_id) and rn in (1,2) order by cod_id desc" > qr_codes_data.json

python compare_record.py qr_codes_data.json cod_id test.json