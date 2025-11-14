# pghttp PostgreSQL 扩展 - Linux 安装指南

## 版本信息
- **版本**: 1.0.0
- **平台**: Linux (使用 libcurl)
- **PostgreSQL**: 12+ (支持 12-18+)
- **依赖**: libcurl

## 系统要求

### 支持的发行版
- Ubuntu 20.04, 22.04, 24.04
- Debian 10, 11, 12
- CentOS 7, 8, 9
- RHEL 7, 8, 9
- Rocky Linux, AlmaLinux
- Fedora

### 必需软件
- PostgreSQL 12 或更高版本
- libcurl 开发库
- GCC 或 Clang 编译器
- PostgreSQL 开发包

## 快速安装

### 1. 安装依赖

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y \
    postgresql-server-dev-all \
    libcurl4-openssl-dev \
    build-essential
```

#### CentOS/RHEL 8+
```bash
sudo dnf install -y \
    postgresql-devel \
    libcurl-devel \
    gcc \
    make
```

#### CentOS/RHEL 7
```bash
sudo yum install -y \
    postgresql-devel \
    libcurl-devel \
    gcc \
    make
```

#### Fedora
```bash
sudo dnf install -y \
    postgresql-devel \
    libcurl-devel \
    gcc \
    make
```

### 2. 编译扩展

```bash
# 进入源代码目录
cd pghttp

# 编译
make clean
make

# 验证编译结果
ls -lh pghttp.so
```

### 3. 安装扩展

#### 方法 A: 使用安装脚本（推荐）
```bash
sudo chmod +x install_linux.sh
sudo ./install_linux.sh
```

#### 方法 B: 手动安装
```bash
# 获取 PostgreSQL 路径
PG_LIBDIR=$(pg_config --pkglibdir)
PG_SHAREDIR=$(pg_config --sharedir)

# 停止 PostgreSQL
sudo systemctl stop postgresql

# 复制文件
sudo cp pghttp.so $PG_LIBDIR/
sudo cp pghttp.control $PG_SHAREDIR/extension/
sudo cp pghttp--1.0.0.sql $PG_SHAREDIR/extension/

# 设置权限
sudo chmod 755 $PG_LIBDIR/pghttp.so
sudo chmod 644 $PG_SHAREDIR/extension/pghttp.control
sudo chmod 644 $PG_SHAREDIR/extension/pghttp--1.0.0.sql

# 启动 PostgreSQL
sudo systemctl start postgresql
```

#### 方法 C: 使用 make install
```bash
sudo make install
```

### 4. 在数据库中启用扩展

```bash
# 连接到数据库
sudo -u postgres psql

# 或连接到指定数据库
psql -U your_user -d your_database
```

```sql
-- 创建扩展
CREATE EXTENSION pghttp;

-- 测试
SELECT http_get('https://httpbin.org/get');
```

## 详细安装步骤

### 步骤 1: 检查系统环境

```bash
# 检查 PostgreSQL 版本
psql --version

# 检查 pg_config
which pg_config
pg_config --version

# 检查 libcurl
pkg-config --modversion libcurl
curl-config --version
```

### 步骤 2: 下载源代码

```bash
# 如果从 Git 仓库下载
git clone <repository-url>
cd pghttp

# 或解压发布包
tar -xzf pghttp-1.0.0-linux-x64.tar.gz
cd pghttp-1.0.0-linux-x64
```

### 步骤 3: 编译

```bash
# 清理之前的编译
make clean

# 编译
make

# 检查编译结果
file pghttp.so
# 输出应该类似：
# pghttp.so: ELF 64-bit LSB shared object, x86-64...
```

#### 编译选项

如果需要调试信息：
```bash
make CFLAGS="-g -O0"
```

如果 PostgreSQL 安装在非标准位置：
```bash
make PG_CONFIG=/path/to/pg_config
```

### 步骤 4: 测试编译

```bash
# 运行测试（如果有）
make installcheck

# 或手动测试
ldd pghttp.so
# 应该显示链接到 libcurl
```

### 步骤 5: 安装

```bash
# 使用 root 权限安装
sudo make install

# 验证安装
ls -l $(pg_config --pkglibdir)/pghttp.so
ls -l $(pg_config --sharedir)/extension/pghttp*
```

### 步骤 6: 启用扩展

```sql
-- 在 PostgreSQL 中
CREATE EXTENSION pghttp;

-- 查看已安装的扩展
\dx

-- 查看扩展函数
\df pghttp*
```

## 验证安装

### 测试 GET 请求
```sql
SELECT http_get('https://httpbin.org/get');
```

### 测试 POST 请求
```sql
SELECT http_post(
    'https://httpbin.org/post',
    '{"test": "data", "value": 123}'
);
```

### 测试详细响应
```sql
SELECT * FROM http_request(
    'GET',
    'https://httpbin.org/get',
    NULL,
    'User-Agent: PostgreSQL-Test'
);
```

### 测试中文支持
```sql
SELECT http_post(
    'https://httpbin.org/post',
    '{"message": "你好世界"}'
);
```

## 故障排除

### 问题 1: pg_config 未找到

**症状**:
```
bash: pg_config: command not found
```

**解决**:
```bash
# Ubuntu/Debian
sudo apt-get install postgresql-server-dev-all

# CentOS/RHEL
sudo yum install postgresql-devel

