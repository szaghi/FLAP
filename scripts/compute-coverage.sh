#!/bin/bash

set -euo pipefail

PCT=$(set +o pipefail
      find . -name '*.gcda' | xargs -r gcov 2>/dev/null | \
        awk '/^Lines executed:/{
          match($0, /([0-9.]+)% of ([0-9]+)/, a)
          total += a[2]; covered += a[1]/100 * a[2]
        } END { if (total>0) printf "%.1f", covered/total*100; else print "0.0" }')

mkdir -p docs/public
printf '{"pct":"%s"}\n' "${PCT}" > docs/public/coverage.json

echo "Coverage: ${PCT}%"
