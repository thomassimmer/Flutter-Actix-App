-- Add migration script here


ALTER TABLE user_tokens DROP COLUMN device;
ALTER TABLE user_tokens DROP COLUMN os;
ALTER TABLE user_tokens ADD COLUMN device TEXT;
ALTER TABLE user_tokens ADD COLUMN os TEXT;