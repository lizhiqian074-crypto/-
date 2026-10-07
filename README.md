# 隐秘生命档案 · Hidden Wildlife Archive

Godot 4.x 离线生态观察游戏 Demo。玩家安静观察森林中各自生活的毛冠鹿，动物拥有独立人格、情绪、行为记忆和关系；生命片段被收为明信片，玩家可点击生成本地生命档案并观看预制纪录片。

## 这次更新

**地形碰撞已接入：** 玩家和毛冠鹿使用物理身体移动；森林 GLB 自动生成静态碰撞，原有碰撞沿用。鹿受重力影响并贴合可行走斜坡；玩家 WASD / Q/E 移动都受碰撞限制。真实森林会自动烘焙导航，缺导航时也会被障碍挡住，不再直接穿过地形。

本次仅更新时：关闭 Godot，复制新版 `scripts` 文件夹和 `scenes/Game.tscn` 到原项目，同名替换。保留原 `assets` 里的模型、图片和视频。已有 `data/assets.json` 无需替换，自动碰撞和导航默认生效。

明信片按实际行为独立触发，不再有固定等待或前置顺序：

- 任意一只鹿对玩家好感达到 **100** 后主动靠近，获得“第一次见面”。
- 任意两只鹿对彼此的好感**都达到 100** 后一起玩耍，获得“新的朋友”。
- 任意一只鹿实际走进距离其出生点至少 **8 米**的未访问探索区域，获得“第一次探索”。

安静陪伴和同类接触的好感增长已加快。每种片段只收集一次；同时发生的片段会排队显示。旧存档保留已经获得的卡片，想从零演示可开启 Debug 后按 F4。原图片文件名保持兼容。

- 新增 **开始页面 → 动物选择 → 森林观察** 流程。开始页有层叠森林剪影、柔和暖光、缓慢薄雾，读取你原来的游戏图标，不裁切、不改字。
- 开场四只鹿：小栗（好奇、喜欢独处）、苔苔（胆小）、阿棕（亲近同伴）、云朵（勇敢、好奇）。山竹可通过 Debug F3 加入演示。每只鹿有自己的状态机、导航代理和 AnimalMind。
- 记住玩家的安静陪伴、靠近或突然移动、栖地帮助，以及同类接触。对玩家和每个同类分别维护 0–100 好感，记忆会影响信任、警觉、提前避让和社交。自动保存，换场景和重启都保留。
- “林间生命”可查看每只鹿的性格、情绪、对玩家态度和同伴关系。“照料栖地”改善林下食源；只有自主觅食并受益的鹿才记录帮助，不直接操控动物。
- 按你的要求，**演示时随时能点击“生成生命纪录片”**。生成页如实展示目前已记录的片段，写入本地档案，再点击“观看纪录片”。三明信片主流程仍正常运行。
- 已接入你上传的 **ai纪录片.mp4**，转为 Godot 原生支持的 Theora/Vorbis OGV，保留 1280×720 画面和音轨，约 14 秒。你无需再转码。视频不会因不同存档自动变成新片；“生成”是整理个人观察档案并准备这段预制电影，不调用在线 AI。

## 你已经放好模型和图片，如何更新

1. **先关闭 Godot**，给你原来的游戏文件夹复制一份备份。
2. 解压 GitHub 下载的新版项目。把新版里面的文件与文件夹复制到原项目目录，同名的项目代码选择替换，文件夹合并。不要删除原项目的 `assets` 文件夹；你已放好的模型、头像和明信片继续沿用。
3. 将你原素材里的 **`游戏标题.png`** 复制到 **`assets/ui/`**，保留中文文件名。这样开始页会显示你发来的原图。也兼容 `assets/ui/game_logo.png`。
4. 用 Godot 打开原项目的 `project.godot`，等待 Import，按 **F5**。先出现开始页，再进入动物选择。
5. 点击毛冠鹿进入森林，可以观察多只鹿；点“林间生命”查看性格与关系，点“生成生命纪录片”整理并观看视频。

