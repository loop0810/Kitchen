#!/usr/bin/env bash

# 检查 Feature 生产代码是否绕过 kitchen_app_core 直接使用全局路由字符串。
# 路由注册本身只允许出现在根壳工程；测试可以自行构造最小 GoRouter，因此排除测试目录。
set -euo pipefail

client_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
production_roots=("$client_root/lib" "$client_root/packages")

direct_navigation="$({
  rg -n --glob '*.dart' --glob '!**/test/**' \
    --glob '!lib/src/navigation/kitchen_notes_app_router.dart' \
    --glob '!packages/kitchen_app_core/lib/src/navigation/extensions/**' \
    'context\.(go|push)\(|context\.(go|push|replace)Named\(' \
    "${production_roots[@]}" || true
})"

direct_paths="$({
  rg -n --glob '*.dart' --glob '!**/test/**' \
    --glob '!lib/src/navigation/kitchen_notes_app_router.dart' \
    "path:[[:space:]]*'/'" "${production_roots[@]}" || true
})"

if [[ -n "$direct_navigation" || -n "$direct_paths" ]]; then
  echo "发现绕过路由契约的生产代码：" >&2
  [[ -z "$direct_navigation" ]] || echo "$direct_navigation" >&2
  [[ -z "$direct_paths" ]] || echo "$direct_paths" >&2
  exit 1
fi

echo "Navigation boundary check passed."
