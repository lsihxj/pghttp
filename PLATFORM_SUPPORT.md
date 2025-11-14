# pghttp 平台支持说明

## 📋 当前状态

### ✅ 已支持平台
- **Windows 10/11** (x64)
- **Windows Server 2016+** (x64)

### ❌ 暂不支持平台
- Linux (Ubuntu, CentOS, Debian, etc.)
- macOS
- FreeBSD

## 🔍 为什么只支持 Windows？

### 技术原因

当前实现使用 **Windows WinHTTP API**：

```c
#ifdef WIN32
#include <windows.h>
#include <winhttp.h>
#pragma comment(lib, "winhttp.lib")
#endif
```

**WinHTTP 优势**：
- ✅ Windows 系统内置，零外部依赖
- ✅ 性能优秀，经过微软优化
- ✅ 自动处理 SSL/TLS（使用 Windows 证书存储）
- ✅ 编译简单，无需额外库

**WinHTTP 限制**：
- ❌ 仅限 Windows 平台
- ❌ 无法在 Linux/macOS 上使用

### 开发历史

最初计划使用跨平台的 **libcurl**，但遇到问题：
- libcurl 在 Windows 上依赖复杂（OpenSSL, nghttp2, zstd 等）
- MinGW 编译的 libcurl 与 MSVC PostgreSQL 不兼容
- 编译和分发困难

因此改用 WinHTTP 专注于 Windows 平台。

## 🚀 Linux 支持计划

### 方案 1: libcurl 实现（推荐）

创建 Linux 版本，使用 **libcurl**：

#### 技术方案
```c
#ifdef __linux__
#include <curl/curl.h>
#endif

#ifdef WIN32
#include <windows.h>
#include <winhttp.h>
#endif
```

#### 优势
- ✅ libcurl 是 Linux 标准库
- ✅ 大多数发行版预装或易安装
- ✅ 功能强大，支持所有 HTTP 特性
- ✅ 与 PostgreSQL 兼容良好

#### 挑战
- 需要重写 HTTP 请求处理逻辑
- 需要处理不同的错误处理机制
- 需要维护两套代码

### 方案 2: 统一 libcurl 实现

完全改用 libcurl，同时支持 Windows 和 Linux：

#### 优势
- ✅ 单一代码库
- ✅ 跨平台一致性
- ✅ 社区支持好

#### 挑战
- Windows 上需要分发 libcurl DLL
- 编译复杂度增加
- 需要处理 SSL 证书问题

## 🛠️ Linux 版本实现指南

如果你需要 Linux 支持，这里是实现方案：

### 步骤 1: 创建 Linux 源文件

创建 `pghttp_linux.c`：

```c
/* PostgreSQL HTTP Extension using libcurl (Linux) */

#include "postgres.h"
#include "fmgr.h"
#include "funcapi.h"
#include "utils/builtins.h"
#include "lib/stringinfo.h"
#include <curl/curl.h>

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

/* Callback for CURL to write response data */
static size_t write_callback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    StringInfo response = (StringInfo)userp;
    appendBinaryStringInfo(response, contents, realsize);
    return realsize;
}

/* Perform HTTP request using libcurl */
static char* perform_http_request(const char *method, const char *url, 
                                   const char *body, const char *headers) {
    CURL *curl;
    CURLcode res;
    StringInfoData response_data;
    char *result;
    
    initStringInfo(&response_data);
    
    curl = curl_easy_init();
    if (!curl) {
        elog(ERROR, "pghttp: Failed to initialize CURL");
        return NULL;
    }
    
    /* Set URL */
    curl_easy_setopt(curl, CURLOPT_URL, url);
    
    /* Set method */
    if (strcmp(method, "POST") == 0) {
        curl_easy_setopt(curl, CURLOPT_POST, 1L);
        if (body) {
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body);
        }
    } else if (strcmp(method, "GET") == 0) {
        curl_easy_setopt(curl, CURLOPT_HTTPGET, 1L);
    }
    
    /* Set headers for POST */
    struct curl_slist *header_list = NULL;
    if (body && strlen(body) > 0) {
        header_list = curl_slist_append(header_list, "Content-Type: application/json");
    }
    if (headers) {
        header_list = curl_slist_append(header_list, headers);
    }
    if (header_list) {
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, header_list);
    }
    
    /* Set callback */
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_data);
    
    /* Set timeout */
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);
    
    /* Perform request */
    res = curl_easy_perform(curl);
    
    /* Cleanup */
    if (header_list) {
        curl_slist_free_all(header_list);
    }
    curl_easy_cleanup(curl);
    
    if (res != CURLE_OK) {
        elog(ERROR, "pghttp: CURL error: %s", curl_easy_strerror(res));
        return NULL;
    }
    
    result = response_data.data;
    return result;
}

/* HTTP GET function */
PG_FUNCTION_INFO_V1(http_get);
Datum http_get(PG_FUNCTION_ARGS) {
    text *url_text = PG_GETARG_TEXT_PP(0);
    char *url = text_to_cstring(url_text);
    char *response = perform_http_request("GET", url, NULL, NULL);
    
    if (response == NULL) {
        PG_RETURN_NULL();
    }
    
    PG_RETURN_TEXT_P(cstring_to_text(response));
}

/* HTTP POST function */
PG_FUNCTION_INFO_V1(http_post);
Datum http_post(PG_FUNCTION_ARGS) {
    text *url_text = PG_GETARG_TEXT_PP(0);
    text *body_text = PG_GETARG_TEXT_PP(1);
    char *url = text_to_cstring(url_text);
    char *body = text_to_cstring(body_text);
    char *response = perform_http_request("POST", url, body, NULL);
    
    if (response == NULL) {
        PG_RETURN_NULL();
    }
    
    PG_RETURN_TEXT_P(cstring_to_text(response));
}
```

