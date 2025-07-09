# 多阶段构建Dockerfile for btc-keygen

# 构建阶段
FROM golang:1.24-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装必要的构建工具
RUN apk add --no-cache git ca-certificates tzdata

# 复制go mod文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o btc-keygen ./cmd

# 运行阶段
FROM alpine:latest

# 安装ca-certificates用于HTTPS请求
RUN apk --no-cache add ca-certificates tzdata

# 创建非root用户
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# 设置工作目录
WORKDIR /app

# 从构建阶段复制二进制文件
COPY --from=builder /app/btc-keygen .

# 复制README等文档（如果存在）
COPY --from=builder /app/README.md ./ 2>/dev/null || true
COPY --from=builder /app/LICENSE ./ 2>/dev/null || true

# 更改文件所有者
RUN chown -R appuser:appgroup /app

# 切换到非root用户
USER appuser

# 设置环境变量
ENV PATH="/app:${PATH}"

# 暴露端口（如果需要的话）
# EXPOSE 8080

# 设置入口点
ENTRYPOINT ["./btc-keygen"]

# 默认命令
CMD ["--help"] 