var targetDirectoryPage = null;

function Component()
{
    // 注册组件加载完成后的回调，用于插入自定义页面
    component.loaded.connect(this, this.installerLoaded);

    // 美化安装程序样式
    installer.setValue("StyleSheet", "style.qss");
}

// 工具函数：统一路径分隔符为反斜杠（Windows）
var Dir = new function () {
    this.toNativeSparator = function (path) {
        if (systemInfo.productType === "windows")
            return path.replace(/\//g, '\\');
        return path;
    };
};

// 组件加载完成后调用
Component.prototype.installerLoaded = function()
{
    // ---- 1. 替换默认目标目录页面为自定义页面，支持原路径升级 ----
    installer.setDefaultPageVisible(QInstaller.TargetDirectory, false);
    installer.addWizardPage(component, "TargetWidget", QInstaller.TargetDirectory);

    targetDirectoryPage = gui.pageWidgetByObjectName("DynamicTargetWidget");
    targetDirectoryPage.windowTitle = "选择安装目录";
    targetDirectoryPage.description.setText(
        "请选择凌波的安装位置。\n"
        + "如果目标目录已存在旧版本，安装程序会先自动卸载旧版本，再继续安装。"
    );
    targetDirectoryPage.targetDirectory.textChanged.connect(this, this.targetDirectoryChanged);
    targetDirectoryPage.targetDirectory.setText(Dir.toNativeSparator(installer.value("TargetDir")));
    targetDirectoryPage.targetChooser.released.connect(this, this.targetChooserClicked);

    // 进入组件选择页前，若目标目录存在旧版本则先清理
    gui.pageById(QInstaller.ComponentSelection).entered.connect(this, this.componentSelectionPageEntered);

    // ---- 2. 在“准备安装”页面前插入自定义快捷方式选项页 ----
    installer.addWizardPage(component, "ShortcutPage", QInstaller.ReadyForInstallation);
}

// 点击“浏览...”按钮时弹出目录选择对话框
Component.prototype.targetChooserClicked = function()
{
    var dir = QFileDialog.getExistingDirectory("", targetDirectoryPage.targetDirectory.text);
    if (dir !== "") {
        targetDirectoryPage.targetDirectory.setText(Dir.toNativeSparator(dir));
    }
}

// 目标目录发生变化时更新提示信息
Component.prototype.targetDirectoryChanged = function()
{
    var dir = targetDirectoryPage.targetDirectory.text;
    installer.setValue("TargetDir", dir);

    var hasMaintenance = installer.fileExists(dir + "/RippleMaintenanceTool.exe");
    var installerFiles = [];
    if (systemInfo.productType === "windows") {
        // 检测目标目录中是否包含安装程序自身（按常见命名规则）
        installerFiles = QDesktopServices.findFiles(dir, "Ripple_*_Installer.exe");
    }

    if (installerFiles.length > 0) {
        targetDirectoryPage.warning.setText(
            '<p style="color: red">'
            + '检测到目标目录中包含安装程序文件（' + Dir.toNativeSparator(installerFiles[0]) + '）。'
            + '安装程序无法覆盖正在运行的自身，请将该安装程序复制到其他位置后再运行，或选择其他目录。'
            + '</p>'
        );
    } else if (hasMaintenance) {
        targetDirectoryPage.warning.setText(
            '<p style="color: orange">'
            + '检测到目标目录中已存在旧版本，继续安装将先卸载旧版本并覆盖安装。'
            + '</p>'
        );
    } else if (installer.fileExists(dir)) {
        targetDirectoryPage.warning.setText(
            '<p style="color: #666">'
            + '目标目录已存在，安装程序将直接写入该目录。'
            + '</p>'
        );
    } else {
        targetDirectoryPage.warning.setText("");
    }
}

// 进入组件选择页时，若目标目录有旧版本则先静默卸载
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

// 安装完成后创建快捷方式
Component.prototype.createOperations = function()
{
    // 先调用默认实现，确保文件被正确释放
    component.createOperations();

    if (systemInfo.productType === "windows") {
        // 开始菜单快捷方式（始终创建）
        component.addOperation("CreateShortcut",
            "@TargetDir@/bin/appRipple.exe",
            "@StartMenuDir@/凌波.lnk",
            "workingDirectory=@TargetDir@/bin",
            "description=启动凌波");

        // 桌面快捷方式（根据用户复选框选择）
        var shortcutPage = component.userInterface("ShortcutPage");
        if (shortcutPage && shortcutPage.desktopShortcutCheckBox.checked) {
            component.addOperation("CreateShortcut",
                "@TargetDir@/bin/appRipple.exe",
                "@DesktopDir@/凌波.lnk",
                "workingDirectory=@TargetDir@/bin",
                "description=启动凌波");
        }
    }
};
