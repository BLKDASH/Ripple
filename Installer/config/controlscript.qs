function Controller()
{
    // 自动回答"目标目录已存在，是否覆盖？"类消息框，允许在原路径上覆盖安装
    installer.setMessageBoxAutomaticAnswer("OverwriteTargetDirectory", QMessageBox.Yes);

    // 更新/卸载过程中若需要停止相关进程，自动忽略（由安装脚本负责处理）
    installer.setMessageBoxAutomaticAnswer("stopProcessesForUpdates", QMessageBox.Ignore);
}
