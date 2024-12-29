-- Add migration script here

ALTER TABLE users ADD column is_admin BOOLEAN NOT NULL DEFAULT FALSE;
