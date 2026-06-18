# CWY Installer（Qt Installer Framework）

本目录存放使用 [Qt Installer Framework](https://doc.qt.io/qtinstallerframework/) 生成离线安装包所需的配置与包数据。

## 目录结构

```
Installer/
├── config/
│   ├── config.xml              # 安装程序全局配置
│   ├── installer-icon.ico      # 安装程序图标（可选，需自行准备）
│   └── installer-icon.png      # 安装程序窗口图标（可选，需自行准备）
├── packages/
│   └── com.cwy.cwyapp/         # 主程序包
│       ├── meta/
│       │   ├── package.xml     # 包元数据
│       │   ├── installscript.qs# 安装脚本（创建快捷方式）
│       │   ├── page.ui         # 自定义安装页面（桌面快捷方式选项）
│       │   └── license.txt     # 许可协议
│       └── data/               # 安装内容（构建时由 CMake install 填充）
│           ├── bin/
│           │   ├── appCWY.exe  # 主程序
│           │   ├── Qt6*.dll    # Qt 运行库
│           │   └── qt.conf
│           ├── qml/            # QML 模块
│           ├── plugins/        # Qt 插件
│           └── translations/   # 翻译文件
└── build_installer.bat         # 一键生成安装包脚本
```

## 前置要求

1. 已安装 Qt Installer Framework，并确保 `binarycreator.exe` 在系统 PATH 中。
2. 项目已通过 CMake 成功构建（建议 Release 模式）。

## 安装程序使用说明

修改后的安装程序支持**在原路径上覆盖升级**。详细使用说明、命令行参数及常见问题请参见：

- [`QIF_USAGE.md`](./QIF_USAGE.md)

## 生成安装包

### 方式一：使用提供的批处理脚本（推荐）

```bat
.\Installer\build_installer.bat
```

生成结果：`CWY_SerialAssistant_0.1.0_Installer.exe`

### 方式二：手动执行

1. 将主程序及依赖部署到安装包数据目录（**必须使用绝对路径作为 prefix**，否则 Qt 部署脚本生成 `qt.conf` 会失败）：

   ```bash
   cmake --install build/Desktop_Qt_6_11_1_llvm_mingw_64_bit-Release \
         --prefix "$(pwd)/Installer/packages/com.cwy.cwyapp/data"
   ```

   在 Windows CMD/PowerShell 中可使用完整绝对路径，例如：

   ```bat
   cmake --install build\Desktop_Qt_6_11_1_llvm_mingw_64_bit-Release ^
         --prefix C:\Users\GM\GGPro\cwy\Installer\packages\com.cwy.cwyapp\data
   ```

2. 使用 `binarycreator` 生成安装包：

   ```bash
   binarycreator -c Installer/config/config.xml \
                 -p Installer/packages \
                 -f \
                 CWY_SerialAssistant_0.1.0_Installer.exe
   ```

   说明：
   - `-c`：指定全局配置文件
   - `-p`：指定包目录
   - `-f`：强制覆盖已存在的安装包
   - 最后一个参数为输出文件名

## 注意事项

- `config.xml` 中默认安装目录使用 `@ApplicationsDir@`（即 64 位系统的 `C:\Program Files`），适合本项目的 64 位构建。
- 安装后的程序位于 `bin/appCWY.exe`，`installscript.qs` 中的快捷方式目标也对应为 `@TargetDir@/bin/appCWY.exe`。
- `Installer/packages/com.cwy.cwyapp/data/` 目录在版本控制中仅保留 `.gitkeep`。实际构建时会由 CMake install 步骤填充，请勿手动提交二进制文件。
- 如需修改版本号，请同步更新：
  - `CMakeLists.txt` 中的 `project(CWY VERSION x.x)`
  - `Installer/config/config.xml` 中的 `<Version>`
  - `Installer/packages/com.cwy.cwyapp/meta/package.xml` 中的 `<Version>`
  - `Installer/build_installer.bat` 中的输出文件名
- 目前安装脚本针对 Windows 创建开始菜单快捷方式（始终创建）和桌面快捷方式（安装过程中可在自定义页面选择是否创建）；
  如需支持 macOS/Linux，请扩展 `installscript.qs`。
