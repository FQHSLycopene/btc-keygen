# Makefile for btc-keygen
# 自动生成各个系统的release版本

# 项目信息
PROJECT_NAME := btc-keygen
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "v0.1.0")
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# 构建参数
LDFLAGS := -ldflags "-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME) -X main.GitCommit=$(GIT_COMMIT) -X main.GitBranch=$(GIT_BRANCH)"
BUILD_FLAGS := -trimpath -ldflags="-s -w"

# 目标平台列表
PLATFORMS := \
	darwin/amd64 \
	darwin/arm64 \
	linux/amd64 \
	linux/arm64 \
	linux/386 \
	windows/amd64 \
	windows/386

# 默认目标
.DEFAULT_GOAL := help

# 帮助信息
.PHONY: help
help: ## 显示帮助信息
	@echo "btc-keygen 构建工具"
	@echo ""
	@echo "可用目标:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "示例:"
	@echo "  make build          # 构建当前平台版本"
	@echo "  make release        # 构建所有平台版本"
	@echo "  make clean          # 清理构建文件"
	@echo "  make test           # 运行测试"

# 构建当前平台版本
.PHONY: build
build: ## 构建当前平台版本
	@echo "构建 $(PROJECT_NAME) $(VERSION) for $(shell go env GOOS)/$(shell go env GOARCH)"
	@mkdir -p bin
	go build $(BUILD_FLAGS) $(LDFLAGS) -o bin/$(PROJECT_NAME) ./cmd

# 构建所有平台版本
.PHONY: release
release: clean ## 构建所有平台版本
	@echo "开始构建 $(PROJECT_NAME) $(VERSION) 的所有平台版本..."
	@mkdir -p dist
	@for platform in $(PLATFORMS); do \
		IFS='/' read -r GOOS GOARCH <<< "$$platform"; \
		echo "构建 $$GOOS/$$GOARCH..."; \
		GOOS=$$GOOS GOARCH=$$GOARCH go build $(BUILD_FLAGS) $(LDFLAGS) -o dist/$(PROJECT_NAME)-$$GOOS-$$GOARCH ./cmd; \
		if [ "$$GOOS" = "windows" ]; then \
			mv dist/$(PROJECT_NAME)-$$GOOS-$$GOARCH dist/$(PROJECT_NAME)-$$GOOS-$$GOARCH.exe; \
		fi; \
	done
	@echo "构建完成！"

# 构建并打包release
.PHONY: package
package: release ## 构建并打包release
	@echo "开始打包release..."
	@mkdir -p releases
	@for platform in $(PLATFORMS); do \
		IFS='/' read -r GOOS GOARCH <<< "$$platform"; \
		RELEASE_NAME="$(PROJECT_NAME)-$(VERSION)-$$GOOS-$$GOARCH"; \
		echo "打包 $$RELEASE_NAME..."; \
		mkdir -p releases/$$RELEASE_NAME; \
		if [ "$$GOOS" = "windows" ]; then \
			cp dist/$(PROJECT_NAME)-$$GOOS-$$GOARCH.exe releases/$$RELEASE_NAME/; \
		else \
			cp dist/$(PROJECT_NAME)-$$GOOS-$$GOARCH releases/$$RELEASE_NAME/; \
		fi; \
		cp README.md releases/$$RELEASE_NAME/ 2>/dev/null || true; \
		cp LICENSE releases/$$RELEASE_NAME/ 2>/dev/null || true; \
		cd releases && tar -czf $$RELEASE_NAME.tar.gz $$RELEASE_NAME; \
		rm -rf $$RELEASE_NAME; \
		cd ..; \
	done
	@echo "打包完成！"

# 构建Docker镜像
.PHONY: docker
docker: ## 构建Docker镜像
	@echo "构建Docker镜像..."
	docker build -t $(PROJECT_NAME):$(VERSION) .
	docker tag $(PROJECT_NAME):$(VERSION) $(PROJECT_NAME):latest

# 运行测试
.PHONY: test
test: ## 运行测试
	@echo "运行测试..."
	go test -v ./...

# 运行测试并生成覆盖率报告
.PHONY: test-coverage
test-coverage: ## 运行测试并生成覆盖率报告
	@echo "运行测试并生成覆盖率报告..."
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "覆盖率报告已生成: coverage.html"

