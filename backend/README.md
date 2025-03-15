# To be able to use diesel cli tools 

cargo install diesel_cli --no-default-features --features postgres

# To create a new migration file

diesel migration generate name_of_your_migration --diff-schema