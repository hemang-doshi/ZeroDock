#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/core-tests
swiftc -D CORE_TEST_RUNNER Core/Models/*.swift Tests/*Tests.swift Tests/TestSupport.swift Tests/main.swift -o .build/core-tests/ZeroDockCoreTests
.build/core-tests/ZeroDockCoreTests
