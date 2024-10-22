#!/bin/bash

# Define variables
SOURCE_DB_HOST='rattan-test-primary-db.ck6w2al7sgpk.eu-west-1.rds.amazonaws.com'
SOURCE_DB_USER='prt_dbadmin'
SOURCE_DB_PASSWORD='YI7g3zXYLaRLf06HTX2s'
SOURCE_DB_NAME='priopassdb'

# SOURCE_DB_HOST='10.10.10.19'
# SOURCE_DB_USER='pip'
# SOURCE_DB_PASSWORD='pip2024##'
# SOURCE_DB_NAME='priopassdb'


for mec_id in $(mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -N -e "select distinct(ticket_id) from template_level_tickets where template_id in (select distinct(template_id) from qr_codes where reseller_id = '686' and cashier_type = '1') and deleted = '0'"); do

echo $mec_id >> rattan.txt


querystring="select mec_id,cat_id,hotel_id,museum_id,product_type,company,rezgo_ticket_id,rezgo_id,'lll' as rezgo_key,tourcms_tour_id,tourcms_channel_id,tax_value, service_cost,latest_sold_date, shortDesc,eventImage,ticketwithdifferentpricing,saveamount,ticketPrice,pricetext,ticket_net_price,newPrice,totalticketPrice,new_discount_price,is_reservation,agefrom,ageto,ticketType,is_combi_ticket_allowed,is_booking_combi_ticket_allowed,start_date,end_date,extra_text_field,deleted,is_updated,third_party_id,third_party_ticket_id,third_party_parameters from(select pos.mec_id as base_id,base2.ticket_id as mec_id,base2.cat_id as cat_id,base2.cod_id as hotel_id,base2.supplier_id as museum_id,base2.product_type as product_type,base2.company as company,'0' as rezgo_ticket_id, '0' as rezgo_id, '0' as rezgo_key,'0' as tourcms_tour_id, '0' as tourcms_channel_id,base2.tax_value as tax_value, '0' as service_cost, '2021-06-19' as latest_sold_date,base2.shortDesc as shortDesc,base2.eventImage as eventImage, '1' as ticketwithdifferentpricing,base2.saveamount as saveamount,base2.ticketPrice as ticketPrice,base2.pricetext as pricetext,base2.ticket_net_price as ticket_net_price,base2.newPrice as newPrice,base2.totalticketPrice as totalticketPrice,base2.new_discount_price as new_discount_price,base2.is_reservation as is_reservation,base2.agefrom as agefrom,base2.ageto as ageto,base2.ticketType as ticketType, '0' as is_combi_ticket_allowed, '0' as is_booking_combi_ticket_allowed,base2.start_date as start_date,base2.end_date as end_date, '0' as extra_text_field, '0' as deleted, '0' as is_updated,base2.third_party_id as third_party_id,base2.third_party_ticket_id as third_party_ticket_id,base2.third_party_parameters as third_party_parameters from (SELECT current_date() as date,date(from_unixtime(tps.start_date)) as tps_start_date, date(from_unixtime(if(tps.end_date like '%9999%', '1750343264', tps.end_date))) as tps_end_time, tps.ticket_id as tps_ticket_id, tps.default_listing,qc.cod_id, qc.template_id as company_template_id, tlt.template_id, tlt.ticket_id, mec.cat_id, mec.sub_cat_id, mec.cod_id as supplier_id, (case when mec.is_combi in ('2','3') then mec.is_combi else 0 end) as product_type, mec.museum_name as company, qc.country_code as country_code, qc.country as country,tps.ticket_tax_value as tax_value,mec.postingEventTitle as shortDesc,mec.eventImage as eventImage, tps.saveamount as saveamount, tps.pricetext as ticketPrice,tps.pricetext as pricetext, tps.newPrice as newPrice, tps.ticket_net_price as  ticket_net_price, tps.newPrice as totalticketPrice, tps.newPrice as new_discount_price, mec.isreservation as is_reservation, tps.agefrom as agefrom, tps.ageto as ageto, tps.ticket_type_label as ticketType,(case when mec.is_allow_pre_bookings ='1' and  mec.is_reservation='1' then mec.pre_booking_date else mec.startDate end) as start_date,mec.endDate as end_date, mec.third_party_id as  third_party_id, mec.third_party_ticket_id as third_party_ticket_id, mec.third_party_parameters as third_party_parameters, 'getQuery' AS action_performed from qr_codes qc left join template_level_tickets tlt on qc.template_id = tlt.template_id left join modeventcontent mec on mec.mec_id = tlt.ticket_id left join ticketpriceschedule tps on tps.ticket_id = mec.mec_id and tps.default_listing = '1' and date(from_unixtime(if(tps.end_date like '%9999%', '1750343264', tps.end_date))) >= current_date()where mec.mec_id = '$mec_id' and mec.deleted = '0' and tlt.deleted = '0' and tlt.template_id != '0' and qc.cashier_type = '1' and tlt.publish_catalog = '1' and date(from_unixtime(if(tps.end_date like '%9999%', '1750343264', tps.end_date))) >= current_date() group by tlt.template_level_tickets_id, qc.cod_id, tps.ticket_id) as base2 left join pos_tickets pos on base2.cod_id = pos.hotel_id and base2.ticket_id = pos.mec_id) as final_missing_entries_in_pos_tickets where base_id is NULL"

# echo $querystring


mysql -h $SOURCE_DB_HOST -u $SOURCE_DB_USER -p$SOURCE_DB_PASSWORD $SOURCE_DB_NAME -e "$querystring" >> rattan.csv

done

