#!/bin/bash

# R11 Style Guide Audit Script
# Scans codebase for style guide violations

echo "=== R11 Style Guide Audit ==="
echo ""

# 1. CircularProgressIndicator violations
echo "1. CircularProgressIndicator usage (should use ShimmerPlaceholder):"
grep -r "CircularProgressIndicator" lib/ --include="*.dart" | wc -l
echo ""

# 2. withOpacity violations
echo "2. withOpacity usage (should use AppColors with opacity):"
grep -r "withOpacity" lib/ --include="*.dart" | wc -l
echo ""

# 3. Relative import violations
echo "3. Relative imports (should use package: imports):"
grep -r "^import '\.\." lib/ --include="*.dart" | wc -l
echo ""

# 4. Hardcoded string violations (excluding constants and enums)
echo "4. Potential hardcoded strings (manual review needed):"
grep -r "Text(" lib/features/ --include="*.dart" | grep -v "S.of" | grep -v "AppTextStyles" | wc -l
echo ""

# 5. Inline color violations
echo "5. Inline Color usage (should use AppColors):"
grep -r "Color(0x" lib/features/ --include="*.dart" | wc -l
echo ""

# 6. Inline TextStyle violations
echo "6. Inline TextStyle usage (should use AppTextStyles):"
grep -r "TextStyle(" lib/features/ --include="*.dart" | wc -l
echo ""

# 7. Inline spacing violations
echo "7. Hardcoded spacing (should use AppSpacing):"
grep -r "SizedBox(height: [0-9]" lib/features/ --include="*.dart" | wc -l
grep -r "SizedBox(width: [0-9]" lib/features/ --include="*.dart" | wc -l
echo ""

echo "=== Detailed Reports ==="
echo ""

echo "CircularProgressIndicator locations:"
grep -rn "CircularProgressIndicator" lib/ --include="*.dart"
echo ""

echo "withOpacity locations:"
grep -rn "withOpacity" lib/ --include="*.dart" | head -20
echo ""

echo "Relative import locations:"
grep -rn "^import '\.\." lib/ --include="*.dart" | head -20
echo ""

echo "=== Audit Complete ==="
