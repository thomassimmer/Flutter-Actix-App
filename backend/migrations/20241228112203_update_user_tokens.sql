-- Add migration script here


ALTER TABLE user_tokens DROP COLUMN device_info;
ALTER TABLE user_tokens ADD COLUMN device TEXT NOT NULL DEFAULT '';
ALTER TABLE user_tokens ADD COLUMN os TEXT NOT NULL DEFAULT '';