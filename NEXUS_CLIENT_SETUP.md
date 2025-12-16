
# Homelab Nexus – Client Configuration Guide

Use this to connect clients (Docker, PyPI/pip, Conda, Hugging Face, Ubuntu APT) to your Nexus, how auth works, and how to onboard friends.

---

## 0. At a Glance

- **Base URL:** `http://bigmaninc.party:4926`
- **Hosts to use for `<HOST>`:** `bigmaninc.party:4926/docker` or your LAN IP, e.g. `192.168.0.193`.
- **Repositories:**

  | Format        | Repository          | Type    | Upstream                                |
  | ------------- | ------------------- | ------- | --------------------------------------- |
  | Docker        | `docker-hosted`     | hosted  | —                                       |
  |               | `docker-proxy`      | proxy   | Docker Hub                              |
  |               | `docker`            | group   | hosted + proxy                          |
  | PyPI          | `pypi`              | proxy   | https://pypi.org/                       |
  | Conda         | `conda`             | proxy   | https://conda.anaconda.org/conda-forge  |
  | Hugging Face  | `hf-proxy`          | proxy   | https://huggingface.co                  |
  | Ubuntu (APT)  | `ubuntu-jammy`      | proxy   | http://mirror.math.princeton.edu/pub/ubuntu/ (jammy)

---

## 1. Nexus Users & Authentication

### Nexus users

If you just need a ready account:

- Username: `bozo`
- Password: `4444`

## 2. Docker – Self-Hosted Images + Docker Hub Cache

### 2.1 Configure Docker daemon (insecure registry)

**File (Linux):** `/etc/docker/daemon.json`

Create or edit:

```json
{
  "insecure-registries": ["bigmaninc.party:4926"]
}
```

To make daemon always pull from nexus

If there are existing entries, just add the `"insecure-registries"` array or append to it.

**Restart Docker:**

```bash
sudo systemctl restart docker
```

On Docker Desktop (Mac/Windows):
Settings → Docker Engine → add `"insecure-registries": ["bigmaninc.party:4926:"]` → Apply & Restart.

### 2.2 Authenticate to Nexus

```bash
docker login bigmaninc.party:4926
```

* Username: your Nexus user (`admin`, `friend1`, …)
* Password: that user’s password

### 2.3 Push your own images (via `docker`)

```bash
docker pull alpine:latest

# Tag image to go through the group repo
docker tag alpine:latest bigmaninc.party:4926/docker/alpine-test:1.0

# Push
docker push bigmaninc.party:4926/docker/alpine-test:1.0

# Test pulling back
docker pull bigmaninc.party:4926/docker/alpine-test:1.0
```

### 2.4 Use Nexus as Docker Hub cache

Pull public images through the group repo:

```bash
docker pull bigmaninc.party:4926/docker/alpine:latest
```
---

## 3. PyPI / pip – Private Python Packages + pypi.org Cache

You have:

* `pypi` (proxy → `https://pypi.org/`)

### 3.1 pip configuration (no auth)

**File (Linux/macOS):** `~/.config/pip/pip.conf`
**File (Windows):** `%APPDATA%\pip\pip.ini`

```ini
[global]
index-url = http://bigmaninc.party:4926/repository/pypi/simple
trusted-host = bigmaninc.party
```

Usage:

```bash
pip install requests
```

All installs go via Nexus:

* Public packages from `pypi` (cached from pypi.org)

### 3.2 pip configuration with Nexus auth

If you require login for `pypi`:

**Option A – Embed credentials in URL (simplest):**

```ini
[global]
index-url = http://friend1:password@bigmaninc.party:4926/repository/pypi/simple
trusted-host = bigmaninc.party
```

**Option B – Use keyring (more secure, more setup):**

1. Configure index without credentials:

   ```ini
   [global]
   index-url = http://bigmaninc.party:4926/repository/pypi/simple
   trusted-host = bigmaninc.party
   ```

2. Install keyring:

   ```bash
   python -m pip install keyring
   ```

3. First time pip prompts for creds, they’re stored in OS keyring.

---

## 4. Conda / Mamba – conda-forge Cache via Nexus

You have:

* `conda` (proxy → `https://conda.anaconda.org/conda-forge`)

### 4.1 Configure `.condarc`

**File:** `~/.condarc`

```yaml
channels:
  - conda-forge

channel_alias: http://bigmaninc.party:4926/repository/
default_channels: []
channel_priority: strict
ssl_verify: true  # set to false if you only use HTTP in a trusted LAN
```

Interpretation:

* `conda-forge` channel becomes:
  `http://bigmaninc.party:4926/repository/conda`
* `channel_priority: strict` keeps things from one ecosystem (conda-forge) and avoids mixing with defaults.

### 4.2 Create and use environments

```bash
conda create -n myenv python=3.11
conda activate myenv
conda install numpy
```

Or, with `mamba`:

