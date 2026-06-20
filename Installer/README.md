# 凌波安装包打包流程

本项目使用 [Inno Setup](https://jrsoftware.org/isinfo.php) 生成 Windows 安装包。

## 目录结构

```
Installer/
├── deploy.bat                # 部署脚本：将构建产物及依赖复制到 data 目录
├── deploy.bat.in             # CMake 模板
├── innoSetup.iss             # Inno Setup 打包脚本
├── config/
│   └── installer-icon.ico    # 安装程序图标
└── packages/
    └── com.ripple.rippleapp/
        └── data/             # 由 deploy.bat 生成，勿提交
```

## 前置要求

1. 已通过 CMake 成功构建 **Release** 版本（默认目录 `build/Desktop_Qt_6_11_1_MinGW_64_bit-Release`）。
2. 已安装 Inno Setup。
3. 脚本顶部路径 `CMAKE_DIR` 若与本地 Qt 安装不一致，请自行修改。

## 打包步骤

### 1. 部署应用程序

```bat
.\Installer\deploy.bat
```

脚本会清理并重新填充 `Installer/packages/com.ripple.rippleapp/data/`，包含：

- `bin/appRipple.exe` 及 Qt 运行库
- `qml/`、`plugins/`、`translations/`
- 运行时依赖与帮助文件

### 2. 编译安装包

在 Inno Setup 中打开 `Installer/innoSetup.iss` 并编译，生成的安装包位于：

```
Installer/Ripple_<版本号>_Installer.exe
```

## 注意事项

- `data/` 目录及其中的文件均由构建脚本生成，**不应提交到版本控制**。
- 生成的 `*.exe` 安装包也不应提交。
- 修改版本号时，请同步更新：
  - `CMakeLists.txt` 中的 `project(Ripple VERSION x.x.x)`
  - `Installer/innoSetup.iss` 中的 `#define MyAppVersion "x.x.x"`
