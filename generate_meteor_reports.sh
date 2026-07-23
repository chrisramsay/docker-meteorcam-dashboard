#!/bin/bash

# Configuration
HUGO_PROJECT_DIR="/app/meteors"
OUTPUT_DIR="${HUGO_PROJECT_DIR}/content/reports"
STATUS_FILE="${HUGO_PROJECT_DIR}/content/_index.md"

CAMERAS=("uk002k" "uk002z" "uk004b" "uk008f" "uk0098")
DATE=$(date +%Y-%m-%d)

mkdir -p "$OUTPUT_DIR"

# Initialize Markdown table rows for the network status dashboard
STATUS_TABLE_ROWS=""

echo "Processing camera data and generating Markdown reports..."

for CAM in "${CAMERAS[@]}"; do
  CAM_UPPER=$(echo "$CAM" | tr '[:lower:]' '[:upper:]')
  CAM_LOWER=$(echo "$CAM" | tr '[:upper:]' '[:lower:]')
  BASE_URL="https://globalmeteornetwork.org/weblog/UK/${CAM_UPPER}/static/"
  JSON_URL="${BASE_URL}${CAM_UPPER}_observation_summary_static.json"
  
  # Fetch JSON data and build both top-line stats and a full Markdown table
  READ_JSON=$(python3 - "${JSON_URL}" << 'EOF'
import sys, urllib.request, json

url = sys.argv[1]
try:
    req = urllib.request.Request(url, headers={'User-Agent': 'HugoGenerator/1.0'})
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        
        # Summary metrics
        # 'detections_after_ml' is the GMN field for ML-verified meteors
        meteors = data.get('detections_after_ml', 'N/A')

        # GMN stores observing time in seconds under 'duration_from_start_of_observation'
        duration_sec = data.get('duration_from_start_of_observation')
        if duration_sec is not None:
            duration = f"{float(duration_sec) / 3600:.1f}"
        else:
            duration = 'N/A'

        # Abbreviation acronym map for pretty key formatting
        abbr = {'ml': 'ML', 'fft': 'FFT', 'id': 'ID', 'fps': 'FPS', 'utc': 'UTC', 'ff': 'FF'}
        
        # Build Markdown table
        rows = ['| Parameter | Value |', '| :--- | :--- |']
        for k, v in data.items():
            words = str(k).split('_')
            clean_key = ' '.join([abbr.get(w.lower(), w.capitalize()) for w in words])
            rows.append(f'| **{clean_key}** | `{v}` |')
        
        table = '\n'.join(rows)
        print(f'{meteors}|{duration}|ONLINE\n{table}')
except Exception as e:
    print('N/A|N/A|OFFLINE / NO DATA\n| Parameter | Value |\n| :--- | :--- |\n| **Status** | `No JSON summary data found` |')
EOF
  )

  # Extract header metrics (Line 1) and full table (Line 2 onwards)
  SUMMARY_HEADER=$(echo "$READ_JSON" | head -n 1)
  METEOR_COUNT=$(echo "$SUMMARY_HEADER" | cut -d'|' -f1)
  OBS_DURATION=$(echo "$SUMMARY_HEADER" | cut -d'|' -f2)
  CAM_STATUS=$(echo "$SUMMARY_HEADER" | cut -d'|' -f3)

  JSON_TABLE=$(echo "$READ_JSON" | tail -n +2)

  # Determine status badge color
  if [ "$CAM_STATUS" == "ONLINE" ]; then
    STATUS_BADGE="🟢 ONLINE"
  else
    STATUS_BADGE="🔴 NO DATA"
  fi

  # -------------------------------------------------------------
  # 1. Generate Static Individual Camera Report
  # -------------------------------------------------------------
  cat <<EOF > "${OUTPUT_DIR}/${CAM_LOWER}.md"
---
title: "Meteor Camera Nightly Report: ${CAM_UPPER}"
date: ${DATE}T03:27:00+00:00
draft: false
tags: ["${CAM_UPPER}", "meteor-camera", "nightly-report"]
categories: ["Meteor Detections"]
camera: "${CAM_UPPER}"
meteors_detected: "${METEOR_COUNT}"
---

