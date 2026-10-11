# EnviousWispr 简体中文版

这是 [EnviousWispr](https://github.com/saurabhav88/EnviousWispr) 的中文支持分支，适用于 Apple Silicon Mac（macOS 14 或更新版本）。应用开源免费；云端大模型可能按服务商的规则收费。

## 本分支的改动

- 为全部 2,464 条非空界面字符串和 5 条系统权限说明添加简体中文翻译。
- 在「设置 → 外观 → 应用语言」中提供「简体中文」，切换后重新启动生效。
- 正确识别 macOS 保存的 `zh-CN`、`zh-SG`、`zh-Hans` 等语言代码，避免启动时误删中文语言设置。
- 补充语言偏好、翻译完整性和打包后中文资源的回归测试。
- 本机 ad-hoc 构建使用独立的 macOS 登录钥匙串保存云端 API Key，避免依赖上游开发者团队的钥匙串权限。

翻译初稿由本机翻译模型生成，常用界面、语音输入和 AI 术语已校订。欢迎改进较长的帮助说明。

## 中文语音输入

1. 完成麦克风和辅助功能授权。
2. 在识别引擎中选择「所有语言」（WhisperKit），下载模型。「快速」引擎主要支持英语和欧洲语言，不能用于中文。
3. 将识别语言设为「中文」，可减少短句被误判为其他语言。
4. 需要录音时显示文字，开启「实时预览」，安装中文预览语言包，并按提示授权系统语音识别。
5. 在「AI 润色」中选择本机模型或配置云端服务商、模型和 API Key。可使用自定义提示词：

   > 将语音转写整理为简体中文。删除“嗯、啊、那个、就是”等无实际意义的口水词和无意义重复，纠正明显的语音识别错误并补全标点。保留原意、事实、语气、专有名词和中英文混排。不要翻译英文术语，不要补充内容或解释，只输出整理后的文本。

界面语言、识别语言和 AI 模型是独立设置。本分支沿用上游的多语言语音引擎；它不改变上游的停止录音后粘贴流程，也不增加对已粘贴文字的三击撤销。

## 本地构建与打包

需要完整 Xcode 和 Tuist：

```sh
brew install tuist
./scripts/build-zh-app.sh
```

脚本使用 Release 优化，生成 `build/EnviousWispr.app` 和 `build/EnviousWispr-zh-Hans-arm64.dmg`，进行本机 ad-hoc 签名，并关闭该构建的上游自动更新。此签名适用于本机使用，不是 Apple 公证的发行签名。源码依赖和模型资源必须完整；首次编译需要下载依赖。

安装前退出正在运行的 EnviousWispr，将旧应用备份，再把新应用复制到 `/Applications`。使用相同的 bundle ID 保留原有设置和模型；签名变化后 macOS 可能要求重新授权。不要在安装时删除用户数据。

```sh
defaults write com.enviouswispr.app AppleLanguages -array zh-Hans
open /Applications/EnviousWispr.app
```

上游架构、许可证和其他构建说明见 [README.md](README.md)。
