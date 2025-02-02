ALTER TABLE prepaid_tickets MODIFY COLUMN additional_information varchar(255);
ALTER TABLE prepaid_tickets MODIFY COLUMN batch_id varchar(255);
ALTER TABLE prepaid_tickets MODIFY COLUMN chart_number varchar(255);
ALTER TABLE prepaid_tickets MODIFY COLUMN currency_rate float;
ALTER TABLE prepaid_tickets MODIFY COLUMN discount_code_amount float;
ALTER TABLE prepaid_tickets MODIFY COLUMN hotel_ticket_overview_id decimal(10,2);
ALTER TABLE prepaid_tickets MODIFY COLUMN is_data_moved int;
ALTER TABLE prepaid_tickets MODIFY COLUMN last_imported_date varchar(255);
ALTER TABLE prepaid_tickets MODIFY COLUMN order_cancellation_date varchar(255);
ALTER TABLE prepaid_tickets MODIFY COLUMN refunded_by int;
ALTER TABLE prepaid_tickets MODIFY COLUMN voucher_creation_date varchar(255);
ALTER TABLE visitor_tickets MODIFY COLUMN order_cancellation_date varchar(255);