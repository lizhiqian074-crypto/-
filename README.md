# 隐秘生命档案 · Hidden Wildlife Archive

可以直接用 Godot 打开的离线 3D 生态观察 Demo。玩家不操控动物；毛冠鹿会自主游走、觅食、休息、警觉、观察，逐渐主动见面、探索和认识伙伴。

**当前交付的资源状态：** 用户上传的「隐秘生命档案资产.zip」超过本次下载工具 32 MiB 上限，未能读取，现有模型、图片、视频没有集成或验证。项目使用明确标注的临时几何占位和缺失资源提示。没有重新生成用户的模型、头像、明信片或纪录片。把原资产导入后可替换占位；真实森林的比例、材质、动画、地形和导航仍需适配。

## 快速运行

1. 安装 Godot **4.3 或以上**（本次实际验证：4.6.3）。不需要插件、服务器或 API。
2. 解压整个项目，Godot 项目管理器中点「导入」，选择 `project.godot`。
3. 等待资源导入，按 **F5 运行项目**。默认进入主页。
4. 点击毛冠鹿，再点击「进入观察」。保持初始视角静止即可观察完整流程；每张明信片弹出后点击「继续观察」。默认节奏在测试中约 2–3 分钟走完，但会因自主随机决策和玩家行为而变化。
5. 想快速演示：打开 `scenes/Game.tscn`，选中 Game 的 `Debug Mode` 设为开启，再 F5；也可以命令行 `godot --path . -- --debug-demo`。

操作：WASD 缓慢移动；Q 下降，E 上升；按住鼠标右键环顾；滚轮调速；ESC 暂停/释放鼠标。明信片和收藏页打开时 ESC 关闭对应页面。

## 导入你的 ZIP

最直接的方式：解压你自己的 ZIP，将文件放入下面的路径，或在 `data/assets.json` 修改路径。GLTF 的外部贴图和 BIN 必须保持相对目录关系，推荐自带材质的 GLB。

| 内容 | 默认文件位置 |
|---|---|
| 毛冠鹿（主角和伙伴共用） | `assets/models/tufted_deer.glb` |
| 森林 | `assets/environment/forest.glb` |
| 四种动物头像 | `assets/ui/animals/tufted_deer.png`、`otter.png`、`hog_badger.png`、`marten.png` |
| 三张完整明信片 | `assets/postcards/first_meeting.png`、`first_exploration.png`、`new_companion.png` |
| 最终纪录片 | `assets/video/tufted_deer_documentary.ogv` |
| 可选环境音 | `assets/audio/forest_ambience.ogg` |

也可使用随附的**本地工具**，不受本次聊天的 32 MiB 限制。工具需要 Python 3.11+，但游戏运行不需要 Python：

```bash
# 在 project.godot 所在文件夹执行。先查看文件和可识别的映射，不修改文件。
python tools/import_assets.py "隐秘生命档案资产.zip"
# 核对映射后导入；原目录结构保存在 assets/imported/ 下。
python tools/import_assets.py "隐秘生命档案资产.zip" --apply
```

工具只复制媒体，不复制或执行 ZIP 中的脚本/场景/指令。无法唯一识别的名字不会瞎猜；编辑 `data/assets.json`，或者创建一个 `mapping.json`，将工具输出的 `res://...` 路径填入对应字段后执行：

```bash
python tools/import_assets.py "隐秘生命档案资产.zip" --mapping mapping.json --apply
```

映射示例（**路径应替换为实际检查输出**）：

```json
{
  "deer_model": "res://assets/imported/隐秘生命档案资产/模型/毛冠鹿.glb",
  "forest_model": "res://assets/imported/隐秘生命档案资产/模型/森林.glb",
  "portraits.otter": "res://assets/imported/隐秘生命档案资产/头像/水獭.png",
  "postcards.FIRST_MEETING": "res://assets/imported/隐秘生命档案资产/明信片/第一次见面.png"
}
```

如果视频是 MP4，需要先转换为 Godot 原生支持的 **Ogg Theora（.ogv）**。安装本地 FFmpeg 后：

```bash
python tools/convert_video.py "原始纪录片.mp4"
```

不会覆盖已存在的视频。导入工具不自动转码；MP4 不会被误当成可播放的纪录片。若自动映射曾指向其他 OGV，转换后需将 `documentary` 路径改回默认。

## 开发、配置与检查

完整项目结构、场景树、脚本职责、Project Settings、资源连接、导航烘焙、事件配置、明信片原图显示、从空项目搭建步骤与测试清单见 [中文搭建说明](docs/搭建说明.md)。

实际测试结果见 [验证报告](docs/验证报告.md)。游戏无需联网；中文字体为 Noto Sans CJK 子集，许可保留于 `assets/fonts/LICENSE.txt`。

```bash
# 安全的测试使用独立存档，不影响真实玩家进度。
# Linux / macOS：
HWA_TEST=1 godot --headless --path . --fixed-fps 60 --scene res://tests/Smoke.tscn
HWA_TEST=1 godot --headless --path . --fixed-fps 60 --scene res://tests/NaturalFlow.tscn
HWA_TEST=1 godot --headless --path . --fixed-fps 60 --scene res://tests/Interactions.tscn
python tests/test_import_assets.py
# Windows PowerShell：
$env:HWA_TEST="1"
godot --headless --path . --fixed-fps 60 --scene res://tests/Smoke.tscn
Remove-Item Env:HWA_TEST
```

正常存档：`user://hidden_wildlife_save.json`。编辑器菜单「项目 → 打开用户数据文件夹」可查看。不要删项目代码来重置；Debug Mode 下 F4 清空进度。
