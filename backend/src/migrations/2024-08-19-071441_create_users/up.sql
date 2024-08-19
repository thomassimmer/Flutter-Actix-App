-- Your SQL goes here
CREATE TABLE "users"(
	"id" UUID NOT NULL PRIMARY KEY,
	"username" VARCHAR NOT NULL,
	"password" VARCHAR NOT NULL,
	"otp_enabled" BOOL NOT NULL,
	"otp_verified" BOOL NOT NULL,
	"otp_base32" VARCHAR,
	"otp_auth_url" VARCHAR,
	"created_at" TIMESTAMPTZ,
	"updated_at" TIMESTAMPTZ,
	"recovery_codes" TEXT NOT NULL[]
);

