-- Add migration script here

ALTER TABLE user_tokens ADD COLUMN is_browser BOOLEAN;