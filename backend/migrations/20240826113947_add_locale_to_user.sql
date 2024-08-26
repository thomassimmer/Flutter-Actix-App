-- Migration: Add 'locale' column to 'users' table

ALTER TABLE users
ADD COLUMN locale VARCHAR(10) NOT NULL DEFAULT 'en';
