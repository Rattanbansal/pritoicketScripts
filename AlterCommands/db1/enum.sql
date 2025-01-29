ALTER TABLE merchant_details MODIFY COLUMN deleted enum('0','1') DEFAULT '0';
ALTER TABLE promocode MODIFY COLUMN promotion_type enum('PROMOCODE','ADDONS_CAMPAIGN') DEFAULT 'PROMOCODE';
ALTER TABLE qr_codes MODIFY COLUMN display_detail_on_checkout_overview enum('0','1') NOT NULL DEFAULT '1' COMMENT '0=not display detail on yellow screen checkout,1=display detail on checkout';
ALTER TABLE qr_codes MODIFY COLUMN isPremiumAccount enum('0','1') NOT NULL DEFAULT '0';
ALTER TABLE qr_codes MODIFY COLUMN merchantAdminstativeInstructionIsMandatory enum('0','1') DEFAULT NULL COMMENT '0=not mandatory, 1=mandatory';
ALTER TABLE qr_codes MODIFY COLUMN template enum('0','1','2','3','4') NOT NULL DEFAULT '0';