# 代码格式化
.PHONY: fmt
fmt: ## 格式化代码
	@echo "格式化代码..."
	go fmt ./...

# 代码检查
.PHONY: lint
lint: ## 运行代码检查
	@echo "运行代码检查..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "golangci-lint 未安装，跳过代码检查"; \
	fi

# 依赖检查
.PHONY: deps
deps: ## 检查和更新依赖
	@echo "检查依赖..."
	go mod tidy
	go mod verify

# 安装到本地
.PHONY: install
install: ## 安装到本地
	@echo "安装 $(PROJECT_NAME)..."
	go install $(LDFLAGS) ./cmd

# 清理构建文件
.PHONY: clean
clean: ## 清理构建文件
	@echo "清理构建文件..."
	rm -rf bin/
	rm -rf dist/
	rm -rf releases/
	rm -f coverage.out
	rm -f coverage.html

# 显示版本信息
.PHONY: version
version: ## 显示版本信息
	@echo "项目: $(PROJECT_NAME)"
	@echo "版本: $(VERSION)"
	@echo "构建时间: $(BUILD_TIME)"
	@echo "Git提交: $(GIT_COMMIT)"
	@echo "Git分支: $(GIT_BRANCH)"

# 创建新版本标签
.PHONY: tag
tag: ## 创建新版本标签 (使用: make tag VERSION=v1.0.0)
	@if [ -z "$(VERSION)" ]; then \
		echo "请指定版本号，例如: make tag VERSION=v1.0.0"; \
		exit 1; \
	fi
	@echo "创建版本标签 $(VERSION)..."
	git tag -a $(VERSION) -m "Release $(VERSION)"
	git push origin $(VERSION)

# 构建并上传release到GitHub (需要gh CLI)
.PHONY: github-release
github-release: package ## 构建并上传release到GitHub
	@if ! command -v gh >/dev/null 2>&1; then \
		echo "GitHub CLI (gh) 未安装，请先安装: https://cli.github.com/"; \
		exit 1; \
	fi
	@echo "创建GitHub release..."
	gh release create $(VERSION) releases/*.tar.gz --title "Release $(VERSION)" --notes "Release $(VERSION) of $(PROJECT_NAME)"

# 开发模式构建（包含调试信息）
.PHONY: dev
dev: ## 开发模式构建
	@echo "开发模式构建..."
	@mkdir -p bin
	go build -race -gcflags="all=-N -l" $(LDFLAGS) -o bin/$(PROJECT_NAME)-dev ./cmd

# 检查构建状态
.PHONY: check
check: fmt lint test ## 运行完整的代码检查

# 显示构建统计信息
.PHONY: stats
stats: ## 显示构建统计信息
	@echo "构建统计信息:"
	@echo "支持的平台数量: $(words $(PLATFORMS))"
	@echo "支持的平台: $(PLATFORMS)"
	@echo "当前平台: $(shell go env GOOS)/$(shell go env GOARCH)"
	@echo "Go版本: $(shell go version)"
	@echo "模块路径: $(shell go list -m)"

# 创建发布清单
.PHONY: manifest
manifest: release ## 创建发布清单
	@echo "创建发布清单..."
	@echo "# $(PROJECT_NAME) $(VERSION) 发布清单" > releases/manifest.txt
	@echo "发布日期: $(BUILD_TIME)" >> releases/manifest.txt
	@echo "Git提交: $(GIT_COMMIT)" >> releases/manifest.txt
	@echo "Git分支: $(GIT_BRANCH)" >> releases/manifest.txt
	@echo "" >> releases/manifest.txt
	@echo "## 构建文件:" >> releases/manifest.txt
	@for platform in $(PLATFORMS); do \
		IFS='/' read -r GOOS GOARCH <<< "$$platform"; \
		if [ "$$GOOS" = "windows" ]; then \
			echo "- $(PROJECT_NAME)-$$GOOS-$$GOARCH.exe" >> releases/manifest.txt; \
		else \
			echo "- $(PROJECT_NAME)-$$GOOS-$$GOARCH" >> releases/manifest.txt; \
		fi; \
	done
	@echo "发布清单已创建: releases/manifest.txt" 