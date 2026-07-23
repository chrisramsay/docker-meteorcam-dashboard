# ☄️ Global Meteor Network - Local Dashboard

An automated, containerized dashboard that aggregates nightly observation summaries, statistics, and static visual outputs from multiple Global Meteor Network (GMN) RMS cameras into a locally hosted [Hugo](https://gohugo.io/) website served via Nginx.

---

## 📌 Features

* **Automated Data Fetching:** Nightly cron job fetches raw `observation_summary_static.json` files over HTTP directly from the GMN server.
* **ML Detection Tracking:** Automatically parses machine-learning verified meteor counts (`detections_after_ml`), observing duration, and hardware metrics.
* **Consolidated Network Dashboard:** Displays a side-by-side status grid (`/status/`) showing online state, meteor counts, and stack previews across all configured cameras.
* **Detailed Nightly Camera Reports:** Generates structured Markdown pages featuring timelapse videos, image stacks, radiants, calibration reports, and full JSON data tables.
* **Zero Host Dependencies:** Runs entirely inside a lightweight Docker container (Alpine + Hugo + Nginx + Python 3 + Cron).

---

## 📁 Repository Structure

```text
meteor-dashboard/
├── .gitignore
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── generate_meteor_reports.sh
├── README.md
└── meteors/                  # Hugo Site Source (Mounted as Volume)
    ├── config.toml
    ├── content/
    │   ├── reports/          # Auto-generated camera reports (.md)
    │   └── _index.md         # Auto-generated network dashboard
    └── layouts/
        └── shortcodes/
            └── video.html    # Shortcode for timelapse MP4 playback

```

---

## 🚀 Quick Start & Deployment

### Prerequisites

* [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/) installed on the host machine (e.g., Ubuntu, Debian, or OpenMediaVault).

### 1. Clone the Repository

```bash
git clone [https://github.com/YOUR_USERNAME/meteor-dashboard.git](https://github.com/YOUR_USERNAME/meteor-dashboard.git)
cd meteor-dashboard

```

### 2. Launch the Container

Build and start the background service:

```bash
docker compose up -d --build

```

### 3. Access the Dashboard

Open your web browser and navigate to:

```text
http://<HOST_IP>:8088

```

* **Network Status Overview:** `http://<HOST_IP>:8088/status/`
* **Individual Camera Reports:** `http://<HOST_IP>:8088/reports/uk002/`

---

## ⏱️ How Automation Works

1. **On Boot:** The container entrypoint script (`entrypoint.sh`) triggers `generate_meteor_reports.sh` immediately to fetch the latest camera summaries and compile the Hugo static HTML into `meteors/public/`.
2. **Daily Schedule:** An internal `crond` task runs automatically every morning at **06:00 AM**:
* Downloads fresh JSON metadata from `globalmeteornetwork.org`.
* Overwrites static Markdown files inside `meteors/content/reports/`.
* Re-compiles the Hugo site.


3. **Serving:** Nginx instantly serves the newly compiled HTML directly from the mounted `./meteors/public` volume.

---

## ⚙️ Customization & Configuration

* **Add/Remove Cameras:** Edit the `CAMERAS` array at the top of `generate_meteor_reports.sh`:
```bash
CAMERAS=("uk002" "uk002z" "uk004b" "uk008f" "uk0098")

```


* **Port Mapping:** To change the HTTP web port from `8088`, update the `ports` mapping in `docker-compose.yml`:
```yaml
ports:
  - "YOUR_PORT:80"

```


* **Cron Execution Time:** To adjust when the daily update runs, modify the crontab schedule inside `entrypoint.sh`:
```bash
# Example: Run every morning at 06:00 AM
0 6 * * * /app/generate_meteor_reports.sh && cd /app/meteors && hugo

```



---

## 📄 License

Distributed under the MIT License. Feel free to modify and adapt for your own GMN station network.

```

```
