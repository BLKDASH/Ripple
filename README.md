# 凌波

跨平台桌面串口调试工具，基于 Qt 6.11 + QML。

## 环境要求

- Qt 6.11.1（MinGW 64-bit）
- CMake（Qt 自带：`C:\Qt\Tools\CMake_64\bin\cmake.exe`）
- MinGW（Qt 自带：`C:\Qt\Tools\mingw1310_64\bin\mingw32-make.exe`）
- Qt Installer Framework（打包安装程序时使用）

## 构建 Release 版本

```bash
# 1. 配置（首次或新增/删除 QML/C++ 源文件后必须执行）
"C:\Qt\Tools\CMake_64\bin\cmake.exe" -G "MinGW Makefiles" ^
  -B build\Desktop_Qt_6_11_1_MinGW_64_bit-Release ^
  -S . ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_PREFIX_PATH=C:\Qt\6.11.1\mingw_64 ^
  -DCMAKE_MAKE_PROGRAM=C:\Qt\Tools\mingw1310_64\bin\mingw32-make.exe ^
  -DCMAKE_CXX_COMPILER=C:\Qt\Tools\mingw1310_64\bin\g++.exe

# 2. 编译
"C:\Qt\Tools\mingw1310_64\bin\mingw32-make.exe" -C build\Desktop_Qt_6_11_1_MinGW_64_bit-Release -j4
```

> **注意**：新增或删除 `.qml` 文件后，务必先重新配置 CMake，否则运行时会出现 `module "Ripple.xxx" is not installed` 错误。

## 部署（生成可直接运行的目录）

```bash
"C:\Qt\Tools\CMake_64\bin\cmake.exe" --install build\Desktop_Qt_6_11_1_MinGW_64_bit-Release --prefix .\deploy\release
```

部署完成后，`deploy\release\bin\appRipple.exe` 即为可直接运行的 Release 版本，依赖 DLL、QML 模块、插件等都已复制到 `deploy\release` 下。

## 打包 QIF 安装程序

1. 确保已安装 **Qt Installer Framework**（例如 `C:\Qt\Tools\QtInstallerFramework\4.11\bin\binarycreator.exe`）。
2. 运行一键打包脚本：

```bat
.\Installer\build_installer.bat
```

脚本会依次执行：

1. 清理 `Installer\packages\com.ripple.rippleapp\data`
2. 调用 `cmake --install` 把 Release 版本部署到 data 目录
3. 调用 `binarycreator` 生成离线安装包

生成的安装程序位于项目根目录：

```
Ripple_0.1.0_Installer.exe
```

如果 QIF 安装路径不同，请修改 `Installer\build_installer.bat` 顶部的 `QIF_DIR`。

## 日志

程序运行日志默认写入：

```
C:\Users\<用户名>\AppData\Roaming\Ripple\凌波\ripple.log
```

- Debug 构建时日志同时输出到 Qt Creator 的 **Application Output** 面板。
- Release 构建时只写入文件，避免控制台输出。
- 单个日志文件超过 **5 MB** 时会自动轮转，最多保留当前文件和一个 `.old` 备份。
