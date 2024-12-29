-- Add migration script here

ALTER TABLE user_tokens DROP COLUMN device_info;
ALTER TABLE user_tokens ADD COLUMN device_info TEXT NOT NULL DEFAULT '';