```bash
mamba create -n myenv -c conda-forge python=3.11 numpy
```

All downloads go via Nexus and are cached.

### 4.3 Conda with Nexus auth (optional)

If you protect `conda`:

You can embed credentials in `channel_alias`:

```yaml
channel_alias: http://friend1:password@bigmaninc.party:4926/repository/
```

Now `conda-forge` access uses `friend1`’s Nexus account.

---

## 5. Hugging Face – Model Cache via Nexus

* `hf-proxy` (proxy → `https://huggingface.co`)

### 5.1 Basic usage (public models, anonymous Nexus read)

Set environment variable:

```bash
export HF_HUB_BASE_URL="http://bigmaninc.party:4926/repository/hf-proxy"
```

Example in Python:

```python
from huggingface_hub import hf_hub_download

hf_hub_download(
    repo_id="bert-base-uncased",
    filename="pytorch_model.bin",
    base_url="http://bigmaninc.party:4926/repository/hf-proxy",
)
```

### 5.2 Private Hugging Face models

For private models, you still need HF auth:

```bash
export HF_TOKEN="hf_xxx_your_token_here"
export HF_HUB_BASE_URL="http://bigmaninc.party:4926/repository/hf-proxy"
```

Or login via `huggingface-cli login`.

Nexus forwards authenticated requests upstream; the HF token stays on the client side.

## 6. Ubuntu / APT – Package Cache via Nexus

You have:

* `ubuntu-jammy` (APT proxy → `http://mirror.math.princeton.edu/pub/ubuntu/`, distribution `jammy`)

### 6.1 Add Nexus APT source

**File:** `/etc/apt/sources.list.d/nexus-ubuntu-jammy.list`

```bash
echo "deb [trusted=yes] http://bigmaninc.party:4926/repository/ubuntu-jammy jammy main restricted universe multiverse" \
  | sudo tee /etc/apt/sources.list.d/nexus-ubuntu-jammy.list
```

* `[trusted=yes]` disables GPG checks (fine for homelab). For proper signing you’d set up a key and remove this flag.

### 6.2 Refresh and use

```bash
sudo apt update
sudo apt install curl  # example
```

All packages coming from that distribution go via Nexus and are cached.

### 6.3 APT with Nexus auth (optional)

If the APT repo is protected:

Simplest (but credentials visible in file):

```bash
echo "deb [trusted=yes] http://friend1:password@bigmaninc.party:4926/repository/ubuntu-jammy jammy main restricted universe multiverse" \
  | sudo tee /etc/apt/sources.list.d/nexus-ubuntu-jammy.list
```

More secure (uses `auth.conf`):

1. **File:** `/etc/apt/auth.conf.d/nexus.conf`

   ```bash
   sudo nano /etc/apt/auth.conf.d/nexus.conf
   ```

   Put:

   ```text
   machine bigmaninc.party
   login friend1
   password PASSWORD_HERE
   ```

   Permissions:

   ```bash
   sudo chmod 600 /etc/apt/auth.conf.d/nexus.conf
   ```

2. APT source can now omit credentials in URL:

   ```bash
   echo "deb [trusted=yes] http://bigmaninc.party:4926/repository/ubuntu-jammy jammy main restricted universe multiverse" \
     | sudo tee /etc/apt/sources.list.d/nexus-ubuntu-jammy.list
   ```

---

## 7. Quick “What to Restart / Reload”

* **Docker**

  * File: `/etc/docker/daemon.json`
  * Command: `sudo systemctl restart docker`

* **pip / PyPI**

  * File: `~/.config/pip/pip.conf` (or `%APPDATA%\pip\pip.ini`)
  * No restart needed; new pip invocations read the config.

* **Conda / mamba**

  * File: `~/.condarc`
  * No restart; new conda/mamba commands use it.

* **Hugging Face**

  * Variables: `HF_HUB_BASE_URL`, `HF_TOKEN`
  * Export per-shell or in `~/.bashrc` / `~/.zshrc`.

* **APT / Ubuntu**

  * File: `/etc/apt/sources.list.d/*.list`, optional `/etc/apt/auth.conf.d/*.conf`
  * Command: `sudo apt update` after changes.

* **Nexus**

  * User/role/repo changes take effect immediately; no service restart required.

---

## 8. Sharing Nexus With a Friend – Minimal Checklist

For each friend:

1. Create a Nexus user: **Administration → Security → Users → Create local user**.
2. Give read or read+write roles for the repos they should use.
3. Give them:

   * `http://bigmaninc.party:4926`
   * Their username/password
   * This Markdown file.
4. They follow:

   * Docker section (if using Docker)
   * PyPI/pip section (if Python)
   * Conda section (if using conda-forge)
   * Hugging Face section (if using HF)
   * Ubuntu/APT section (if on Ubuntu)

That’s the full setup for turning Nexus into the central package/cache server for your homelab.
