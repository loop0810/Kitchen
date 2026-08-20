## Why

客户端和服务端都存在“失败被完全吞掉”的位置：`catch (_) {}`、空 `catchError((_) {})`、未被观察的 `unawaited(...)`，以及只返回布尔值的就绪检查。离线优先的降级行为本身是正确的，但当前实现让降级与实现缺陷无法区分：孤立封面与受控媒体清理失败没有任何线索、平台“不支持识别”被写成“这张图片不清”、导入草稿暂存失败时用户仍以为已保存、单个待恢复任务异常会阻断其余任务。

## What Changes

- 所有机会式维护（孤立封面清理、受控媒体清理、过期菜谱清理、个性化配置同步）保持不阻断启动，但失败必须写入诊断日志。
- 可选文件操作只屏蔽 `FileSystemException`，其余异常继续向上传递以暴露实现缺陷。
- OCR 适配层已给出稳定错误码时按原样记录到失败页，不再统一降级为 `pageUnreadable`。
- `resumePending()` 隔离单任务失败，保证其余待处理任务继续恢复。
- 组合根统一观察启动、生命周期和分享导入触发的后台 Future，失败按操作名称归因。
- 用户发起的操作（集合增删排序、草稿暂存与继续、补充说明、重新整理、备份与清除、解绑）在失败时同时给出中文提示和诊断日志。
- 认证失败只记录异常类型，不记录错误对象，避免响应体或凭证进入日志。
- 服务端 `/health/ready` 与数据库就绪检查在失败时记录 `readiness_check_failed` / `database_readiness_failed`，仅包含异常类型这一安全字段，对外仍返回不透明 503。

## Capabilities

### New Capabilities

- `error-observability`：定义降级路径的可观测性要求，即“可以降级，但不得静默”。

### Modified Capabilities

无。

## Impact

- 客户端：根 App 组合根、认证会话仓库、Recipe Data、Import Data、Import Domain、Import UI、Recipe Library、Recipe Editor、Profile。
- 服务端：`app/factory.py` 就绪探针与 `infrastructure/database.py` 就绪检查；日志仍受 `SafeJsonFormatter` 字段白名单约束。
- 不改变离线可用性、任务状态机、HTTP 契约和错误响应体；不新增依赖。
