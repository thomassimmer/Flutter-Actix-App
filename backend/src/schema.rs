diesel::table! {
    users (id) {
        id -> Uuid,
        username -> Varchar,
        password -> Varchar,

        otp_enabled -> Bool,
        otp_verified -> Bool,
        otp_base32 -> Nullable<Varchar>,
        otp_auth_url -> Nullable<Varchar>,

        created_at -> Nullable<Timestamptz>,
        updated_at -> Nullable<Timestamptz>,

        recovery_codes -> Array<Text>,
    }
}

diesel::allow_tables_to_appear_in_same_query!(users,);
