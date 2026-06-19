# icon 目录

应用图标资源目录。

## 文件说明

| 文件 | 用途 |
|---|---|
| `ripple-icon.svg` | 源矢量图标（256×256，深蓝渐变背景 + 波浪动画） |
| `ripple-icon.ico` | Windows 图标文件（6 个尺寸：16/32/48/64/128/256） |
| `app.rc` | Windows 资源文件，将 `.ico` 嵌入到编译后的 `.exe` |

## ICO 生成方式

项目没有使用 ImageMagick 等外部工具，而是通过 **Chrome Headless + Python PIL** 的方式从 SVG 渲染生成：

1. 用 Chrome Headless 模式以白色背景逐尺寸截图（16/32/48/64/128/256）
2. 用 PIL 根据 SVG 中圆角矩形的几何参数（`x=15, y=15, w=226, h=226, rx=56, ry=56`）创建 4 倍超采样的蒙版，保证边缘平滑
3. 将蒙版应用到截图上，圆角外区域变为透明
4. 将所有尺寸合并保存为 `.ico` 文件

> **注意：** 不要使用品红色背景做色键抠图——Chrome 在小尺寸渲染时的反锯齿会把背景色混入 SVG 边缘，导致图标出现粉红色像素。

如果需要重新生成（例如 SVG 被修改），可以用以下 Python 脚本：

```python
import subprocess, os, io
from PIL import Image, ImageDraw

CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe'
SIZES = [16, 32, 48, 64, 128, 256]
svg_abs = os.path.abspath('icon/ripple-icon.svg').replace('\\', '/')

def render(size):
    html = f'<!DOCTYPE html><html><head><style>body{{margin:0;padding:0;background:white}}img{{width:{size}px;height:{size}px;display:block}}</style></head><body><img src="file:///{svg_abs}"></body></html>'
    hp, pp = f'icon/_t{size}.html', f'icon/_t{size}.png'
    with open(hp, 'w') as f: f.write(html)
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--no-sandbox',
        f'--screenshot={os.path.abspath(pp)}', f'--window-size={size},{size}',
        '--hide-scrollbars', os.path.abspath(hp).replace('\\','/')],
        capture_output=True, timeout=15)
    os.remove(hp)
    if os.path.exists(pp):
        img = Image.open(pp).convert('RGBA').resize((size, size), Image.LANCZOS)
        os.remove(pp)
        return img
    return None

def mask(size):
    s = size / 256.0
    x1, y1, x2, y2 = round(15*s), round(15*s), round(241*s), round(241*s)
    r = round(56*s)
    big = Image.new('L', (size*4, size*4), 0)
    ImageDraw.Draw(big).rounded_rectangle([x1*4, y1*4, x2*4, y2*4], radius=r*4, fill=255)
    return big.resize((size, size), Image.LANCZOS)

images = []
for size in SIZES:
    img = render(size)
    if img:
        result = Image.new('RGBA', (size, size), (0,0,0,0))
        result.paste(img, mask=mask(size))
        images.append(result)

out = io.BytesIO()
images[-1].save(out, format='ICO', sizes=[(s,s) for s in SIZES[:len(images)]], append_images=images[:-1])
with open('icon/ripple-icon.ico', 'wb') as f: f.write(out.getvalue())
```

## 如何嵌入到项目

### 1. Windows exe 图标（资源管理器中显示）

`app.rc` 内容：

```rc
IDI_ICON1 ICON "ripple-icon.ico"
```

在 `CMakeLists.txt` 的 `qt_add_executable` 中添加此文件：

```cmake
qt_add_executable(appRipple
    main.cpp
    icon/app.rc    # ← 添加这一行
    ...
)
```

Qt/MinGW 工具链会自动调用 `windres` 编译 `.rc` 并链接到 exe。

### 2. 运行时窗口图标（标题栏 / 任务栏）

**CMakeLists.txt** — 将 SVG 加入 Qt 资源系统：

```cmake
set_source_files_properties(icon/ripple-icon.svg
    PROPERTIES QT_RESOURCE_ALIAS "ripple-icon.svg")

qt_add_qml_module(appRipple
    URI Ripple
    RESOURCES
        icon/ripple-icon.svg   # ← 添加这一行
    ...
)
```

**main.cpp** — 设置运行时窗口图标（标题栏 / 任务栏）：

```cpp
#include <QIcon>
// ...
app.setWindowIcon(QIcon(QStringLiteral(":/qt/qml/Ripple/ripple-icon.svg")));
```

## 更新图标流程

1. 修改 `ripple-icon.svg`
2. 运行上方 Python 脚本重新生成 `ripple-icon.ico`
3. 在 Qt Creator 中重新构建项目（CMake 会自动重新编译 `.rc` 和资源文件）
