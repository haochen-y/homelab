# Linux Commands

## GUI Targets
Switch between text-only and graphical sessions with either the traditional
`init` commands or their `systemd` equivalents:

```bash
sudo init 3
sudo systemctl isolate multi-user.target

sudo init 5
sudo systemctl isolate graphical.target
```

## Change Default Boot Target
Pick which target the system boots into by default:

```bash
# Boot straight to a CLI
sudo systemctl set-default multi-user.target

# Boot to the graphical desktop
sudo systemctl set-default graphical.target
```

## Laptop Lid Config
Edit `/etc/systemd/logind.conf` and override the handlers to stop lid actions:

```ini
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

### Optional minimalist overrides

```ini
HandlePowerKey=ignore
HandleRebootKey=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
```

### Apply the changes immediately

```bash
sudo systemctl restart systemd-logind
```

## Graphical Setting for Screen Blanking
Disable automatic suspend, shorten idle delay, and stop the lock screen:

```bash
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'

# time
gsettings set org.gnome.desktop.session idle-delay 60

# disable lock screen
gsettings set org.gnome.desktop.screensaver lock-enabled false
```


## Console Setting for Screen Blanking
1. Edit `/etc/default/grub`:

   ```bash
   sudo nano /etc/default/grub
   ```

2. Update the kernel command line:

   ```conf
   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
   # becomes
   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash consoleblank=60"
   ```

3. Save, then rebuild the GRUB config:

   ```bash
   sudo update-grub
   ```


