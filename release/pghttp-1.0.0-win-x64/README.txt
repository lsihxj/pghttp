# pghttp - PostgreSQL HTTP Extension

Version: 1.0.0
Build Date: 2025-11-14
Platform: Windows x64

## Quick Start

1. **浠ョ鐞嗗憳韬唤杩愯 PowerShell**

2. **杩愯瀹夎鑴氭湰**:
   ```powershell
   .\install.ps1
   ```

3. **鍦?PostgreSQL 涓垱寤烘墿灞?*:
   ```sql
   CREATE EXTENSION pghttp;
   ```

4. **娴嬭瘯**:
   ```sql
   SELECT http_get('https://httpbin.org/get');
   ```

## 鏂囦欢璇存槑

- **install.ps1** - 鑷姩瀹夎鑴氭湰锛堟帹鑽愪娇鐢級
- **INSTALL_RELEASE.md** - 璇︾粏瀹夎鎸囧崡
- **USAGE.md** - 浣跨敤鏂囨。
- **examples.sql** - 绀轰緥浠ｇ爜
- **pghttp.dll** - 鎵╁睍搴撴枃浠?
- **pghttp.control** - 鎵╁睍鎺у埗鏂囦欢
- **pghttp--1.0.0.sql** - SQL 鍑芥暟瀹氫箟
- **VERSION.txt** - 鐗堟湰淇℃伅

## 绯荤粺瑕佹眰

- Windows 10/11 鎴?Windows Server 2016+
- PostgreSQL 15.x (Windows x64)
- 绠＄悊鍛樻潈闄?

## 鍔熻兘鐗规€?

鉁?HTTP/HTTPS GET 璇锋眰
鉁?HTTP/HTTPS POST 璇锋眰
鉁?鏀寔鎵€鏈?HTTP 鏂规硶
鉁?璇︾粏鍝嶅簲淇℃伅锛堢姸鎬佺爜銆丆ontent-Type銆佸搷搴斾綋锛?
鉁?UTF-8 缂栫爜鏀寔
鉁?鏃犲閮ㄤ緷璧栵紙浣跨敤 Windows 鍘熺敓 WinHTTP锛?

## 蹇€熺ず渚?

```sql
-- 绠€鍗?GET 璇锋眰
SELECT http_get('https://api.example.com/data');

-- POST JSON 鏁版嵁
SELECT http_post('https://api.example.com/users', '{"name":"John"}');

-- 鑾峰彇璇︾粏鍝嶅簲
SELECT * FROM http_request('GET', 'https://api.example.com/status');
```

鏌ョ湅 **examples.sql** 鑾峰彇鏇村绀轰緥銆?

## 鎶€鏈敮鎸?

- 璇︾粏鏂囨。: INSTALL_RELEASE.md, USAGE.md
- 绀轰緥浠ｇ爜: examples.sql
- 椤圭洰璇存槑: README_FINAL.md

## 璁稿彲璇?

MIT License - 鍙嚜鐢变娇鐢ㄣ€佷慨鏀瑰拰鍒嗗彂

---

**Happy coding with pghttp!** 馃殌
