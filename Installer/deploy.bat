@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: 获取脚本所在目录的绝对路径，并据此得到项目根目录
for %%I in ("%~dp0..") do set "PROJECT_ROOT=%%~fI"
set "INSTALLER_DIR=%~dp0"
set "DATA_DIR=%INSTALLER_DIR%packages\com.ripple.rippleapp\data"
set "BUILD_DIR=%PROJECT_ROOT%\build\Desktop_Qt_6_11_1_MinGW_64_bit-Release"

:: Add CMake to PATH if not already present
set "CMAKE_DIR=C:\Qt\Tools\CMake_64\bin"
if exist "%CMAKE_DIR%" (
    set "PATH=%PATH%;%CMAKE_DIR%"
)

echo ========================================
echo  Deploying Ripple for Inno Setup
echo ========================================

:: 清理旧数据（保留目录本身）
echo [1/2] 清理旧安装数据...
if exist "%DATA_DIR%" (
    rd /s /q "%DATA_DIR%"
)
mkdir "%DATA_DIR%"

:: 使用 CMake install 将主程序及依赖部署到 data 目录
:: 必须使用绝对路径作为 prefix，否则 Qt 部署脚本生成 qt.conf 会失败
echo [2/2] 部署应用程序到安装包数据目录...
if not exist "%BUILD_DIR%" (
    echo [WARN] 未找到 Release 构建目录：%BUILD_DIR%
    echo        将尝试使用默认 build 目录...
    set "BUILD_DIR=%PROJECT_ROOT%\build"
)

cmake --install "!BUILD_DIR!" --prefix "%DATA_DIR%"
if errorlevel 1 (
    echo [ERROR] CMake install 失败。
    exit /b 1
)

echo ========================================
echo  部署完成：%DATA_DIR%
echo  下一步请在 Inno Setup 中编译 innoSetup.iss
echo ========================================

endlocal
