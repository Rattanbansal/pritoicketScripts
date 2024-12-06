SELECT clc.ticketpriceschedule_id, clc.ticket_type, tps.ticket_type_label  FROM channel_level_commission clc join ticketpriceschedule tps on clc.ticketpriceschedule_id = tps.id and clc.ticket_type is null where clc.deleted = '0' and tps.deleted = '0'


update channel_level_commission clc join ticketpriceschedule tps on clc.ticketpriceschedule_id = tps.id and clc.ticket_type is null set clc.ticket_type = tps.ticket_type_label where clc.deleted = '0' and tps.deleted = '0'


SELECT clc.ticketpriceschedule_id, clc.ticket_type, tps.ticket_type_label FROM channel_level_commission clc join ticketpriceschedule tps on clc.ticketpriceschedule_id = tps.id and clc.ticket_type = '' where clc.deleted = '0' and tps.deleted = '0' and clc.ticket_type != tps.ticket_type_label


update channel_level_commission clc join ticketpriceschedule tps on clc.ticketpriceschedule_id = tps.id and clc.ticket_type = '' set clc.ticket_type = tps.ticket_type_label where clc.deleted = '0' and tps.deleted = '0' and clc.ticket_type != tps.ticket_type_label