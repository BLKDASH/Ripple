var targetDirectoryPage = null;

function Component()
{
    component.loaded.connect(this, this.installerLoaded);
    installer.setValue("StyleSheet", "style.qss");
}

var Dir = new function () {
    this.toNativeSparator = function (path) {
        if (systemInfo.productType === "windows")
            return path.replace(/\//g, '\\');
        return path;
    };
};

Component.prototype.installerLoaded = function()
{
    // 隐藏默认目标目录页，用自定义页面替代
    installer.setDefaultPageVisible(QInstaller.TargetDirectory, false);

    // 插入自定义目标目录页面
    installer.addWizardPage(component, "TargetWidget", QInstaller.ComponentSelection);

    targetDirectoryPage = gui.pageWidgetByObjectName("DynamicTargetWidget");
    if (targetDirectoryPage != null) {
        targetDirectoryPage.windowTitle = "选择安装目录";
        targetDirectoryPage.description.setText("请选择凌波的安装位置。");
        targetDirectoryPage.targetDirectory.textChanged.connect(this, this.targetDirectoryChanged);
        targetDirectoryPage.targetDirectory.setText(Dir.toNativeSparator(installer.value("TargetDir")));
        targetDirectoryPage.targetChooser.released.connect(this, this.targetChooserClicked);
    }

    // 在"准备安装"页面上嵌入桌面快捷方式复选框
    if (systemInfo.productType === "windows") {
        installer.setValue("CreateDesktopShortcut", "true");
        installer.addWizardPageItem(component, "ShortcutPage", QInstaller.ReadyForInstallation);

        var shortcutWidget = gui.pageWidgetByObjectName("ShortcutPageWidget");
        if (shortcutWidget != null) {
            shortcutWidget.desktopShortcutCheckBox.toggled.connect(this, this.onDesktopShortcutToggled);
        }
    }

    gui.pageById(QInstaller.ComponentSelection).entered.connect(this, this.componentSelectionPageEntered);
}

Component.prototype.onDesktopShortcutToggled = function(checked)
{
    if (checked) {
        installer.setValue("CreateDesktopShortcut", "true");
    } else {
        installer.setValue("CreateDesktopShortcut", "false");
    }
}

Component.prototype.targetChooserClicked = function()
{
    var dir = QFileDialog.getExistingDirectory("", targetDirectoryPage.targetDirectory.text);
    if (dir !== "") {
        targetDirectoryPage.targetDirectory.setText(Dir.toNativeSparator(dir));
    }
}

Component.prototype.targetDirectoryChanged = function()
{
    var dir = targetDirectoryPage.targetDirectory.text;
    installer.setValue("TargetDir", dir);

    var hasMaintenance = installer.fileExists(dir + "/RippleMaintenanceTool.exe");
    var installerFiles = [];
    if (systemInfo.productType === "windows") {
        installerFiles = QDesktopServices.findFiles(dir, "Ripple_*_Installer.exe");
    }

    if (installerFiles.length > 0) {
        targetDirectoryPage.warning.setText(
            '<p style="color: red">'
            + '检测到安装程序文件，请复制到其他位置后再安装。'
            + '</p>'
        );
    } else if (hasMaintenance) {
        targetDirectoryPage.warning.setText(
            '<p style="color: orange">'
            + '检测到旧版本，将先卸载再覆盖安装。'
            + '</p>'
        );
    } else if (installer.fileExists(dir)) {
        targetDirectoryPage.warning.setText(
            '<p style="color: #666">目标目录已存在，将直接写入。</p>'
        );
    } else {
        targetDirectoryPage.warning.setText("");
    }
}

Component.prototype.componentSelectionPageEntered = function()
{
    var dir = installer.value("TargetDir");
    if (!dir)
        return;

    var maintenanceTool = Dir.toNativeSparator(dir + "/RippleMaintenanceTool.exe");
    if (installer.fileExists(maintenanceTool)) {
        console.log("检测到旧版本，执行维护工具 purge：" + maintenanceTool);
        var result = installer.execute(maintenanceTool, ["purge"], "yes");
        console.log("purge 执行结果：" + result);
    }
}

Component.prototype.createOperations = function()
{
    component.createOperations();

    if (systemInfo.productType === "windows") {
        // 1. 清理 HKCU Uninstall 下所有 Ripple/凌波 相关的 GUID 条目
        try {
            var result = installer.execute("cmd", "/c", "reg query HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall /s /f \"Ripple\" 2>nul");
            if (result) {
                var output = typeof result === "string" ? result : (result[1] || "");
                var lines = output.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.indexOf("HKEY_CURRENT_USER") !== -1 && line.indexOf("Uninstall") !== -1) {
                        var match = line.match(/Uninstall\\([{][0-9a-fA-F\-]+[}])/);
                        if (match) {
                            var guid = match[1];
                            try {
                                installer.execute("cmd", "/c", "reg delete \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\" + guid + "\" /f");
                                console.log("Deleted HKCU Uninstall entry: " + guid);
                            } catch(e) {}
                        }
                    }
                }
            }
        } catch (e) {
            console.log("Failed to clean HKCU Uninstall: " + e);
        }

        // 2. 清理 HKLM Uninstall
        try {
            var result2 = installer.execute("cmd", "/c", "reg query HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall /s /f \"Ripple\" 2>nul");
            if (result2) {
                var output2 = typeof result2 === "string" ? result2 : (result2[1] || "");
                var lines2 = output2.split("\n");
                for (var j = 0; j < lines2.length; j++) {
                    var line2 = lines2[j].trim();
                    if (line2.indexOf("HKEY_LOCAL_MACHINE") !== -1 && line2.indexOf("Uninstall") !== -1) {
                        var match2 = line2.match(/Uninstall\\([{][0-9a-fA-F\-]+[}])/);
                        if (match2) {
                            var guid2 = match2[1];
                            try {
                                installer.execute("cmd", "/c", "reg delete \"HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\" + guid2 + "\" /f");
                                console.log("Deleted HKLM Uninstall entry: " + guid2);
                            } catch(e) {}
                        }
                    }
                }
            }
        } catch (e) {}

        // 3. 清理 UFH\SHC 中的 Ripple 快捷方式缓存
        try {
            var ufhResult = installer.execute("cmd", "/c", "reg query \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\UFH\\SHC\" 2>nul");
            if (ufhResult) {
                var ufhOutput = typeof ufhResult === "string" ? ufhResult : (ufhResult[1] || "");
                var ufhLines = ufhOutput.split("\n");
                for (var k = 0; k < ufhLines.length; k++) {
                    var ufhLine = ufhLines[k].trim();
                    if (/^\d+\s/.test(ufhLine)) {
                        var parts = ufhLine.split(/\s+/);
                        var valName = parts[0];
                        if (ufhLine.indexOf("Ripple") !== -1) {
                            try {
                                installer.execute("cmd", "/c", "reg delete \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\UFH\\SHC\" /v " + valName + " /f");
                                console.log("Deleted SHC value: " + valName);
                            } catch(e) {}
                        }
                    }
                }
            }
        } catch (e) {}

        // 4. 清理 AppListBackup
        try {
            var bakResult = installer.execute("cmd", "/c", "reg query \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\AppListBackup\" 2>nul");
            if (bakResult) {
                var bakOutput = typeof bakResult === "string" ? bakResult : (bakResult[1] || "");
                var bakLines = bakOutput.split("\n");
                for (var m = 0; m < bakLines.length; m++) {
                    var bakLine = bakLines[m].trim();
                    if (bakLine.indexOf("ListOfEventDriven") !== -1) {
                        var bakParts = bakLine.split(/\s+/);
                        var bakName = bakParts[0];
                        try {
                            var valResult = installer.execute("cmd", "/c", "reg query \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\AppListBackup\" /v " + bakName + " 2>nul");
                            if (valResult) {
                                var valStr = typeof valResult === "string" ? valResult : (valResult[1] || "");
                                if (valStr.indexOf("Ripple") !== -1) {
                                    installer.execute("cmd", "/c", "reg delete \"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\AppListBackup\" /v " + bakName + " /f");
                                    console.log("Deleted AppListBackup value: " + bakName);
                                }
                            }
                        } catch(e) {}
                    }
                }
            }
        } catch (e) {}
    }

    // 5. 创建快捷方式
    if (systemInfo.productType === "windows") {
        component.addOperation("CreateShortcut",
            "@TargetDir@/bin/appRipple.exe",
            "@StartMenuDir@/凌波.lnk",
            "workingDirectory=@TargetDir@/bin",
            "description=启动凌波");

        if (installer.value("CreateDesktopShortcut") === "true") {
            component.addOperation("CreateShortcut",
                "@TargetDir@/bin/appRipple.exe",
                "@DesktopDir@/凌波.lnk",
                "workingDirectory=@TargetDir@/bin",
                "description=启动凌波");
        }
    }
};
