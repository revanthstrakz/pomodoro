#!/bin/bash

echo "Running Pomodoro App Tests"
echo "=========================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Flutter is not installed. Please install Flutter to run tests."
    exit 1
fi

echo "Installing dependencies..."
flutter pub get

echo "Generating mock files..."
flutter packages pub run build_runner build --delete-conflicting-outputs

echo "Running unit tests..."
flutter test test/services/
flutter test test/controllers/

echo "Running widget tests..."
flutter test test/widgets/

echo "Running all tests..."
flutter test

echo "Tests completed!"