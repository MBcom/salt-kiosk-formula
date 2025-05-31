# Essential packages for X11, window manager, VNC, SSH, etc.
kiosk_base_packages:
  pkg.installed:
    - pkgs:
      - xorg             # X.Org server and utilities
      - xinit            # For starting X session with startx
      - x11vnc           # VNC server that mirrors the physical display :0
      - novnc            # The noVNC web client + websockify
      - websockify       # Often bundled with novnc, but ensure it's present
      - curl             # Utility often needed for repo keys/setup
      - gnupg            # For handling repository keys
      # Add basic fonts to prevent rendering issues
      - fonts-liberation
      - fonts-dejavu-core
      - wget
      - xdotool

# --- Browser Installation ---

# Common setup for Chrome/Edge repos
browser_repo_setup_pkgs:
  pkg.installed:
    - pkgs:
      - apt-transport-https
      - ca-certificates


google_chrome_repo_key:
  cmd.run:
    - name: curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | sudo tee /usr/share/keyrings/google-chrome-keyring.gpg > /dev/null
    - unless: test -f /usr/share/keyrings/google-chrome-keyring.gpg
    - require:
      - pkg: browser_repo_setup_pkgs
      - pkg: kiosk_base_packages

google_chrome_repo:
  pkgrepo.managed:
    - name: deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main
    - file: /etc/apt/sources.list.d/google-chrome.list
    - require:
      - cmd: google_chrome_repo_key
    - watch_in:
      - pkg: google_chrome_installed

google_chrome_installed:
  pkg.installed:
    - name: google-chrome-stable
    - refresh: True  # Refresh package db after adding repo