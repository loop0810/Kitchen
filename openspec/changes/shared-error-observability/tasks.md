## 1. 客户端降级路径可观测化

- [x] 1.1 将 `kitchen_recipe_data` 与 `kitchen_import_data` 组合入口的空 `catchError((_) {})` 替换为记录失败原因的观察者，保持清理不阻断启动
- [x] 1.2 将可选封面与受控媒体文件操作的宽泛 `catch (_)` 收窄为 `FileSystemException` 并记录日志
- [x] 1.3 个性化配置远端保存与启动同步失败时保留缓存与 pending 状态，并记录失败原因

## 2. 导入流水线错误语义

- [x] 2.1 单页 OCR 抛出 `ImportPipelineException` 时按原样持久化其错误码与用户指引
- [x] 2.2 非预期的单页与任务级异常在降级前记录诊断日志
- [x] 2.3 `resumePending()` 隔离单任务失败，保证其余待处理任务继续恢复
- [x] 2.4 增加流水线测试：稳定错误码原样落库、单任务恢复失败不影响其余任务

## 3. 组合根与用户可见反馈

- [x] 3.1 组合根统一以命名后台工作包装会话恢复、导入恢复、个性化同步、Android 分享消费、过期菜谱清理和分享导入处理
- [x] 3.2 认证恢复与登录失败只记录异常类型，避免凭证或响应体进入日志
- [x] 3.3 集合成员添加、移除、撤销和排序失败时回退乐观更新并提示用户
- [x] 3.4 草稿字段暂存、继续保存、补充说明和重新整理失败时提示用户并记录日志
- [x] 3.5 图片与文本导入的后台处理、媒体工作区重处理失败不再成为无人认领的异步错误
- [x] 3.6 Profile 依赖读取只容忍未注入依赖，账号删除与本机清理失败分别给出对应文案

## 4. 服务端就绪诊断

- [x] 4.1 `/health/ready` 捕获非预期异常时记录 `readiness_check_failed`，仅包含异常类型
- [x] 4.2 数据库就绪检查失败时记录 `database_readiness_failed`，仅包含异常类型
- [x] 4.3 增加单元测试：就绪检查抛错仍返回不透明 503，日志包含类别且不含异常消息

## 5. 验证

- [x] 5.1 `dart format`、`flutter analyze`、`flutter test`、`flutter test packages/*/test`
- [x] 5.2 `make lock-check`、`make typecheck`、`make test`（`make format-check` 的两处失败为既有未改动文件的格式化漂移）
- [x] 5.3 学习记录豁免：服务端改动仅为既有 `SafeJsonFormatter` 白名单字段下的日志补充，未引入新的 FastAPI、SQLAlchemy 或运维知识增量
