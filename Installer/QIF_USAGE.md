# 凌波 安装程序（QIF）使用说明

本安装程序基于 **Qt Installer Framework（QIF）** 构建，支持常规安装与**原路径覆盖升级**。

---

## 1. 安装包文件

构建产物：

```
Ripple_0.1.0_Installer.exe
```

默认安装位置：

```
C:\Program Files\Ripple
```

---

## 2. 常规安装

双击安装程序，按向导提示操作即可：

1. 欢迎页 → 点击“下一步”
2. 选择安装目录（默认推荐 `C:\Program Files\Ripple`）
3. 选择组件（本安装包只有一个主程序组件，默认勾选）
4. 接受许可协议
5. 选择是否创建桌面快捷方式
6. 点击“安装”

---

## 3. 原路径升级（覆盖安装）

新版安装程序支持**在旧版本安装目录上直接升级**，无需手动卸载。

### 适用场景

- 旧版本安装在 `C:\Program Files\Ripple`
- 运行新版安装程序，目标目录仍选择旧版本所在目录
- 安装程序会自动检测并清理旧版本，然后安装新版本

### 升级流程

1. 运行 `Ripple_0.1.0_Installer.exe`
2. 在“选择安装目录”页面，选择旧版本的安装目录
3. 页面会提示：**“检测到目标目录中已存在旧版本，继续安装将先卸载旧版本并覆盖安装。”**
4. 进入组件选择页后，安装程序会自动调用维护工具（`RippleMaintenanceTool.exe purge`）清理旧版本
5. 继续完成安装

> ⚠️ **注意**：升级过程中旧版本的快捷方式、开始菜单项等会被重新创建。若旧版本正在运行，请先退出，否则可能导致文件被占用。

---

## 4. 重要限制：不能安装到安装程序自身所在目录

安装程序**无法覆盖正在运行的自身**。因此：

- **不要将安装目标目录设置为 `Ripple_0.1.0_Installer.exe` 所在的目录**
- 如果目标目录中包含类似 `Ripple_*_Installer.exe` 的文件，安装程序会提示错误并阻止继续

### 正确做法

| 场景 | 推荐操作 |
|------|---------|
| 安装程序在 `C:\Users\GM\GGPro\ripple\` | 将安装程序复制到桌面或下载目录后再运行，目标目录选择 `C:\Program Files\Ripple` |
| 想安装到项目目录 | 先把安装程序移出该目录，或安装到一个子目录（如 `C:\Users\GM\GGPro\ripple\Ripple`） |
| 想升级旧版本 | 运行安装程序，目标目录选择旧版本的安装目录（不是安装程序所在的目录） |

---

## 5. 命令行调用

安装程序也支持命令行静默安装/升级。

### 静默安装到指定目录

```bat
Ripple_0.1.0_Installer.exe --root "C:\Program Files\Ripple" --confirm-command install
```

参数说明：

- `--root <dir>`：指定安装目标目录
- `--confirm-command`：自动确认所有交互式提示
- `install`：执行安装模式

### 静默升级

```bat
Ripple_0.1.0_Installer.exe --root "C:\Program Files\Ripple" --confirm-command install
```

> 由于安装程序内置了 `OverwriteTargetDirectory` 自动回答为“是”，升级时不会提示覆盖确认。

### 查看所有可用参数

```bat
Ripple_0.1.0_Installer.exe --help
```

---

## 6. 维护工具

安装完成后，目标目录会生成维护工具：

```
C:\Program Files\Ripple\RippleMaintenanceTool.exe
```

可用于：

- 添加/删除组件
- 更新应用（在线模式）
- 完全卸载应用

命令行清理旧版本（开发/测试用）：

```bat
"C:\Program Files\Ripple\RippleMaintenanceTool.exe" purge
```

输入 `yes` 确认后，将删除该目录下的安装记录和文件。

---

## 7. 常见问题

### Q1：提示“您选择的目录已存在且包含安装程序”

**原因**：目标目录中包含了正在运行的安装程序文件。

**解决**：将安装程序移动到其他地方（如桌面），然后重新运行。

### Q2：提示“目标目录已存在安装”

**原因**：目标目录中残留旧版本的维护工具或安装记录。

**解决**：新版安装程序会自动检测并清理旧版本。若仍失败，可手动运行维护工具卸载：

```bat
"目标目录\RippleMaintenanceTool.exe" purge
```

### Q3：安装后没有桌面快捷方式

桌面快捷方式需要在“快捷方式选项”页面手动勾选。开始菜单快捷方式始终会创建。

### Q4：安装程序需要管理员权限吗？

默认安装到 `C:\Program Files` 需要管理员权限。若安装到用户目录（如 `C:\Users\<用户名>\AppData\Local\Ripple`），通常不需要。

---

## 8. 重新构建安装包

如需修改安装配置或升级版本号，执行：

```bat
.\Installer\build_installer.bat
```

或手动执行：

```bat
cmake --install build\Desktop_Qt_6_11_1_llvm_mingw_64_bit-Release --prefix C:\Users\GM\GGPro\ripple\Installer\packages\com.ripple.rippleapp\data

binarycreator --offline-only -c Installer\config\config.xml -p Installer\packages -f Ripple_0.1.0_Installer.exe
```

---

## 9. 相关文件

| 文件 | 说明 |
|------|------|
| `Installer/config/config.xml` | 安装程序全局配置 |
| `Installer/config/controlscript.qs` | 控制脚本，处理自动消息框回答 |
| `Installer/packages/com.ripple.rippleapp/meta/installscript.qs` | 安装脚本，处理目标目录页、快捷方式、旧版本清理 |
| `Installer/packages/com.ripple.rippleapp/meta/targetwidget.ui` | 自定义目标目录选择页面 |
| `Installer/packages/com.ripple.rippleapp/meta/page.ui` | 快捷方式选项页面 |
| `Installer/build_installer.bat` | 一键构建脚本 |
