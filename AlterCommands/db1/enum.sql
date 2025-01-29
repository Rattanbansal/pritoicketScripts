ALTER TABLE merchant_details MODIFY COLUMN deleted enum; -- Applicable servers: sandbox
ALTER TABLE promocode MODIFY COLUMN promotion_type enum; -- Applicable servers: test, staging, sandbox
ALTER TABLE qr_codes MODIFY COLUMN display_detail_on_checkout_overview enum; -- Applicable servers: sandbox
ALTER TABLE qr_codes MODIFY COLUMN isPremiumAccount enum; -- Applicable servers: test
ALTER TABLE qr_codes MODIFY COLUMN merchantAdminstativeInstructionIsMandatory enum; -- Applicable servers: sandbox
ALTER TABLE qr_codes MODIFY COLUMN template enum; -- Applicable servers: staging, sandbox