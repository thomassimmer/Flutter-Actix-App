# Use the official Rust image as the base image
FROM rust:latest

# Create a new user and switch to that user
RUN useradd -m rustuser
USER rustuser

# Install cargo-watch
RUN cargo install cargo-watch
RUN cargo install sqlx-cli --no-default-features --features postgres

# Set the working directory inside the container
WORKDIR /app

# Now copy the rest of the source code
COPY --chown=rustuser:rustuser . .

# Expose the port the app runs on
EXPOSE 8000
