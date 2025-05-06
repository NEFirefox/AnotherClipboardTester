# 剪贴板测试程序

fork from daimaxiaofeng,用作学习，和*抄点实现*来完成*学校要求的课题*，哎我们的Web开发和神必的软件工程课，~~害人不浅~~
---

> 感谢大家的支持，这里是 [B 站传送门](https://www.bilibili.com/video/BV1zWzwYkEtf/) 。



可直接运行的版本见 Releases 页面。

以下步骤适用于想要修改代码、重新构建程序的小伙伴，**以 Windows 系统为例。**



## 1. 环境配置



需要准备 flutter 开发环境，官方文档写得不错：

* 英文：[Start building Flutter native desktop apps on Windows](https://docs.flutter.dev/get-started/install/windows/desktop)

* 中文：[开始在 Windows 上构建 Flutter 原生桌面应用](https://docs.flutter.cn/get-started/install/windows/desktop)



## 2. 调试 Debug



先获取依赖包：

```bash
flutter pub get
```

然后调试运行：

```bash
flutter run
```

会提示选择要运行的设备，选择 Windows，输入序号（一般是 1），示例：

```bash
$ flutter run        
Connected devices:
Windows (desktop) • windows • windows-x64    • Microsoft Windows [版本 10.0.22631.4460]
Chrome (web)      • chrome  • web-javascript • Google Chrome 131.0.6778.86
Edge (web)        • edge    • web-javascript • Microsoft Edge 131.0.2903.63
[1]: Windows (windows)
[2]: Chrome (chrome)
[3]: Edge (edge)
Please choose one (or "q" to quit): 
```

输入 1，然后按回车即可启动 Windows 版本的 debug。



## 3. 发布 Release



执行构建命令：

```bash
flutter build windows
```

产出文件在路径（相对路径）`build\windows\x64\runner\Release\clipboard_test.exe` 。

目录 `build\windows\x64\runner\Release\` 中已经包含了所有依赖。
