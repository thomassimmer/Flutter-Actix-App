-- Add migration script here

ALTER TABLE user_tokens ADD COLUMN device_info TEXT;
