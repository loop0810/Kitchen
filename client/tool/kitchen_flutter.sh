#!/usr/bin/env bash

# Flutter 的 VM Service、DDS 和 flutter_tester 都通过本机回环地址通信。
# 开发环境可能设置了代理；如果不声明 NO_PROXY，127.0.0.1 的调试连接会被
# 代理接管，表现为 Connection closed before full header was received。
set -euo pipefail

local_proxy_bypass='127.0.0.1,localhost,::1'
if [[ -n "${NO_PROXY:-}" ]]; then
  export NO_PROXY="${NO_PROXY},${local_proxy_bypass}"
else
  export NO_PROXY="${local_proxy_bypass}"
fi
if [[ -n "${no_proxy:-}" ]]; then
  export no_proxy="${no_proxy},${local_proxy_bypass}"
else
  export no_proxy="${local_proxy_bypass}"
fi

exec flutter "$@"
