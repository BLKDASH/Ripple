# 凌波

跨平台桌面串口调试工具，基于 **Qt 6.11** + **QML** + **C++** 构建。

凌波采用 C++ 后端 / QML 前端分离架构，串口 I/O 运行在独立工作线程上，保证高波特率下 UI 依旧流畅。

## 功能特性

- 串口参数配置：波特率、数据位、停止位、校验位、流控
- 文本 / HEX 双模式接收与发送
- 可选时间戳前缀
- 自动日志与录制
- 快捷发送按钮网格
- 明暗主题切换
- 中文界面支持

## 环境要求

- Qt 6.11.1（MinGW 64-bit）
- CMake（Qt 自带）
- MinGW（Qt 自带）
- Inno Setup（打包安装程序时使用）

## 构建 Release 版本

### 方式一：使用 Qt Creator（推荐）

1. 打开 Qt Creator，选择 **打开项目**，定位到本目录下的 `CMakeLists.txt`。
2. 选择已配置好的 **MinGW 64-bit** 套件。
3. 点击左下角构建配置按钮，切换到 **Release** 模式。
4. 选择菜单 **构建 > 重新构建项目**。

构建产物默认位于：

```
build\Desktop_Qt_6_11_1_MinGW_64_bit-Release\appRipple.exe
```

> **注意**：新增或删除 `.qml` 文件后，务必先重新执行 CMake，否则运行时会出现 `module "Ripple.xxx" is not installed` 错误。在 Qt Creator 中可以通过 **构建 > 重新构建项目** 或删除构建目录后重新配置来实现。

### 方式二：命令行

如果偏好命令行，可使用以下命令：

```bat
"C:\Qt\Tools\CMake_64\bin\cmake.exe" -G "MinGW Makefiles" ^
  -B build\Desktop_Qt_6_11_1_MinGW_64_bit-Release ^
  -S . ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_PREFIX_PATH=C:\Qt\6.11.1\mingw_64 ^
  -DCMAKE_MAKE_PROGRAM=C:\Qt\Tools\mingw1310_64\bin\mingw32-make.exe ^
  -DCMAKE_CXX_COMPILER=C:\Qt\Tools\mingw1310_64\bin\g++.exe

"C:\Qt\Tools\mingw1310_64\bin\mingw32-make.exe" -C build\Desktop_Qt_6_11_1_MinGW_64_bit-Release -j4
```

## 部署（生成可直接运行的目录）

运行 CMake install，将 Release 构建产物及依赖复制到 `deploy\release`：

```bat
"C:\Qt\Tools\CMake_64\bin\cmake.exe" --install build\Desktop_Qt_6_11_1_MinGW_64_bit-Release --prefix .\deploy\release
```

部署完成后，`deploy\release\bin\appRipple.exe` 即为可直接运行的 Release 版本，依赖 DLL、QML 模块、插件等都已复制到 `deploy\release` 下。

> 也可以在 Qt Creator 的项目设置中，为当前套件添加一个 **Install** 构建步骤，使其一键完成安装。

## 打包安装程序（Inno Setup）

### 1. 部署到安装包数据目录

直接双击运行：

```
Installer\deploy.bat
```

脚本会自动清理并重新填充 `Installer\packages\com.ripple.rippleapp\data\`，包含主程序、Qt 运行库、QML 模块、插件及翻译文件。

> 如果构建目录或 CMake 路径与本地环境不同，请用文本编辑器修改 `Installer\deploy.bat` 顶部的 `CMAKE_DIR` 和 `BUILD_DIR`。

### 2. 编译安装包

1. 打开 Inno Setup。
2. 选择 **打开**，定位到 `Installer\innoSetup.iss`。
3. 点击工具栏 **运行** 按钮（或按 F9）编译。

生成的安装包位于：

```
Installer\Ripple_<版本号>_Installer.exe
```

## 项目结构

```
.
├── CMakeLists.txt              # 项目构建配置
├── main.cpp                    # 程序入口
├── src/                        # C++ 后端源码
│   ├── serialportmanager.cpp   # 串口管理器（QML 单例）
│   ├── serialworker.cpp        # 串口 I/O 工作线程
│   ├── receivemodel.cpp        # 接收数据模型
│   ├── translator.cpp          # 国际化
│   ├── appsettings.cpp         # 应用设置
│   └── logger.cpp              # 日志
├── qml/                        # QML 前端
│   ├── Main.qml
│   ├── serial/                 # 串口面板
│   ├── receive/                # 接收面板
│   ├── send/                   # 发送面板
│   ├── dialogs/                # 设置/帮助对话框
│   ├── components/             # 自定义控件
│   └── singleton/              # 主题 / 通知管理单例
├── translations/               # 翻译文件
├── help/                       # 帮助文档
├── Installer/                  # 安装包相关
│   ├── deploy.bat              # 部署脚本
│   ├── deploy.bat.in           # CMake 模板
│   ├── innoSetup.iss           # Inno Setup 打包脚本
│   └── config/
│       └── installer-icon.ico
└── icon/                       # 应用图标
```

## 日志

程序运行日志默认写入：

```
C:\Users\<用户名>\AppData\Roaming\Ripple\凌波\ripple.log
```

- Debug 构建时日志同时输出到 Qt Creator 的 **Application Output** 面板。
- Release 构建时只写入文件，避免控制台输出。
- 单个日志文件超过 **5 MB** 时会自动轮转，最多保留当前文件和一个 `.old` 备份。

## 协议

Copyright (C) 2026 Ripple. All rights reserved.

本软件仅供个人学习与非商业用途。未经授权不得用于商业分发。

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
