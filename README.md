# dsh-squad

把 DS Bot（DeepSeek 的宿主）接成一个多智能体小队（Squad）：Controller（Go）负责任务、依赖、审核与恢复；DSH Adapter（JavaScript）把 DS Bot 的会话交给 Controller 管理；另有部署脚本、客户端页面，以及用来对照不同组织方式的实验运行器。

本仓库由 `pi-learn` 中的 `dsh_squad` 独立而来，第一次提交不带原仓库的历史。

## 目录

| 路径 | 内容 |
|---|---|
| `dsh_squad/` | 主体：`controller`（Go）、`adapter`（JS）、`client`（页面）、`deploy`（一键部署）、`scripts`（检查与构建）、`experiments`（实验运行器、判题、规格、模板）、`patches`（对 ds-bot 的补丁）、`protocol`、`cases`、`USAGE.md` |
| `dsh-bot/ds-bot/` | DS Bot 宿主源码（上游 `Fei2411/DeepSeek-Bot`，Apache-2.0，锁定版本见 `dsh-bot/UPSTREAM`） |
| `probes/` | `versions.lock.json`（锁定的 DSH npm 版本与 ds-bot 提交）和 `squad-mock.mjs`（`--mock` 使用的模拟服务） |

## 依赖

- **Go 1.27 或更新**（`dsh_squad/controller/go.mod`）。Go 依赖由 `go` 命令下载。
- **Node.js 24**（在 v24.18 上测试过）和 **npm**。
- **git**（`prepare-ds-bot.sh` 用 `git init` 生成补丁后的 ds-bot 副本）。
- **DeepSeek（DSH）**：`dsh_squad/deploy/dsh-squad` 按 `probes/versions.lock.json` 从 npm 安装 `@deepseek-ai/dsh`，不随仓库发布。
- 可选：**Google Chrome**（`squad_check_page` 取证工具和实验判题）。路径可用 `CHROME` 指定，默认 `/usr/bin/google-chrome`。
- 可选：**puppeteer-core** 和 **axe-core**，装在仓库外的 `~/.cache/dsh-exp-tools`（可用 `DSH_EXP_TOOLS` 指定）。实验判题和页面取证需要它们。

## 安装

```sh
git clone https://github.com/kms9/dsh-squad.git
cd dsh-squad/dsh-bot/ds-bot
npm ci --ignore-scripts      # ds-bot 的依赖（含 esbuild）
npm run harness              # 测试用的 DSH 依赖，装在 dev/harness
cd ../..
```

## 检查

```sh
sh dsh_squad/scripts/check.sh
```

它依次检查：controller 的构建、vet 与测试；adapter 的测试；client 的测试与打包是否最新；按锁定版本生成补丁后的 ds-bot 并跑它的测试。

## 冒烟运行（不需要密钥）

```sh
node dsh_squad/experiments/exp/run.mjs exp02 --mock --repeats 1 --arms B0,DAG
```

`--mock` 不调用模型，但会真的启动 DSH 宿主和 controller，走完一次 Run（B0 是一步，DAG 包含两段审核）。运行结束后没有残留进程。

## 跑一个真实的小队

密钥只从环境变量读取，仓库里不保存任何密钥：

```sh
export DEEPSEEK_API_KEY=...                       # 或在 DSH 的设置页里填写
dsh_squad/deploy/dsh-squad up <项目目录>            # 项目目录里会生成 .agents/dshsquad 和 .dsh-squad
dsh_squad/deploy/dsh-squad down <项目目录>
```

配置、任务下发与会话内工具见 `dsh_squad/USAGE.md`。

## 实验

```sh
DEEPSEEK_API_KEY=... node dsh_squad/experiments/exp/run.mjs exp01 --repeats 5
node dsh_squad/experiments/exp/summarize.mjs <报告>.json
```

实验 `exp01`～`exp03` 的规格在 `specs/`，模板在 `templates/`，判题在 `judges/`，输入在 `fixtures/`。每次运行在 `experiments/exp/.runs/` 下使用一个全新的项目目录，报告写到 `experiments/exp/reports/`，两者都不进入版本库。`--resume` 可以续跑，挂起的运行会被排除并重跑（见 `USAGE.md` 10.1）。

## 已知的限制

- `adapter/test/judge.test.js` 中的 4 个回放测试读取 DS Bot 录制的会话日志（`probes/scenarios*`）。这些日志不随本仓库发布，所以这 4 个测试会显式跳过（`skip`），其余测试照常运行。
- 设计文档（`docs/`、PRD）和实验结果、会话记录都不在本仓库里。`USAGE.md` 与 `AGENTS.md` 中提到的 `docs/…` 路径指向原项目，在这里不可用。
- 运行器在机器挂起时会排除并重跑受影响的运行；卡住检测（`stall.mjs`）在 `needs_review` 状态下 10 分钟无进展时生效。

## 许可证

- `dsh-bot/ds-bot/`：Apache-2.0，版权归上游作者所有，许可证文本在 `dsh-bot/ds-bot/LICENSE` 和 `dsh-bot/LICENSE`。
- `dsh_squad/`、`probes/`、`experiments/`：**尚未声明许可证**。在选定许可证之前，请不要假定可以复用。
