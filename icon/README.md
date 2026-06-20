# icon 目录

应用图标资源目录。

## 文件说明

| 文件 | 用途 |
|---|---|
| `ripple-icon.svg` | 源矢量图标（256×256，浅色背景 + 蓝/红/黄三条波浪动画） |
| `ripple-icon.ico` | Windows 图标文件（6 个尺寸：16/32/48/64/128/256） |
| `app.rc` | Windows 资源文件，将 `.ico` 嵌入到编译后的 `.exe` |

## ICO 生成方式

项目没有使用 ImageMagick 等外部工具，而是通过 **Chrome Headless + Python PIL** 的方式从 SVG 渲染生成：

1. 用 Chrome Headless 模式以白色背景逐尺寸截图（16/32/48/64/128/256）
2. 用 PIL 根据 SVG 中圆角矩形的几何参数创建 4 倍超采样的蒙版，保证边缘平滑
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

## 图标在项目中的使用

以下配置已经集成到项目中，不需要手动添加：

### Windows exe 图标

`app.rc` 内容：

```rc
IDI_ICON1 ICON "ripple-icon.ico"
```

`CMakeLists.txt` 中已将 `icon/app.rc` 加入 `qt_add_executable`，Qt/MinGW 工具链会自动调用 `windres` 编译并链接到 exe。

### 运行时窗口图标

`main.cpp` 中已设置：

```cpp
app.setWindowIcon(QIcon(QStringLiteral(":/qt/qml/Ripple/ripple-icon.svg")));
```

SVG 通过 `qt_add_qml_module` 的 `RESOURCES` 注册到 Qt 资源系统。

## 更新图标流程

1. 修改 `icon/ripple-icon.svg`
2. 运行上方 Python 脚本重新生成 `icon/ripple-icon.ico`
3. 重新构建项目（CMake 会自动重新编译 `.rc` 和资源文件）
4. 如需同时更新安装包图标，请将新的 `.ico` 复制到 `Installer/config/installer-icon.ico`
