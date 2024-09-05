-- Add migration script here

ALTER TABLE users
ADD COLUMN password_is_expired BOOL NOT NULL DEFAULT FALSE;
