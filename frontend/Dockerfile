FROM ghcr.io/cirruslabs/flutter:3.24.0-0.2.pre@sha256:8e6ae5d10c653665cbe5f5737e23eb9ef50eaa6d2a0b90d834226db1352fa007

# Create a non-root user and switch to that user
RUN useradd -m flutteruser

# Change ownership of the Flutter SDK to the non-root user
RUN chown -R flutteruser:flutteruser /sdks/flutter

USER flutteruser

# Set the working directory inside the container
WORKDIR /app

# Set the working directory inside the container
WORKDIR /home/flutteruser/app

# Copy the Flutter project files into the container
COPY --chown=flutteruser:docker . .

# Enable web support
RUN flutter config --enable-web

# Ensure dependencies are installed
RUN flutter pub get

# Expose the port Flutter will use for web server
EXPOSE 3000

# Start the Flutter development server
CMD ["flutter", "run", "-d", "web-server", "--web-port", "3000", "--web-hostname", "0.0.0.0"]