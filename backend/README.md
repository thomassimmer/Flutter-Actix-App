# To be able to use sqlx cli tools 

cargo install sqlx-cli --no-default-features --features postgres

# To create a new migration file

sqlx migrate add name_of_your_migration
sqlx migrate run
