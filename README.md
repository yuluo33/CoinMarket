# CoinMarket

CoinMarket 是一个基于 SwiftUI 开发的 macOS 加密货币实时监控应用，提供实时价格更新、多语言支持、多法币换算等功能。

## 功能特性

- 📊 **实时价格更新** - 支持多种加密货币的实时价格监控
- 🌐 **多语言支持** - 支持中文、英语、日语、韩语、越南语
- 💱 **多法币换算** - 支持 USDT、人民币、美元、欧元、英镑、日元、韩元等多种法币
- 🔍 **搜索功能** - 快速搜索加密货币
- ⭐ **收藏管理** - 支持添加和管理收藏的加密货币
- 📱 **状态栏集成** - 支持在 macOS 状态栏显示实时价格
- 📈 **价格图表** - 支持查看 7 天价格走势图
- ⚙️ **个性化设置** - 支持自定义刷新间隔、语言、价格单位等

## 技术栈

- **开发框架**: SwiftUI
- **状态管理**: Combine
- **异步编程**: Async/Await
- **API**: 
  - Binance API (加密货币价格)
  - Frankfurter API (实时汇率)
- **构建工具**: Xcode

## 项目结构

```
CoinMarket/
├── Models/            # 数据模型
├── Services/          # API 服务
├── Utilities/         # 工具类
├── ViewModels/        # 视图模型
├── Views/             # 视图
│   └── Components/    # 组件
└── Assets.xcassets/   # 资源文件
```

## 安装与运行

### 要求

- macOS 15.0 或更高版本
- Xcode 17.0 或更高版本
- Swift 6.0 或更高版本

### 安装步骤

1. 克隆项目到本地
   ```bash
   git clone <仓库URL>
   cd CoinMarket
   ```

2. 打开 Xcode 项目
   ```bash
   open CoinMarket.xcodeproj
   ```

3. 选择目标设备或模拟器

4. 点击 "Run" 按钮或使用快捷键 `Cmd + R` 运行项目

## 使用指南

### 主界面

- **价格列表**: 显示加密货币的实时价格、24 小时涨跌幅等信息
- **搜索框**: 位于顶部导航栏，可快速搜索加密货币
- **设置按钮**: 位于右上角，可进入设置页面

### 设置

- **语言设置**: 支持切换多种语言
- **价格单位**: 支持切换多种法币
- **刷新间隔**: 支持设置自动刷新间隔 (5s, 10s, 15s, 30s, 60s)
- **状态栏轮播间隔**: 支持设置状态栏价格轮播间隔

### 状态栏应用

- 点击状态栏图标可查看实时价格
- 支持在状态栏轮播显示不同加密货币的价格
- 支持点击切换显示的加密货币

## 配置

### API 配置

项目使用公开的 API，无需配置 API 密钥：

- **Binance API**: 用于获取加密货币价格数据
- **Frankfurter API**: 用于获取实时汇率数据

### 刷新机制

- 加密货币价格每 5-60 秒自动刷新一次
- 汇率数据每小时自动刷新一次

## 开发

### 代码规范

- 遵循 Swift 官方代码规范
- 使用 SwiftUI 声明式 UI 开发
- 使用 MVVM 架构模式

### 构建命令

```bash
# 清理构建缓存
xcodebuild clean

# 构建项目
xcodebuild -project CoinMarket.xcodeproj -scheme CoinMarket -destination 'platform=macOS,name=Any Mac' build

# 运行测试
xcodebuild test -project CoinMarket.xcodeproj -scheme CoinMarket -destination 'platform=macOS,name=Any Mac'
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v1.0.0
- 初始版本发布
- 支持实时加密货币价格监控
- 支持多语言和多法币换算
- 支持状态栏集成
- 支持收藏管理
