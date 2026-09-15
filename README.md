# 日序 · Dayweave

面向个人的多项目时间轴与每日任务安排工具。电脑负责规划，手机可查看、完成任务、编辑备注和改期。

源码：[MOONLZH/dayweave-planner](https://github.com/MOONLZH/dayweave-planner) · 许可证：[MIT](LICENSE)

## 已实现

- 项目起止日期、颜色、备注，以及周 / 双周 / 月时间轴。
- 点击日期汇总全部项目的每日记录，跨项目拖拽排序，也支持上移 / 下移按钮。
- 单日任务和跨天任务；每个执行日有独立内容、备注、预计分钟、完成状态和顺序。
- 全部每日记录完成后，总任务自动完成；修改或改期某天不影响其他日期。
- 任务截止日期独立于执行日期；错过执行日进入待处理区，不会自动顺延。
- 项目详情与每日清单共享同一份状态；改期追加到目标日末尾，必要时扩展项目周期。
- ChatGPT 个人身份 + Cloudflare D1 持久化；8 秒检查更新，返回窗口时立即同步。
- 数据按稳定用户 ID 隔离；每次保存使用版本号进行条件更新，防止两个设备同时覆盖。
- 首次访问展示明确标记的示例，可直接创建自己的第一个项目；示例不写入数据库。
- WebMCP：`get_day_plan` 读取每日安排，`show_plan_date` 联动界面日期。

## 参考来源

根据用户提供的 [OCA/project](https://github.com/OCA/project/tree/18.0) 参考以下产品概念：

- `project_timeline`：项目与任务的计划起止日期、统一时间轴。
- `project_task_note`：任务附加备注。
- `project_task_parent_completion_blocking`：父任务与子任务完成状态的一致性。

本应用独立实现界面与业务逻辑，未复制 OCA 模块源码，也无需安装 Odoo。每日记录、跨项目排序和个人同步根据本项目需求实现。

## 本地运行

需要 Node.js >= 22.13.0、npm。先安装依赖、构建并初始化本地数据库：

```sh
git clone https://github.com/MOONLZH/dayweave-planner.git
cd dayweave-planner
npm ci
npm run build
node --import ./scripts/sites-env.mjs ./node_modules/wrangler/bin/wrangler.js d1 execute DB --local --config dist/server/wrangler.json --persist-to .wrangler/state --file drizzle/0000_flashy_unicorn.sql
npm run dev
```

打开终端显示的本地地址（默认 `http://localhost:5173`）。在 `/signin-with-chatgpt?return_to=/` 使用 starter 提供的本地演示身份；该模拟登录不进入生产构建。数据库迁移位于 `drizzle/`；新增迁移后按顺序应用。

## 部署与身份认证

当前生产部署使用 Sites 的 ChatGPT 登录入口和 Cloudflare D1 数据库，线上迁移由 Sites 发布流程执行，不在请求处理时创建数据库表。公开仓库仅保留通用数据库绑定配置，不包含作者的部署项目标识、凭据或私人任务数据。

使用 Sites 部署时，需要创建自己的项目并绑定数据库。`app/chatgpt-auth.ts` 依赖可信 Sites 网关注入身份请求头；若改用其他托管平台，必须先接入该平台的服务端身份认证，并阻止客户端伪造身份请求头。单独启动构建后的 Worker 不会提供生产登录服务。

## 验证

```sh
npm run typecheck
npm test
npm start
# 另一个终端，对本地构建后的 Worker 做集成验证
npm run test:api
```

测试覆盖日期边界、上海时区、跨项目排序、逐日完成、改期、项目日期扩展、无效关系、鉴权、持久保存、账号隔离、并发冲突和跨来源写入拒绝。集成测试仅允许 localhost / 127.0.0.1，使用独立测试身份。

## 数据与同步

`GET /api/planner` 返回 `{ state, revision, user }`；`PUT /api/planner` 接收 `{ state, revision }`。`state` 包含 `projects`、`tasks` 和 `entries`。D1 中以用户 ID 为主键保存一份原子工作空间快照，以便跨日期移动和重排序一起成功或一起失败。条件更新失败返回 409，界面刷新并保留正在编辑的草稿。

本工具需要联网保存。离线时不会伪装成已同步，也不把浏览器存储当作唯一数据源。日期按上海时区确定“今天”；单次跨天生成上限 366 天，工作空间最多 300 个项目、5000 个任务、12000 条每日记录。任务备注最多 10000 字。未实现团队协作、附件、通知与外部日历接入。

## 开源许可

本项目原创代码使用 [MIT 许可证](LICENSE)，允许使用、修改和再分发，须保留许可与版权声明。内置第三方代码和依赖保留各自的许可，详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。欢迎通过 Issues 反馈问题，或提交 Pull Request 改进工具。
