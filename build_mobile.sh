#!/bin/bash

# SynqCast Mobile Build Script
# This script builds the app for both Android and iOS platforms

set -e  # Exit on any error

echo "🚀 SynqCast Mobile Build Script"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version: $(flutter --version | head -n 1)"

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Check Flutter doctor
print_status "Running Flutter doctor..."
flutter doctor

echo ""
echo "📱 Building for Android..."
echo "=========================="

# Build Android APK (Release)
print_status "Building Android APK (Release)..."
flutter build apk --release --target-platform android-arm64

if [ $? -eq 0 ]; then
    print_success "Android APK build successful!"
    print_status "APK location: build/app/outputs/flutter-apk/app-release.apk"
    print_status "APK size: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
else
    print_error "Android APK build failed!"
    exit 1
fi

# Build Android APK (Debug) - Optional
echo ""
print_status "Building Android APK (Debug)..."
flutter build apk --debug --target-platform android-arm64

if [ $? -eq 0 ]; then
    print_success "Android Debug APK build successful!"
    print_status "Debug APK location: build/app/outputs/flutter-apk/app-debug.apk"
else
    print_warning "Android Debug APK build failed (this is optional)"
fi

# Build Android App Bundle (for Play Store)
echo ""
print_status "Building Android App Bundle..."
flutter build appbundle --release --target-platform android-arm64

if [ $? -eq 0 ]; then
    print_success "Android App Bundle build successful!"
    print_status "AAB location: build/app/outputs/bundle/release/app-release.aab"
else
    print_warning "Android App Bundle build failed"
fi

echo ""
echo "🍎 Building for iOS..."
echo "======================"

# Check if we're on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "macOS detected - iOS build available"
    
    # Check if Xcode is installed
    if command -v xcodebuild &> /dev/null; then
        print_status "Xcode detected"
        
        # Build iOS (Release)
        print_status "Building iOS (Release)..."
        flutter build ios --release --no-codesign
        
        if [ $? -eq 0 ]; then
            print_success "iOS build successful!"
            print_status "iOS build location: build/ios/iphoneos/Runner.app"
        else
            print_error "iOS build failed!"
        fi
        
        # Build iOS (Debug)
        print_status "Building iOS (Debug)..."
        flutter build ios --debug --no-codesign
        
        if [ $? -eq 0 ]; then
            print_success "iOS Debug build successful!"
        else
            print_warning "iOS Debug build failed"
        fi
        
    else
        print_warning "Xcode not found - iOS builds skipped"
        print_status "Install Xcode from the App Store to build for iOS"
    fi
else
    print_warning "Not on macOS - iOS builds skipped"
    print_status "iOS development requires macOS with Xcode"
fi

echo ""
echo "📋 Build Summary"
echo "================"

# List all built files
print_status "Built files:"
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "  📱 Android APK (Release): build/app/outputs/flutter-apk/app-release.apk"
fi

if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo "  📱 Android APK (Debug): build/app/outputs/flutter-apk/app-debug.apk"
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    echo "  📦 Android App Bundle: build/app/outputs/bundle/release/app-release.aab"
fi

if [[ "$OSTYPE" == "darwin"* ]] && [ -d "build/ios/iphoneos" ]; then
    echo "  🍎 iOS App: build/ios/iphoneos/Runner.app"
fi

echo ""
print_success "Build process completed!"
print_status "Installation instructions:"
echo "  📱 Android: Transfer APK to device and install"
echo "  🍎 iOS: Use Xcode to install on device or simulator"

echo ""
print_status "Next steps:"
echo "  1. Test the app on actual devices"
echo "  2. Configure signing for production releases"
echo "  3. Upload to app stores (Google Play Store / Apple App Store)"