### 步骤 2: 创建 Linux Makefile

创建 `Makefile`：

```makefile
MODULE_big = pghttp
OBJS = pghttp_linux.o

EXTENSION = pghttp
DATA = pghttp--1.0.0.sql
PGFILEDESC = "pghttp - HTTP client for PostgreSQL"

# libcurl dependency
PG_CPPFLAGS = -I/usr/include
SHLIB_LINK = -lcurl

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
```

### 步骤 3: 编译和安装

```bash
# 安装依赖
sudo apt-get install postgresql-server-dev-all libcurl4-openssl-dev

# 编译
make

# 安装
sudo make install

# 在 PostgreSQL 中使用
psql -d your_database
CREATE EXTENSION pghttp;
```

## 📦 双平台发布策略

### 建议的项目结构

```
pghttp/
├── src/
│   ├── pghttp_windows.c    # Windows (WinHTTP)
│   ├── pghttp_linux.c      # Linux (libcurl)
│   └── pghttp_common.h     # 共享头文件
├── build/
│   ├── Makefile.linux      # Linux Makefile
│   └── build_windows.ps1   # Windows 编译脚本
├── release/
│   ├── pghttp-1.0.0-win-x64.zip
│   └── pghttp-1.0.0-linux-x64.tar.gz
└── docs/
    ├── INSTALL_WINDOWS.md
    └── INSTALL_LINUX.md
```

## 🎯 实现优先级建议

### 短期（当前 v1.0.0）
✅ **专注 Windows 平台**
- 代码稳定
- 功能完整
- 文档齐全

### 中期（v1.1.0）
🔨 **添加 Linux 支持**
- 基于 libcurl 实现
- 提供 Ubuntu/Debian 和 CentOS/RHEL 预编译包
- 统一 SQL API

### 长期（v2.0.0）
🌟 **统一实现**
- 可能全部改用 libcurl
- 或保持双实现但共享更多代码
- 添加 macOS 支持

## 📊 平台使用场景对比

| 场景 | Windows | Linux |
|------|---------|-------|
| 企业 Windows Server | ✅ 完美支持 | - |
| 云服务器 (AWS/Azure/GCP) | ✅ 可用 | ⚠️ 需 Linux 版本 |
| 容器化部署 (Docker/K8s) | ⚠️ 较少使用 | ⚠️ 需 Linux 版本 |
| 开发环境 | ✅ 常见 | ⚠️ 需 Linux 版本 |

## ❓ 常见问题

### Q1: 我的 PostgreSQL 在 Linux 上，能用这个扩展吗？
❌ **当前版本不能**。需要等待 Linux 版本或自己实现（参考上面的代码）。

### Q2: 有计划支持 Linux 吗？
💡 **可以实现**。如果需求强烈，可以开发 libcurl 版本。

### Q3: 能在 Docker 容器中使用吗？
- Windows 容器：✅ 可以
- Linux 容器：❌ 需要 Linux 版本

### Q4: 我能自己实现 Linux 版本吗？
✅ **可以！** 参考本文档的实现指南。主要工作：
1. 用 libcurl 替换 WinHTTP API
2. 调整编译脚本（Makefile）
3. 测试功能

### Q5: 为什么不一开始就做跨平台？
因为：
1. WinHTTP 在 Windows 上更简单可靠
2. libcurl 依赖在 Windows 上复杂
3. 专注一个平台可以更快发布稳定版本

## 🤝 贡献 Linux 版本

如果你愿意贡献 Linux 版本：

1. **Fork 项目**
2. **实现 libcurl 版本**（参考上面的代码框架）
3. **测试**（至少在 Ubuntu 和 CentOS 上）
4. **提交 Pull Request**

需要帮助：
- 代码审查
- 测试用例
- 文档编写

## 📌 总结

| 项目 | Windows | Linux |
|------|---------|-------|
| **当前状态** | ✅ v1.0.0 已发布 | ❌ 暂不支持 |
| **实现技术** | WinHTTP | 计划用 libcurl |
| **依赖** | 零依赖（系统内置） | libcurl |
| **难度** | ✅ 简单 | ⚠️ 中等 |
| **时间估算** | - | ~2-3 天开发 |

### 给 Linux 用户的建议

**选项 1**: 等待官方 Linux 版本发布

**选项 2**: 使用现有的 PostgreSQL HTTP 扩展
- `pgsql-http` (https://github.com/pramsey/pgsql-http) - 成熟的跨平台方案
- `http` extension (已有多个实现)

**选项 3**: 自己实现（参考本文档）

**选项 4**: 使用其他方案
- PL/Python + requests 库
- 外部脚本 + COPY/FOREIGN DATA WRAPPER

---

**最后更新**: 2025-11-14  
**当前版本**: 1.0.0 (Windows only)  
**计划版本**: 1.1.0 (Linux support planned)
