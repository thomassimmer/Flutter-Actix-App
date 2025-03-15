# Use the official Rust image as the base image
FROM rust:1.81

# Create a new user and switch to that user
RUN useradd -m rustuser
USER rustuser

# Install cargo-watch
RUN cargo install cargo-watch

# Set the working directory inside the container
WORKDIR /app

# Now copy the rest of the source code
COPY --chown=rustuser:rustuser . .

# Expose the port the app runs on
EXPOSE 8000
