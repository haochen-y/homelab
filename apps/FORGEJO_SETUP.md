# FORGEJO SETUP (bigmaninc.party)

Forgejo (self-hosted Git) on your homelab domain.

- **HTTP Web / HTTPS clone:** `http://bigmaninc.party:3000`
- **SSH Git:** `ssh://git@bigmaninc.party:2222/...`

## Quick Start

### Create a repo
1. Open `http://bigmaninc.party:3000`
2. Create a new repository (private/public)
3. Copy the clone URL (SSH or HTTP)

### HTTP

**Clone over HTTP:**
```bash
git clone http://bigmaninc.party:3000/<USER>/<REPO>.git
````

### SSH

**Clone over SSH:**

```bash
git clone ssh://git@bigmaninc.party:2222/<USER>/<REPO>.git
```

---

## SSH Setup (required for SSH pull/push)

### 1) Generate a key (if you don’t have one)

```bash
ssh-keygen -t ed25519 -C "hy@bigmaninc.party"
```

### 2) Add your public key to Forgejo

```bash
cat ~/.ssh/id_ed25519.pub
```

Forgejo UI:

* User Settings → **SSH Keys** → **Add Key** → paste the key

### 3) Test SSH auth

```bash
ssh -F /dev/null -p 2222 git@bigmaninc.party
```

Expected: authentication success message (usually “no shell access” is normal).


## Using Forgejo + GitHub together (multiple remotes)

### Terminology

* **origin**: the default remote name (often where you push)
* **upstream**: commonly used name for the “source of truth” remote (often where you pull)

You can name remotes anything; these names are conventions.

---

## Add Forgejo as `origin` and GitHub as `upstream` (common workflow)

### 1) Clone from Forgejo (origin)

SSH:

```bash
git clone ssh://git@bigmaninc.party:2222/<USER>/<REPO>.git
cd <REPO>
```

Check remotes:

```bash
git remote -v
```

### 2) Add GitHub as `upstream`

```bash
git remote add upstream git@github.com:<GH_USER_OR_ORG>/<REPO>.git
```

Verify:

```bash
git remote -v
```

---

## Add Forgejo as `upstream` and GitHub as `origin` (also common)

If you cloned from GitHub first, GitHub will be `origin`. Add Forgejo:

```bash
git remote add forgejo ssh://git@bigmaninc.party:2222/<USER>/<REPO>.git
git remote -v
```

If you want Forgejo to become the new `origin`:

```bash
git remote rename origin github
git remote rename forgejo origin
git remote -v
```

---

## Push to both Forgejo and GitHub

### Option A (simple): push explicitly to each remote

```bash
git push origin main
git push upstream main
```

### Option B (one command): configure a “push URL” for the same remote name

This makes `git push origin` push to **both**.

Example: keep Forgejo as the fetch URL, add GitHub as an extra push URL:

```bash
git remote set-url origin ssh://git@bigmaninc.party:2222/<USER>/<REPO>.git
git remote set-url --add --push origin ssh://git@bigmaninc.party:2222/<USER>/<REPO>.git
git remote set-url --add --push origin git@github.com:<GH_USER_OR_ORG>/<REPO>.git
```

Now:

```bash
git push origin main
```

pushes to both.

Check:

```bash
git remote -v
```

> Tip: If you want pushes to go to *only one* place by default, don’t use multi-push URLs—use explicit remotes instead.

---

## Pull from the selected upstream (and keep your local branch tracking clean)

### See what branch you’re tracking

```bash
git status -sb
```

You’ll see something like:

* `## main...origin/main` (tracking `origin/main`)
* `## main...upstream/main` (tracking `upstream/main`)

### Pull from the remote your branch tracks

```bash
git pull
```

### Pull from a specific remote explicitly

```bash
git pull origin main
git pull upstream main
```

---

## Set (or change) which remote/branch your local branch tracks

### Make `main` track Forgejo `origin/main`

```bash
git branch --set-upstream-to=origin/main main
```

### Make `main` track GitHub `upstream/main`

```bash
git branch --set-upstream-to=upstream/main main
```

### One-step: set tracking when pushing the first time

```bash
git push -u origin main
```

---

## Switch a repo between HTTP and SSH

### Check current remote URL

```bash
git remote -v
```

### Change `origin` to SSH (recommended for pushing)

```bash
git remote set-url origin ssh://git@bigmaninc.party:2222/<USER>/<REPO>.git
```

### Change `origin` to HTTP

```bash
git remote set-url origin http://bigmaninc.party:3000/<USER>/<REPO>.git
```

---

## Credentials Notes

### HTTP auth (recommended)

Use a **Personal Access Token (PAT)**:

* Forgejo → User Settings → Applications → Generate Token
* Use that token as the password when Git prompts

### SSH auth (recommended)

* Add your SSH public key in Forgejo (see SSH Setup)
* No password prompts after it’s configured

---

## Useful Commands Cheat Sheet

### List remotes

```bash
git remote -v
```

### Add/remove a remote

```bash
git remote add <name> <url>
git remote remove <name>
```

### Rename a remote

```bash
git remote rename <old> <new>
```

### Fetch from all remotes (no merge)

```bash
git fetch --all --prune
```

### Compare branches across remotes

```bash
git log --oneline --decorate --graph --all
```

