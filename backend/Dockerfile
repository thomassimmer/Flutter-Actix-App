# Use the official Rust image as the base image
FROM rust:1.81

# Create a new user and switch to that user
RUN useradd -m rustuser
USER rustuser

# Install cargo-watch
RUN cargo install cargo-watch

# Set the working directory inside the container
WORKDIR /app

# First, copy the Cargo.toml and Cargo.lock files to build the dependency cache
COPY --chown=rustuser:rustuser Cargo.toml Cargo.lock ./

# Create a dummy main.rs file to build the dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build the dependencies only (this will be cached unless Cargo.toml or Cargo.lock changes)
RUN cargo build

# Remove the dummy main.rs to prepare for copying the actual source code
RUN rm -rf src

# Now copy the rest of the source code
COPY --chown=rustuser:rustuser . .

# Expose the port the app runs on
EXPOSE 8000

# Run the Actix web server with cargo watch for automatic rebuilding and running
CMD ["cargo", "watch", "-q", "-c", "-w", "src/", "-x", "run"]