# 或手动指定路径
export PATH=/usr/pgsql-15/bin:$PATH
```

### 问题 2: libcurl 未找到

**症状**:
```
fatal error: curl/curl.h: No such file or directory
```

**解决**:
```bash
# Ubuntu/Debian
sudo apt-get install libcurl4-openssl-dev

# CentOS/RHEL
sudo yum install libcurl-devel

# 验证
pkg-config --libs libcurl
```

### 问题 3: 编译错误

**症状**: 各种编译错误

**解决**:
```bash
# 确保安装了编译工具
sudo apt-get install build-essential  # Ubuntu/Debian
sudo yum groupinstall "Development Tools"  # CentOS/RHEL

# 清理并重新编译
make clean
make
```

### 问题 4: 权限错误

**症状**:
```
ERROR: could not load library "/usr/lib/postgresql/15/lib/pghttp.so"
```

**解决**:
```bash
# 检查文件权限
ls -l $(pg_config --pkglibdir)/pghttp.so

# 修复权限
sudo chmod 755 $(pg_config --pkglibdir)/pghttp.so

# 检查 SELinux (CentOS/RHEL)
sudo setenforce 0  # 临时禁用
sudo restorecon -v $(pg_config --pkglibdir)/pghttp.so
```

### 问题 5: SSL 证书错误

**症状**:
```
ERROR: CURL error: SSL certificate problem
```

**解决**:
```bash
# 确保 CA 证书已安装
sudo apt-get install ca-certificates  # Ubuntu/Debian
sudo yum install ca-certificates  # CentOS/RHEL

# 更新证书
sudo update-ca-certificates  # Ubuntu/Debian
sudo update-ca-trust  # CentOS/RHEL
```

### 问题 6: 扩展无法加载

**症状**:
```
ERROR: could not load library: libcurl.so.4: cannot open shared object file
```

**解决**:
```bash
# 检查 libcurl 是否安装
ldconfig -p | grep libcurl

# 如果未找到，安装运行时库
sudo apt-get install libcurl4  # Ubuntu/Debian
sudo yum install libcurl  # CentOS/RHEL

# 更新动态链接库缓存
sudo ldconfig
```

## 多版本 PostgreSQL

如果系统中安装了多个 PostgreSQL 版本：

```bash
# 为 PostgreSQL 15 编译
make PG_CONFIG=/usr/pgsql-15/bin/pg_config
sudo make install PG_CONFIG=/usr/pgsql-15/bin/pg_config

# 为 PostgreSQL 16 编译
make clean
make PG_CONFIG=/usr/pgsql-16/bin/pg_config
sudo make install PG_CONFIG=/usr/pgsql-16/bin/pg_config
```

## 卸载

```bash
# 在 PostgreSQL 中删除扩展
psql -c "DROP EXTENSION IF EXISTS pghttp CASCADE;"

# 删除文件
sudo rm $(pg_config --pkglibdir)/pghttp.so
sudo rm $(pg_config --sharedir)/extension/pghttp.control
sudo rm $(pg_config --sharedir)/extension/pghttp--1.0.0.sql

# 或使用 make
sudo make uninstall
```

## 性能调优

### libcurl 选项

可以通过环境变量调整 libcurl 行为：

```bash
# 设置代理
export http_proxy=http://proxy.example.com:8080
export https_proxy=http://proxy.example.com:8080

# 禁用代理
export no_proxy=localhost,127.0.0.1
```

### PostgreSQL 配置

```sql
-- 增加函数超时时间（如果需要）
SET statement_timeout = '60s';

-- 对于大量 HTTP 请求的应用
SET work_mem = '64MB';
```

## 安全建议

1. **限制扩展使用**
```sql
-- 只允许特定用户使用
REVOKE ALL ON FUNCTION http_get(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION http_get(text, text) TO your_user;
```

2. **网络隔离**
- 确保 PostgreSQL 服务器可以访问必要的外部 API
- 使用防火墙限制出站连接

3. **SSL/TLS**
- 确保系统 CA 证书是最新的
- 对于内部 API，考虑配置自定义 CA

## 生产部署

### 容器化部署 (Docker)

```dockerfile
FROM postgres:15

# 安装依赖
RUN apt-get update && apt-get install -y \
    postgresql-server-dev-15 \
    libcurl4-openssl-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 复制源代码
COPY . /tmp/pghttp
WORKDIR /tmp/pghttp

# 编译并安装
RUN make && make install && make clean

# 清理
RUN apt-get purge -y \
    postgresql-server-dev-15 \
    build-essential \
    && apt-get autoremove -y
```

### systemd 服务

如果需要重启 PostgreSQL：

```bash
sudo systemctl restart postgresql

# 检查状态
sudo systemctl status postgresql

# 查看日志
sudo journalctl -u postgresql -f
```

## 更多信息

- **使用文档**: [USAGE.md](USAGE.md)
- **示例代码**: [examples.sql](examples.sql)
- **版本兼容性**: [POSTGRESQL_COMPATIBILITY.md](POSTGRESQL_COMPATIBILITY.md)
- **平台支持**: [PLATFORM_SUPPORT.md](PLATFORM_SUPPORT.md)

## 获取帮助

如果遇到问题：
1. 检查 PostgreSQL 日志：`sudo tail -f /var/log/postgresql/postgresql-15-main.log`
2. 启用详细日志：`SET client_min_messages = DEBUG;`
3. 检查扩展版本：`SELECT * FROM pg_available_extensions WHERE name = 'pghttp';`

---

**最后更新**: 2025-11-14  
**版本**: 1.0.0  
**平台**: Linux (libcurl)
