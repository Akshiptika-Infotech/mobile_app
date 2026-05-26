#!/usr/bin/env python3
"""Upload APKs to Indus App Store using only built-in Python libraries."""

import http.client
import mimetypes
import os
import json
import uuid
import ssl
from datetime import datetime, timezone

API_KEY = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJpc3MiOiJpZGVudGl0eU1hbmFnZXIiLCJ2ZXJzaW9uIjoiNC4wIiwidGlkIjoiOTY3Yjc3NDItZDI5Ny00YTg1LWIzMGMtMmM3M2U4MzhkNDdjIiwic2lkIjoiOWI4MjQyNTktNTYzZS00YTNlLTg0MDctZjcwNGNmNTMxMGJiIiwiaWF0IjoxNzczODQ1MDkwLCJleHAiOjIwODkyMDUwOTB9.CFCPsovZYCPUd68cDygNxWne1tnmaNw0D2yhj6vrIp4oNpKuKAsLWVDykDSUJF43fGyFIcryHO4HvOjj8ZGTjg"
BASE_HOST = "developer-api.indusappstore.com"

APPS = [
    {"name": "JMukhisics", "package": "in.jmukhisics.mobile_app", "apk": "build/app/outputs/flutter-apk/app-jmukhisics-release.apk", "version": "1.0.6", "versionCode": 7},
    {"name": "SIC School", "package": "in.sicschool.mobile_app", "apk": "build/app/outputs/flutter-apk/app-sicschool-release.apk", "version": "1.0.6", "versionCode": 7},
    {"name": "SchoolFeePro", "package": "in.schoolfeepro.mobile_app", "apk": "build/app/outputs/flutter-apk/app-schoolfeepro-release.apk", "version": "1.0.6", "versionCode": 7},
    {"name": "The Shivalik", "package": "in.theshivalik.mobile_app", "apk": "build/app/outputs/flutter-apk/app-theshivalik-release.apk", "version": "1.0.6", "versionCode": 7},
    {"name": "Shivalik Smart Kids", "package": "in.shivaliksmartkids.mobile_app", "apk": "build/app/outputs/flutter-apk/app-shivaliksmartkids-release.apk", "version": "1.0.6", "versionCode": 7},
]


def encode_multipart_formdata(fields, files):
    """Encode form data and files for multipart/form-data upload."""
    boundary = uuid.uuid4().hex
    lines = []

    for key, value in fields.items():
        lines.append((f"--{boundary}").encode())
        lines.append(f'Content-Disposition: form-data; name="{key}"'.encode())
        lines.append(b"")
        lines.append(value.encode() if isinstance(value, str) else value)

    for key, filepath in files.items():
        filename = os.path.basename(filepath)
        content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"
        lines.append((f"--{boundary}").encode())
        lines.append(f'Content-Disposition: form-data; name="{key}"; filename="{filename}"'.encode())
        lines.append(f"Content-Type: {content_type}".encode())
        lines.append(b"")
        with open(filepath, "rb") as f:
            lines.append(f.read())

    lines.append((f"--{boundary}--").encode())
    lines.append(b"")

    body = b"\r\n".join(lines)
    content_type = f"multipart/form-data; boundary={boundary}"
    return body, content_type


def upload_app(app):
    """Upload a single APK to Indus App Store."""
    apk_path = app["apk"]
    package = app["package"]
    name = app["name"]

    print(f"\n{'='*50}")
    print(f"Uploading {name} v{app['version']}")
    print(f"Package: {package}")
    print(f"APK: {apk_path}")
    print(f"{'='*50}")

    if not os.path.exists(apk_path):
        print(f"ERROR: APK file not found: {apk_path}")
        return {"name": name, "package": package, "version": app["version"], "versionCode": app["versionCode"],
                "status_code": None, "response": "APK file not found", "success": False}

    apk_size = os.path.getsize(apk_path)
    print(f"APK size: {apk_size / (1024*1024):.1f} MB")

    body, content_type = encode_multipart_formdata({}, {"file": apk_path})

    headers = {
        "Authorization": f"O-Bearer {API_KEY}",
        "Content-Type": content_type,
        "Content-Length": str(len(body)),
    }

    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        conn = http.client.HTTPSConnection(BASE_HOST, timeout=300, context=ctx)
        conn.request("POST", f"/devtools/apk/upgrade/{package}", body=body, headers=headers)
        response = conn.getresponse()
        status_code = response.status
        response_body = response.read().decode("utf-8", errors="replace")
        conn.close()

        print(f"HTTP Status: {status_code}")
        print(f"Response: {response_body}")

        success = (status_code == 200)
        return {"name": name, "package": package, "version": app["version"], "versionCode": app["versionCode"],
                "status_code": status_code, "response": response_body, "success": success}

    except Exception as e:
        print(f"ERROR: {e}")
        return {"name": name, "package": package, "version": app["version"], "versionCode": app["versionCode"],
                "status_code": None, "response": str(e), "success": False}


def main():
    results = []
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    for app in APPS:
        result = upload_app(app)
        result["timestamp"] = timestamp
        results.append(result)

    print(f"\n\n{'='*50}")
    print("UPLOAD SUMMARY")
    print(f"{'='*50}")
    for r in results:
        status = "[SUCCESS]" if r["success"] else "[FAILED]"
        print(f"{status} - {r['name']} (HTTP {r['status_code']})")

    # Save results
    with open("scripts/upload_results.json", "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print("\nResults saved to scripts/upload_results.json")


if __name__ == "__main__":
    main()