**素材状态说明：** 你本地已放好的 GLB、头像和明信片没有上传到本次云工作区，因此 GitHub 包仍没有这些原文件。游戏图标目前只有聊天内展示图，工具没有原图文件路径，所以本地复制 `游戏标题.png` 这一步仍需你做。代码会自动读取；缺少图标时显示文字标题。用户视频已完整接入。森林/鹿模型适配、动画名和真实地形导航仍需在你的电脑上检查。

## 新安装

用 Godot **4.3+** 项目管理器导入 `project.godot`，等资源导入后 F5。本次验证引擎是 **4.6.3**。无需 Godot 插件、服务器、API 或 Python 后端。

默认素材槽位：

| 原素材 | 项目路径 |
|---|---|
| 毛冠鹿模型 | `assets/models/tufted_deer.glb` |
| 场景模型 | `assets/environment/forest.glb` |
| 游戏标题.png | `assets/ui/游戏标题.png` |
| 毛冠鹿 / 欧亚水獭 / 猪獾 / 松貂头像 | `assets/ui/animals/tufted_deer.png`、`otter.png`、`hog_badger.png`、`marten.png` |
| 第一次见面 / 第一次探索 / 新的朋友 | `assets/postcards/first_meeting.png`、`first_exploration.png`、`new_companion.png` |
| 已接入纪录片 | `assets/video/tufted_deer_documentary.ogv` |

其他路径、模型比例和方向可在 `data/assets.json` 修改。GLTF 外部贴图/BIN 必须保持相对目录关系，推荐 GLB。

## 操作与演示

WASD 缓慢移动，Q/E 升降，按住右键环顾，滚轮调速，ESC 暂停。明信片、林间生命和收藏打开时世界暂停。

默认不会显示任务、相机拍摄玩法、日志或评分。三张明信片可由任意在场毛冠鹿完成主动见面、探索或双向满好感后的玩耍。

Debug：选中 Game.tscn 的 Game，开启 Debug Mode，或 `godot --path . -- --debug-demo`。F1 准备见面、F2 探索、F3 准备双向满好感伙伴、F4 清空全部存档与生成档案。F1 会显式清除小栗的惊吓记忆以便演示；正常游戏没有这个人格/关系修改按钮。

`data/assets.json` 的 `documentary_demo_access` 默认为 true，表示演示可随时生成。改为 false 则恢复“集齐三张才能生成”的正式流程。

## 代码、存档与测试

[中文搭建说明](docs/搭建说明.md) · [新版说明与 AI 参数](docs/新版说明.md) · [验证报告](docs/验证报告.md)

正常存档：`user://hidden_wildlife_save.json`；生成的个人档案：`user://hidden_wildlife_documentary.json`。旧版明信片进度自动迁移到版本 3；新动物记忆独立保存。游戏未使用网络请求。

```bash
# Linux/macOS；测试使用独立存档，按顺序执行。
HWA_TEST=1 godot --headless --path . --fixed-fps 60 --scene res://tests/Smoke.tscn
HWA_TEST=1 godot --headless --path . --fixed-fps 60 --scene res://tests/AnimalMinds.tscn
HWA_TEST=1 godot --headless --path . --fixed-fps 60 --scene res://tests/EventRules.tscn
HWA_TEST=1 godot --headless --path . --fixed-fps 60 --scene res://tests/CollisionWorld.tscn
HWA_TEST=1 godot --headless --path . --fixed-fps 60 --scene res://tests/NaturalFlow.tscn
HWA_TEST=1 godot --headless --path . --fixed-fps 60 --scene res://tests/Interactions.tscn
# 带音轨的视频使用实际时间验证，不加 --fixed-fps：
HWA_TEST=1 godot --headless --path . --scene res://tests/SuppliedVideo.tscn
python tests/test_import_assets.py
```

Windows PowerShell 先执行 `$env:HWA_TEST="1"`，再运行上面不含 `HWA_TEST=1` 前缀的 godot 命令，完成后 `Remove-Item Env:HWA_TEST`。图形模式可覆盖指针捕获和旋转；headless 中这两项会明确跳过。

可选的本地 ZIP 导入工具：`python tools/import_assets.py "隐秘生命档案资产.zip"` 仅检查；加 `--apply` 导入。工具需要 Python 3.11+；游戏不需要 Python。多候选文件不猜测、已有不同文件不覆盖。新版本支持识别 `游戏标题.png`。
