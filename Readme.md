# Salt Kiosk Formula

**Do you have any screens (like self-service portals in your shop, screens to display KPIs or even advertising) or PCs which just need to run a browser? Do you want a small footprint setup using open-source software?** This SaltStack formula is the right one for you.

A SaltStack formula to configure plain Debian PCs machines as kiosk devices with the following features:

- Automatic login
- Chrome browser in kiosk mode
- VNC remote access with web interface (noVNC)
- Automatic power management
- Dedicated unpriveledged kiosk user account
- X11 session autostart
- no need to install a GUI in debian
- small ressource foot print - does not use any display manager
- Optional screen power saving
- Optional turn off kiosk mode to create browser only work stations
- Support for [Chrome polcies](https://support.google.com/chrome/a/answer/9027408?hl=en) to manage Google Chrome Browser settings like bookmarks etc.
  
**Do you also looking for an web app to centrally manage your kiosk screens?** Have a look at [Kiosk Manager](https://github.com/MBcom/kioskmanager). It's also open source ;)  
  
**Do you want to show your companie's or personal logo during startup?** Have a look at [SaltStack plymouth formula](https://github.com/MBcom/salt-plymouth-formula). It's also open source ;)  
  
## Requirements

- SaltStack
- Linux system with systemd

## Configuration

Create your pillar data based on the [pillar.example](pillar.example):

```yaml
kiosk:
  user_password: "CHANGE-ME" # User password
  
  # Browser settings
  start_url: "https://www.google.com"

  # VNC access
  vnc_password: "CHANGE-ME"  # VNC access password
  
  #############################
  # Optional: Power management
  #############################
  power:
    my_schedule1:
      enabled: True
      shutdown_time: 22          # 24h format
      shutdown_time_minute: 0
      shutdown_daymonth: '*'     # Day of month (1-31 or *)
      shutdown_month: '*'        # Month (1-12 or *)
      shutdown_dayweek: '*'      # Day of week (0-6 or *)

  # ---- or ----
  rtcwake:
    my_schedule1:
      enabled: True
      mode: "off"                 # Possible values: freeze, standby, mem, disk, off  See https://wiki.ubuntuusers.de/rtcwake/#Optionen
      start_hour: 18            # Start rtcwake at 6 PM
      start_minute: 0
      start_daymonth: '*'       # Day of month (1-31 or *)
      start_month: '*'          # Month (1-12 or *)
      start_dayweek: '*'        # Day of week (0-6 or *)
      duration: 43200           # Wake up after 12 hours (in seconds)
```

You can find a full example in `.\pillar.example`. You will any default values in `.\kiosk\defaults.yaml`.

## Features

### Automatic Login
- Configures systemd for automatic login
- Starts X11 session on login
- Launches Chrome in kiosk mode

### Browser Setup
- Runs google chrome in kiosk mode
- Auto-restarts on crash
- Configurable startup URL
- Optional Chrome flags

### Remote Access
- noVNC web interface to control your kiosk pc remotely and provide support to end users
- Password protected
- Local-only by default (localhost) - use ssh tunneling to get a save/ encrypted connection

### Power Management
- Scheduled shutdown support
- Configurable shutdown time
- Optional enable/disable
- rtcwake support - power down your kiosk for a given time period

### Screen Power Management
- Optional screen power saving
- Configurable screen blank time
- Configurable screen power off time
- Automatic reactivation on mouse/keyboard activity

### Browser Work station
You can set `chromeKioskMode: False` in your Pillar to show Google Chrome as normal but without the ability to minimize or close the window.  
You can use this method to support work environments which entirely run on the web.  
I would recommend to turn on private mode by setting `additionalChromeArgs: "--incognito --disable-features=PasswordManager"` in your Pillar to prevent users from storing passwords if the work stations are used by different employees.  
  
You can also set `chromePolicies` to a Google Chrome Policy JSON or YAML.
You can look for an example [here](https://github.com/google/ChromeBrowserEnterprise/blob/main/docs/policy_examples/managed_policies.json).
The documentation can be found [here](https://chromeenterprise.google/policies/).
This allows you to also set bookmarks or install specific extensions.  
  
Configuration example:
```yaml
kiosk:
  screen_power_management:
    enabled: True               # Enable screen power management
    blank_time: 20             # Minutes before screen blanking
    poweroff_time: 30          # Minutes before turning off screen
```

The screen will:
1. Blank after specified minutes of inactivity
2. Turn off after specified minutes of inactivity
3. Automatically turn back on with any keyboard or mouse activity

## Usage

1. Include this formula in your Salt state
2. Configure pillar data
3. Apply the state:

```bash
salt '*' state.apply kiosk
```

### Remote Support
You can connect to the PC remotely using SSH and forward the noVNC port to your own machine.
You can view and control anything the end user can see and do on the connected monitor.  
  
1. Create a port forwarding using SSH to your kiosk PC. You can use the `kiosk` account created by this formula and the password you configured in your pillar under `kiosk.user_password`, or use any other user account you have access to (For example, use another SaltStack formula to manage additional users or distribute your SSH keys on the system.):

```bash
ssh -L 6080:localhost:6080 kiosk@your-kiosk-pc
```

2. Open your browser at `http://localhost:6080` and enter the password you configured in your pillar under `kiosk.vnc_password`. You should see the same screen that is displayed on the connected monitor.

### Troubleshooting
All relevant logs are stored in:
* `/tmp/kiosk_startup.log` - Informational messages and Chrome logs
* `/tmp/kiosk_error.log` - Error messages like Chrome shutdowns

Note: These logs are cleared during system startup.

## Security Considerations

- Change default passwords in pillar data
- VNC server only listens on localhost
- Consider using encrypted pillar values
- Review Chrome security settings

## Files

- init.sls: Main entry point
- install.sls: Package installation
- browser.sls: Chrome configuration
- vnc.sls: Remote access setup
- power.sls: Power management
- user.sls: User account setup
- autologin.sls: Automatic login configuration
- tty.sls: TTY management

## Customization

The formula can be customized through pillar data and map.jinja for:

- OS-specific settings
- Package names
- File paths
- Browser arguments
- Power schedules
