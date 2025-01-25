# Makefile for Swift Project

# Project Settings
PROJECT_NAME = zippy
SCHEME = $(PROJECT_NAME)
CONFIGURATION = Release

# Build Settings
BUILD_DIR = .build

# Targets
.PHONY: all build run clean release install help

# Default target
all: help

# Build the application in debug mode
build:
	@echo "Building zippy in debug mode..."
	@swift build

# Run the application
run: build
	@echo "Running zippy..."
	@$(BUILD_DIR)/debug/zippy

# Clean build artifacts
clean:
	@echo "Cleaning build directory..."
	@swift package clean
	@rm -rf $(BUILD_DIR)

# Build and run in release mode
release:
	@echo "Building zippy in release mode..."
	@swift build -c release
	@echo "Running zippy in release mode..."
	@$(BUILD_DIR)/release/zippy

# Install to /usr/local/bin (requires sudo)
install: release
	@echo "Installing zippy to /usr/local/bin..."
	@sudo cp $(BUILD_DIR)/release/zippy /usr/local/bin/
	@echo "Installation complete! You can now run 'zippy' from anywhere."

# Help command
help:
	@echo "Zippy - Network Status Menu Bar App"
	@echo ""
	@echo "Available commands:"
	@echo "  make        - Show this help message"
	@echo "  make build  - Build the application (debug mode)"
	@echo "  make run    - Build and run the application (debug mode)"
	@echo "  make clean  - Clean build artifacts"
	@echo "  make release - Build and run in release mode"
	@echo "  make install - Install to /usr/local/bin (requires sudo)"