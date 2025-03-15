-- Migration: Add 'theme' column to 'users' table

ALTER TABLE users
ADD COLUMN theme VARCHAR(10) NOT NULL DEFAULT 'light';
