# btc-keygen

一个用Go语言编写的比特币密钥生成和地址创建工具，支持多种地址类型和网络。

## 功能特性

- 🔑 生成新的比特币密钥对
- 📥 导入现有私钥（WIF格式）
- 🌐 支持主网和测试网
- 🏠 支持多种地址类型：
  - P2PKH（传统地址，1开头）
  - P2SH（脚本哈希地址，3开头）
  - P2WPKH（原生隔离见证地址，bc1开头）
  - P2TR（Taproot地址，bc1p开头）
- 🐳 Docker支持
- 📦 多平台构建支持

## 系统要求

- Go 1.24 或更高版本
- Git

## 快速开始

### 方法一：使用预编译版本

1. 从 [Releases](https://github.com/FQHSLycopene/btc-keygen/releases) 页面下载适合您系统的版本
2. 解压并运行：

```bash
# Linux/macOS
./btc-keygen --help

# Windows
btc-keygen.exe --help
```

### 方法二：从源码编译

#### 1. 克隆仓库

```bash
git clone https://github.com/FQHSLycopene/btc-keygen.git
cd btc-keygen
```

#### 2. 编译项目

**使用Makefile（推荐）：**

```bash
# 查看所有可用命令
make help

# 编译当前平台版本
make build

# 编译所有平台版本
make release

# 安装到本地
make install
```

**手动编译：**

```bash
# 下载依赖
go mod download

# 编译
go build -o btc-keygen ./cmd

# 或者安装到GOPATH
go install ./cmd
```

#### 3. 使用Docker

```bash
# 构建Docker镜像
make docker

# 或者手动构建
docker build -t btc-keygen .

# 运行容器
docker run btc-keygen --help
```

## 使用方法

### 基本命令

```bash
# 显示帮助信息
btc-keygen --help

# 生成新的密钥对（主网，P2PKH地址）
btc-keygen --generate

# 生成新的密钥对（测试网，P2WPKH地址）
btc-keygen --generate --type p2wpkh --testnet

# 导入私钥
btc-keygen --import "5KJvsngHeMpm884wtkJNzQGaCErckhHJBGFsvd3VyK5qMZXj3hS"

# 生成Taproot地址
btc-keygen --generate --type p2tr
```

### 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--generate` | 生成新的比特币密钥对 | false |
| `--import` | 导入私钥（WIF格式） | "" |
| `--type` | 地址类型：p2pkh, p2sh, p2wpkh, p2tr | p2pkh |
| `--testnet` | 使用测试网络 | false |

### 地址类型说明

- **P2PKH (Pay-to-Public-Key-Hash)**: 传统比特币地址，以"1"开头
- **P2SH (Pay-to-Script-Hash)**: 脚本哈希地址，以"3"开头
- **P2WPKH (Pay-to-Witness-Public-Key-Hash)**: 原生隔离见证地址，以"bc1"开头
- **P2TR (Pay-to-Taproot)**: Taproot地址，以"bc1p"开头

## 开发指南

### 项目结构

```
btc-keygen/
├── cmd/
│   └── main.go          # 主程序入口
├── go.mod               # Go模块文件
├── go.sum               # 依赖校验文件
├── Makefile             # 构建脚本
├── Dockerfile           # Docker配置
├── .dockerignore        # Docker忽略文件
└── README.md            # 项目文档
```

### 开发命令

```bash
# 运行测试
make test

# 代码格式化
make fmt

# 代码检查
make lint

# 完整检查（格式化+检查+测试）
make check

# 开发模式构建（包含调试信息）
make dev

# 生成测试覆盖率报告
make test-coverage
```

### 构建多平台版本

```bash
# 构建所有支持的平台
make release

# 打包发布版本
make package

# 创建发布清单
make manifest
```

支持的平台：
- macOS (amd64, arm64)
- Linux (amd64, arm64, 386)
- Windows (amd64, 386)

### 版本管理

```bash
# 显示版本信息
make version

# 创建新版本标签
make tag VERSION=v1.0.0

# 发布到GitHub（需要gh CLI）
make github-release
```

## 安全注意事项

⚠️ **重要安全提醒：**

1. **私钥安全**: 生成的私钥请妥善保管，不要在不安全的环境中显示
2. **测试网络**: 开发测试时建议使用测试网络（`--testnet`参数）
3. **离线使用**: 生产环境建议在离线环境中生成密钥
4. **备份**: 请务必备份您的私钥

## 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

- 项目主页: https://github.com/FQHSLycopene/btc-keygen
- 问题反馈: https://github.com/FQHSLycopene/btc-keygen/issues

## 更新日志

### v0.1.0
- 初始版本发布
- 支持基本的密钥生成和地址创建
- 支持多种地址类型
- 支持主网和测试网
