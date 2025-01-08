--- query to check for one pos_ticket we have duplicate rows

select pos.pos_ticket_id, pos.hotel_id, pos.mec_id, pos.deleted, pos.is_pos_list, pos.last_modified_at from pos_tickets pos join (SELECT hotel_id, mec_id FROM pos_tickets where pos_ticket_id = '95600364') as base on pos.hotel_id = base.hotel_id and pos.mec_id = base.mec_id 