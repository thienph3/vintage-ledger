#!/bin/bash
cd /home/phthien/workspace/thienph3/vintage-ledger

echo "=== EN duplicates ==="
grep -ohP "'[^']+'\s*:" lib/core/l10n/en/*.dart | sort | uniq -d

echo "=== VI duplicates ==="
grep -ohP "'[^']+'\s*:" lib/core/l10n/vi/*.dart | sort | uniq -d

echo "=== EN duplicates with files ==="
for key in $(grep -ohP "'[^']+'\s*:" lib/core/l10n/en/*.dart | sort | uniq -d); do
  echo "$key found in:"
  grep -l "$key" lib/core/l10n/en/*.dart
done

echo "=== VI duplicates with files ==="
for key in $(grep -ohP "'[^']+'\s*:" lib/core/l10n/vi/*.dart | sort | uniq -d); do
  echo "$key found in:"
  grep -l "$key" lib/core/l10n/vi/*.dart
done
