#!/bin/bash

# Optimized Build Script for Smart Navigation System
# This script builds the app with all performance optimizations enabled

set -e  # Exit on error

echo "🚀 Starting optimized build process..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Clean previous builds
print_step "Cleaning previous builds..."
flutter clean
print_success "Clean complete"
echo ""

# Get dependencies
print_step "Getting dependencies..."
flutter pub get
print_success "Dependencies fetched"
echo ""

# Run code generation if needed
print_step "Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs || true
print_success "Code generation complete"
echo ""

# Analyze code
print_step "Analyzing code..."
flutter analyze
print_success "Analysis complete"
echo ""

# Run tests (optional)
# print_step "Running tests..."
# flutter test
# print_success "Tests passed"
# echo ""

# Build for Android
print_step "Building optimized Android APK..."
flutter build apk \
    --release \
    --split-per-abi \
    --obfuscate \
    --split-debug-info=./build/debug-info/android \
    --target-platform android-arm,android-arm64,android-x64 \
    --dart-define=FLUTTER_WEB_USE_SKIA=false

print_success "Android APK build complete"
echo ""

# Analyze APK size
print_step "Analyzing APK size..."
flutter build apk --analyze-size --target-platform android-arm64
echo ""

# Build for iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_step "Building optimized iOS IPA..."
    flutter build ios \
        --release \
        --obfuscate \
        --split-debug-info=./build/debug-info/ios
    print_success "iOS build complete"
    echo ""
fi

# Build for Web
print_step "Building optimized Web version..."
flutter build web \
    --release \
    --web-renderer canvaskit \
    --source-maps \
    --pwa-strategy offline-first \
    --base-href="/"

print_success "Web build complete"
echo ""

# Display build artifacts
print_step "Build artifacts:"
echo ""
echo "Android APKs:"
ls -lh build/app/outputs/flutter-apk/*.apk 2>/dev/null || echo "  No APK found"
echo ""
echo "iOS IPA:"
ls -lh build/ios/ipa/*.ipa 2>/dev/null || echo "  No IPA found (requires macOS)"
echo ""
echo "Web build:"
du -sh build/web 2>/dev/null || echo "  No web build found"
echo ""

# Performance recommendations
print_warning "Performance Recommendations:"
echo "  1. Test on real devices, not just emulators"
echo "  2. Use Firebase Performance Monitoring in production"
echo "  3. Monitor app size regularly"
echo "  4. Profile with Flutter DevTools before release"
echo "  5. Run lighthouse audit for web builds"
echo ""

print_success "🎉 Optimized build complete!"
echo ""
echo "Next steps:"
echo "  • Test the release build on physical devices"
echo "  • Run performance profiling"
echo "  • Upload to app stores or deploy web version"
echo ""
