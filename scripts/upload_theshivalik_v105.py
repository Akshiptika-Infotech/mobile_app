import http.client
import ssl
import os
import uuid

API_KEY = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJpc3MiOiJpZGVudGl0eU1hbmFnZXIiLCJ2ZXJzaW9uIjoiNC4wIiwidGlkIjoiOTY3Yjc3NDItZDI5Ny00YTg1LWIzMGMtMmM3M2U4MzhkNDdjIiwic2lkIjoiOWI4MjQyNTktNTYzZS00YTNlLTg0MDctZjcwNGNmNTMxMGJiIiwiaWF0IjoxNzczODQ1MDkwLCJleHAiOjIwODkyMDUwOTB9.CFCPsovZYCPUd68cDygNxWne1tnmaNw0D2yhj6vrIp4oNpKuKAsLWVDykDSUJF43fGyFIcryHO4HvOjj8ZGTjg"
APK = "build/app/outputs/flutter-apk/app-theshivalik-release.apk"

print(f"Uploading The Shivalik v1.0.5")
print(f"APK: {APK}")
print(f"Size: {os.path.getsize(APK) / (1024*1024):.1f} MB")

boundary = uuid.uuid4().hex
with open(APK, "rb") as f:
    data = f.read()
body = f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{os.path.basename(APK)}\"\r\nContent-Type: application/vnd.android.package-archive\r\n\r\n".encode() + data + f"\r\n--{boundary}--\r\n".encode()

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
conn = http.client.HTTPSConnection("developer-api.indusappstore.com", timeout=600, context=ctx)
conn.request("POST", "/devtools/apk/upgrade/in.theshivalik.mobile_app", body=body, headers={
    "Authorization": f"O-Bearer {API_KEY}",
    "Content-Type": f"multipart/form-data; boundary={boundary}",
    "Content-Length": str(len(body))
})
resp = conn.getresponse()
print(f"Status: {resp.status}")
print(f"Response: {resp.read().decode()}")
conn.close()
