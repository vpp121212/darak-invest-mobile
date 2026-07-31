import json, time, urllib.request, urllib.parse, os, sys, gzip, io

BASE = "https://open.data.gov.sa"
UA = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36", "Accept": "application/json"}

OUT = os.path.join(os.path.dirname(__file__), "..", "data", "rega")
os.makedirs(OUT, exist_ok=True)

TARGETS = {
    "06939867-7a5c-436d-815d-c19cb878430a": "riyadh_rent_city",
    "a108f1ed-0091-4264-bb82-71a4ad0989f8": "eastern_rent_city",
    "a3096049-0662-4ecb-96b1-d86628dbde1e": "makkah_rent_city",
    "86415b9b-dd94-4bd2-a2a9-496ba0bcc250": "madinah_rent_city",
    "75d8dd7a-88fe-4d48-b69b-485a7afb0cc4": "qassim_rent_city",
    "5841795c-c6a7-45ad-97b8-49b4533f36f6": "baha_rent_city",
    "2dde7e8c-db79-4aec-be4e-37cef64c1d4d": "riyadh_rent_q1_2026",
    "05cc087e-7151-42b2-8fbe-6e41e5813201": "riyadh_sales_q1_2026",
}

def fetch(url, binary=False):
    for attempt in range(6):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read()
            if not binary and data[:100].find(b"Request Rejected") != -1:
                raise Exception("WAF blocked, retry")
            return data
        except Exception as e:
            print(f"  retry {attempt+1}: {e}")
            time.sleep(4 * (attempt + 1))
    raise Exception("FAILED: " + url)

meta = []
for dsid, slug in TARGETS.items():
    print(f"\n=== {slug} ({dsid})")
    data = fetch(f"{BASE}/api/datasets/{dsid}")
    d = json.loads(data)
    title = d.get("titleAr", "")
    period = d.get("timePeriod", {})
    resources = d.get("resources") or []
    saved = None
    for res in resources:
        if res.get("format") == "CSV" and res.get("url"):
            url_path = res["url"]
            parts = url_path.split("/")
            parts[-1] = urllib.parse.quote(parts[-1])
            dl = f"{BASE}/odp-public/{'/'.join(parts)}"
            print("  downloading:", dl)
            try:
                raw = fetch(dl, binary=True)
            except Exception as e:
                print("  ", e)
                continue
            if raw[:100].find(b"Request Rejected") != -1:
                print("  WAF on download, skip")
                continue
            fname = f"{slug}.csv"
            with open(os.path.join(OUT, fname), "wb") as f:
                f.write(raw)
            size = len(raw)
            print(f"  saved {fname} ({size} bytes)")
            meta.append({
                "dataset_id": dsid, "slug": slug, "title": title,
                "period": period, "file": fname, "size": size,
                "source_url": f"https://open.data.gov.sa/ar/datasets/view/{dsid}",
            })
            break
    time.sleep(2)

with open(os.path.join(OUT, "_meta.json"), "w") as f:
    json.dump(meta, f, ensure_ascii=False, indent=2)
print("\nSaved meta:", len(meta))
