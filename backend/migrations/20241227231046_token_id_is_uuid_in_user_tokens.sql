-- Add migration script here

ALTER TABLE user_tokens DROP COLUMN token_id;
ALTER TABLE user_tokens ADD COLUMN token_id UUID NOT NULL UNIQUE;