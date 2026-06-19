# 凌波 / Ripple 注册表残留报告

> 扫描时间：2026-06-19
> 扫描范围：当前用户注册表
> 问题原因：每次覆盖安装生成新的 Product GUID，旧条目未被清理，导致大量重复残留

---

## 目录

1. [HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall](#1-hkcusoftwaremicrosoftwindowscurrentversionuninstall--17个重复项)
2. [HKU\AppListBackup](#2-hkuapplistbackup--13个备份项)
3. [HKU\UFH\SHC](#3-hkuufhshc--17个快捷方式历史记录)
4. [残留统计](#残留统计)
5. [修复建议](#修复建议)

---

## 1. HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall — 17个重复项

**完整路径：**
```
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall
```

此处共有 **17 个** GUID 子项，均为"凌波"的卸载记录，版本混杂（0.1.0 / 1.0.0），指向同一安装目录 `C:\Program Files\Ripple`。

### 详细列表

| 子项 (GUID) | 版本 | 安装时间 | 安装目录 |
|-------------|------|----------|----------|
| `{0f092eae-a44e-4dbb-b2bc-da5528b11443}` | 1.0.0 | 2026-06-19 23:16:34 | `C:\Program Files\Ripple` |
| `{0ffb713f-3466-4c3b-bc45-19c21dd1575e}` | 1.0.0 | 2026-06-19 22:50:28 | `C:\Program Files\Ripple` |
| `{1f4c018e-3cb2-4e86-913c-1d12f957196a}` | 0.1.0 | 2026-06-19 20:26:37 | `C:\Program Files\Ripple` |
| `{23fc823e-8a93-4619-bc6d-b44b0abc6132}` | 0.1.0 | 2026-06-19 19:51:01 | `C:\Program Files\Ripple` |
| `{2c6755af-59d6-4a2d-b7bf-08aeb2887d70}` | 0.1.0 | 2026-06-19 20:27:43 | `C:\Program Files\Ripple` |
| `{2fbcef20-efd4-4c57-96d7-0d796287f624}` | 0.1.0 | 2026-06-19 18:36:46 | `\Ripple` (路径异常) |
| `{4ce9e047-12f2-411a-9d0d-a2bc2a6d464f}` | 0.1.0 | 2026-06-19 20:33:45 | `C:\Program Files\Ripple` |
| `{56933fe3-70b5-4b2d-8c75-716a8ebdd62e}` | 1.0.0 | 2026-06-19 23:08:40 | `C:\Program Files\Ripple` |
| `{67aa4c56-de87-42d7-bc98-e8ad30ed2714}` | 0.1.0 | 2026-06-19 19:34:58 | `C:\Program Files\Ripple` |
| `{8e793c4c-06fa-4955-93f3-a15a9d984e5e}` | 1.0.0 | 2026-06-19 23:17:47 | `C:\Program Files\Ripple` |
| `{954e5496-8a09-466b-95b4-72d3eb2d5381}` | 0.1.0 | 2026-06-19 19:40:07 | `C:\Program Files\Ripple` |
| `{b5a06b17-3a95-4196-9b98-c841b8a27784}` | 1.0.0 | 2026-06-19 22:43:29 | `C:\Program Files\Ripple` |
| `{bcb726b9-f1cc-4631-8ee3-3af8b9a2cf2c}` | 0.1.0 | 2026-06-19 18:44:53 | `C:\Program Files\Ripple` |
| `{c8d771e2-6ad6-4d09-b471-71903f5d4ca0}` | 0.1.0 | 2026-06-19 19:31:37 | `C:\Program Files\Ripple` |
| `{d427fbb2-8e93-4ee6-baac-79b1f4925f4c}` | 0.1.0 | 2026-06-19 18:59:00 | `C:\Program Files\Ripple` |
| `{f48fbf3f-c3be-425e-909c-1373a9565b26}` | 1.0.0 | 2026-06-19 23:09:19 | `C:\Program Files\Ripple` |
| `{f4cf972e-582b-4fc8-803a-92ba3f2f573a}` | 0.1.0 | 2026-06-19 20:15:22 | `C:\Program Files\Ripple` |

### 公共字段示例

```
DisplayName: 凌波
DisplayVersion: 0.1.0 / 1.0.0
DisplayIcon: C:\Program Files\Ripple\RippleMaintenanceTool.exe
Publisher: Ripple
UrlInfoAbout: https://github.com/BLKDASH
UninstallString: "C:\Program Files\Ripple\RippleMaintenanceTool.exe" --start-uninstaller
NoRepair: 1
```

---

## 2. HKU\AppListBackup — 13个备份项

**完整路径：**
```
HKEY_USERS\S-1-5-21-1682122225-1083331270-3844410850-1001
  \Software\Microsoft\Windows\CurrentVersion\AppListBackup
```

此处为 Windows 开始菜单应用列表备份，包含 **3 个应用备份**和 **10 个磁贴备份**，均指向 Ripple / 凌波。

### 2a. 应用备份（ListOfEventDrivenBackedUpApps_*）

| 子项 | 内容摘要 |
|------|----------|
| `ListOfEventDrivenBackedUpApps_3765795246` | `{0f092eae-a44e-4dbb-b2bc-da5528b11443}`, Ripple, 1.0.0, action=1 |
| `ListOfEventDrivenBackedUpApps_3765812329` | `{8e793c4c-06fa-4955-93f3-a15a9d984e5e}`, Ripple, 1.0.0, action=0 |
| `ListOfEventDrivenBackedUpApps_3765867924` | `{8e793c4c-06fa-4955-93f3-a15a9d984e5e}`, Ripple, 1.0.0, action=1 |

### 2b. 磁贴备份（ListOfEventDrivenBackedUpTiles_*）

| 子项 | action | 内容摘要 |
|------|--------|----------|
| `ListOfEventDrivenBackedUpTiles_3763751017` | 1 | `C:\Program Files\Ripple\bin\appRipple.exe`, 凌波 |
| `ListOfEventDrivenBackedUpTiles_3764170010` | 1 | `C:\Program Files\Ripple\bin\appRipple.exe`, 凌波 |
| `ListOfEventDrivenBackedUpTiles_3764285724` | 1 | `C:\Program Files\Ripple\bin\appRipple.exe`, 凌波 |
| `ListOfEventDrivenBackedUpTiles_3764775880` | 2 | 空数据（残留） |
| `ListOfEventDrivenBackedUpTiles_3765115729` | 0 | `C:\Program Files\Ripple\bin\appRipple.exe`, 凌波 |
| `ListOfEventDrivenBackedUpTiles_3765234811` | 2 | 空数据（残留） |
| `ListOfEventDrivenBackedUpTiles_3765262063` | 0 | `C:\Program Files\Ripple\bin\appRipple.exe`, 凌波 |
| `ListOfEventDrivenBackedUpTiles_3765301078` | 1 | `C:\Program Files\Ripple\bin\appRipple.exe`, 凌波 |
| `ListOfEventDrivenBackedUpTiles_3765736388` | 1 | `C:\Program Files\Ripple\bin\appRipple.exe`, 凌波 |
| `ListOfEventDrivenBackedUpTiles_3765808997` | 1 | `C:\Program Files\Ripple\bin\appRipple.exe`, 凌波 |

### 公共字段

```json
{
  "tileId": "W~{6D809377-6AF0-444B-8957-A3773F02200E}\\Ripple\\bin\\appRipple.exe",
  "displayName": "凌波",
  "suiteName": "Ripple",
  "targetPath": "C:\\Program Files\\Ripple\\bin\\appRipple.exe",
  "publisher": "Ripple",
  "productUrl": "https://github.com/BLKDASH"
}
```

---

## 3. HKU\UFH\SHC — 17个快捷方式历史记录

**完整路径：**
```
HKEY_USERS\S-1-5-21-1682122225-1083331270-3844410850-1001
  \Software\Microsoft\Windows\CurrentVersion\UFH\SHC
```

SHC 是 Windows 的 **User File History / Shell History Cache**（快捷方式历史缓存），用于记录开始菜单快捷方式的变更历史。此键下共有 **25 个值**，其中 **17 个**与 Ripple/凌波 相关。

### 详细列表

| 键名 | 快捷方式路径 | 目标程序 |
|------|-------------|----------|
| `8` | `C:\Users\dengy\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Ripple\凌波.lnk` | `C:\Ripple\bin\appRipple.exe` (旧路径) |
| `9` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `10` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `11` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `12` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `13` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `14` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `15` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `16` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `17` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `18` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `19` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `20` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `21` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `22` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `23` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |
| `24` | `...Ripple\凌波.lnk` | `C:\Program Files\Ripple\bin\appRipple.exe` |

> 注：键 `8` 使用的是旧路径 `C:\Ripple\bin\appRipple.exe`（可能是早期安装或开发环境），键 `9`~`24` 共 **16 条**均指向 `C:\Program Files\Ripple\bin\appRipple.exe`。

---

## 残留统计

| 路径 | 残留数量 | 类型 |
|------|----------|------|
| `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall` | **17** | 卸载程序重复项（GUID 各不相同） |
| `HKU\...\AppListBackup` | **13** | 开始菜单应用/磁贴备份 |
| `HKU\...\UFH\SHC` | **17** | 快捷方式历史缓存 |
| **总计** | **约 47** | — |

---

## 修复建议

### 方案一：手动清理（立即可做）

1. 按 `Win + R`，输入 `regedit`，回车打开注册表编辑器
2. 导航到 `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall`
3. 删除上述 17 个 GUID 子项（保留最新安装的那个即可）
4. 导航到 `HKEY_USERS\S-1-5-21-...\Software\Microsoft\Windows\CurrentVersion\AppListBackup`
5. 删除包含 Ripple/凌波的备份值
6. 导航到 `HKEY_USERS\S-1-5-21-...\Software\Microsoft\Windows\CurrentVersion\UFH\SHC`
7. 删除键 `8` ~ `24`（保留最新的 1 条即可，或全部删除让系统重建）

### 方案二：安装程序修复（根治问题）

问题根因：**每次安装都生成新的随机 ProductCode（GUID）**，Windows 把它们视为不同产品，导致条目累积。

建议修改安装程序（如 WiX / MSI / Inno Setup）：

- **固定 ProductCode**：使用固定的 GUID，不要每次随机生成
- **使用 UpgradeCode**：让 MSI 安装时自动检测旧版本并升级（`RemoveExistingProducts`）
- **升级逻辑**：在自定义安装器中先读取注册表 `Uninstall` 下的旧 GUID，调用卸载后再安装

这样每次覆盖安装时，旧条目会被自动替换，不会再产生累积。

### 方案三：生成自动清理脚本

如果你需要，我可以为你生成一个 `.reg` 文件或 PowerShell 脚本，一键删除上述残留。确认后我可以立即生成。

---

*报告生成完成。*
