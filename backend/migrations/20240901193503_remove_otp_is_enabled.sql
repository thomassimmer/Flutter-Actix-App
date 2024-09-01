-- Add migration script here

ALTER TABLE users
DROP COLUMN otp_enabled;
