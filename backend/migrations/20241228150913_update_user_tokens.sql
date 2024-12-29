-- Add migration script here

ALTER TABLE user_tokens DROP COLUMN is_browser;
ALTER TABLE user_tokens ADD COLUMN is_mobile BOOLEAN;
ALTER TABLE user_tokens ADD COLUMN browser TEXT;
ALTER TABLE user_tokens ADD COLUMN app_version TEXT;
ALTER TABLE user_tokens ADD COLUMN model TEXT;