> **Nightly Summary Stats**  
> ☄️ **Meteors Detected (ML Verified):** \`${METEOR_COUNT}\`  
> ⏱️ **Observing Duration:** \`${OBS_DURATION} hrs\`  
> 📡 **Status:** \`${CAM_STATUS}\`

---

## 📋 Detailed Observation Summary

${JSON_TABLE}

---

## 🌌 Key Highlights & Visuals

### Meteor Stack
![Meteor Stack](${BASE_URL}${CAM_UPPER}_stack_meteors_static.jpg)

### Captured Stack
![Captured Stack](${BASE_URL}${CAM_UPPER}_captured_stack_static.jpg)

### Nightly Timelapse
{{< video src="${BASE_URL}${CAM_UPPER}_timelapse_static.mp4" >}}

---

## 📸 Detections & Thumbnails

| Captured Thumbnails | Detected Thumbnails |
| :---: | :---: |
| ![Captured Thumbs](${BASE_URL}${CAM_UPPER}_CAPTURED_thumbs_static.jpg) | ![Detected Thumbs](${BASE_URL}${CAM_UPPER}_DETECTED_thumbs_static.jpg) |

---

## 📊 Nightly Observing Activity

### Observing Periods & Intervals
![Observing Periods](${BASE_URL}${CAM_UPPER}_observing_periods_static.png)
![FF Intervals](${BASE_URL}${CAM_UPPER}_ff_intervals_static.png)

### Field Sums
![Field Sums](${BASE_URL}${CAM_UPPER}_fieldsums_static.png)
![Field Sums No Average](${BASE_URL}${CAM_UPPER}_fieldsums_noavg_static.png)

---

## 🎯 Radiants & Calibration Reports

### Detected Radiants
![Radiants Map](${BASE_URL}${CAM_UPPER}_radiants_static.png)

### Calibration Performance
| Astrometry Calibration | Photometry Calibration |
| :---: | :---: |
| ![Astrometry Report](${BASE_URL}${CAM_UPPER}_calib_report_astrometry_static.jpg) | ![Photometry Report](${BASE_URL}${CAM_UPPER}_calib_report_photometry_static.png) |

| Calibration Variation | Photometry Variation |
| :---: | :---: |
| ![Calibration Variation](${BASE_URL}${CAM_UPPER}_calibration_variation_static.png) | ![Photometry Variation](${BASE_URL}${CAM_UPPER}_photometry_variation_static.png) |

---

## ⚙️ Mask & Calibration References

| Camera Mask | Masked Flat |
| :---: | :---: |
| ![Mask](${BASE_URL}mask_static.bmp) | ![Masked Flat](${BASE_URL}masked_flat_static.jpg) |

---

## 📄 Raw Output Data

* **Text Summary:** [View Raw Text Summary](${BASE_URL}${CAM_UPPER}_observation_summary_static.txt)
* **JSON Summary:** [View Raw JSON Data](${BASE_URL}${CAM_UPPER}_observation_summary_static.json)
EOF

  # Append row to Dashboard table
  STATUS_TABLE_ROWS="${STATUS_TABLE_ROWS}| **${CAM_UPPER}** | ${STATUS_BADGE} | **${METEOR_COUNT}** | [![${CAM_UPPER}](${BASE_URL}${CAM_UPPER}_stack_meteors_static.jpg)](${BASE_URL}${CAM_UPPER}_stack_meteors_static.jpg) | [View Report](/reports/${CAM_LOWER}/) \| [Server Data](${BASE_URL}) |\n"

done

# -------------------------------------------------------------
# 2. Generate Static Consolidated Status Page
# -------------------------------------------------------------
cat <<EOF > "$STATUS_FILE"
---
title: "Camera Network Overview"
date: ${DATE}T06:00:00+00:00
draft: false
---

## 📡 Daily Camera Status Dashboard

> **Last Refreshed:** \`${DATE}\`

| Camera | Status | Meteors (ML) | Latest Stack Preview | Quick Links |
| :---: | :---: | :---: | :---: | :---: |
$(echo -e "$STATUS_TABLE_ROWS")

---

### ℹ️ Raw JSON Feeds
$(for CAM in "${CAMERAS[@]}"; do
  CAM_UPPER=$(echo "$CAM" | tr '[:lower:]' '[:upper:]')
  echo "* **${CAM_UPPER}:** [observation_summary_static.json](https://globalmeteornetwork.org/weblog/UK/${CAM_UPPER}/static/${CAM_UPPER}_observation_summary_static.json)"
done)
EOF

echo "Static reports and detailed JSON tables successfully generated!"
