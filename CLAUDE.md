# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 写在最前

注意，Qt框架的所有文档在C:\Qt\Docs
如有不清楚的地方，请查阅qt文档

## 构建命令

本项目没有单元测试。推荐直接在 **Qt Creator** 中打开 `CMakeLists.txt`，选择已配好的 MinGW 套件后点击 **构建 > 重新构建项目**。

如果要从命令行构建（根据实际 Qt 安装路径调整）：

```bash
# 1. 配置（首次或新增/删除 QML 文件时必须执行）
cmake -G "MinGW Makefiles" \
  -B build/Desktop_Qt_6_11_1_MinGW_64_bit-Release \
  -S . \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=C:/Qt/6.11.1/mingw_64 \
  -DCMAKE_MAKE_PROGRAM=C:/Qt/Tools/mingw1310_64/bin/mingw32-make.exe \
  -DCMAKE_CXX_COMPILER=C:/Qt/Tools/mingw1310_64/bin/g++.exe

# 2. 编译
cmake --build build/Desktop_Qt_6_11_1_MinGW_64_bit-Release

# 3. 部署（将 QML 模块、DLL、插件打包到 exe 同级目录）
cmake --install build/Desktop_Qt_6_11_1_MinGW_64_bit-Release --prefix ./deploy/release
```

> **注意：** 新增或删除 `.qml` 文件后，务必先 **重新配置 CMake**（Qt Creator 中右键项目 → 重新构建；命令行下删除构建目录后重新执行 `cmake -B ...`），否则运行时会出现 `module "Ripple.xxx" is not installed` 错误。

## 架构

**凌波** — 跨平台桌面串口调试工具。基于 Qt 6.8+，采用 C++ 后端 / QML 前端分离架构。

### 线程模型

串口 I/O 运行在**独立 QThread** 上，确保高波特率（实测最高 921600）下 UI 不卡顿。主线程负责 QML 渲染和数据模型。

```
工作线程 (SerialWorker)                    主线程
───────────────────────────              ──────────────────────────
QSerialPort::readyRead
  → SerialWorker::readData()
  → 累积到 m_pendingBatch
  → 达到阈值后刷新（200条 / 4KB / 50ms）
  → 发射 batchDataReady(QVariantList)  →  ReceiveModel::appendBatch()
                                        →  ReceivePane.qml 中的 ListView 更新
```

`SerialPortManager` 中所有对 QML 暴露的方法都通过 `QMetaObject::invokeMethod` + `Qt::QueuedConnection` 将调用封送到工作线程执行。

### C++ 核心类

| 类 | 职责 | 所在线程 |
|---|---|---|
| `SerialPortManager` | QML 单例（`Ripple.Serial`），线程持有者，暴露属性和 invokable 方法 | 主线程 |
| `SerialWorker` | 持有 `QSerialPort`，负责所有 I/O、数据批处理、录制、自动日志 | 工作线程 |
| `ReceiveModel` | `QAbstractListModel` 单例（`Ripple.Receive`），接收数据的唯一数据源 | 主线程 |
| `Translator` | 国际化单例（`Ripple.I18n`），运行时加载 `.qm` 文件 | 主线程 |

### SerialWorker 数据批处理

三种阈值触发向 UI 的批次刷新：
- **200 条记录**（每条记录对应一个换行分隔的行）
- **4096 字节**待处理原始数据
- **50 ms 定时器**自上次刷新后到期

此外串口打开后有 **150 ms 预热期**，用于丢弃线路上残留的噪声数据。

### ReceiveModel 缓冲区管理

- `maxRecords`（默认 50,000）和 `maxBufferMb`（默认 32 MB）两个上限
- 超限时从 `std::deque<Record>` 头部删除最旧数据，裁剪到约 75% 上限
- 支持文本模式（UTF-8）、HEX 模式（每行 16 字节，空格分隔），以及可选 `[HH:mm:ss.zzz]` 时间戳

### QML 布局

`Main.qml` → 三栏 `RowLayout`：
- **左侧（200px）：** `SerialPortPanel.qml` — 串口/波特率/数据位/停止位/校验位/流控下拉框，使用 `ParamCombo.qml` 组件
- **中间（自适应）：** `ReceivePane.qml` — `ListView` 绑定 `ReceiveModel`，自定义文字选择（叠加矩形方案，而非 TextArea），HEX/文本/时间戳切换，带锁定检测的自动滚动
- **右侧（280px）：** `SendPane.qml`（文本/HEX 发送，CR/LF/循环发送选项）+ `QuickSendGrid.qml`（可配置快捷发送按钮）

自定义组件：`MainPanel.qml`、`CustomScrollBar.qml`、`ParamCombo.qml`、`QuickSendEditDialog.qml`。

主题与通知通过两个 QML Singleton 集中管理：
- `Theme.qml` — 明暗色板、窗口调色板映射；所有面板/控件统一从这里取色，不再依赖动态作用域。
- `NotificationManager.qml` — 全局通知队列；任何 QML 文件调用 `NotificationManager.error/info/...` 即可弹出 Toast，不再依赖 `Main.qml` 里的 `notify` id。

### 跨线程信号连接（main.cpp）

`SerialPortManager::batchDataReady` 在 `main.cpp` 中直接连接到 `ReceiveModel::appendBatch`。三个单例（`SerialPortManager`、`ReceiveModel`、`Translator`）均在 `main()` 中创建并注册到 QML 引擎，之后才加载 `Main.qml`。`Theme` 与 `NotificationManager` 通过 `qt_add_qml_module` 的 `QT_QML_SINGLETON_TYPE` 属性注册为 QML Singleton。

### 安装包

基于 Inno Setup。先运行 `Installer/deploy.bat` 将构建产物部署到 `Installer/packages/com.ripple.rippleapp/data/`，再在 Inno Setup 中编译 `Installer/innoSetup.iss` 生成安装程序。
