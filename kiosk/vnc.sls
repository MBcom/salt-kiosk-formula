# salt/kiosk/vnc.sls
{%- from tpldir ~ "/map.jinja" import kiosk with context %}

{% set user = kiosk.user %}
{% set home = kiosk.user_home %}
{% set vnc_password = kiosk.vnc_password %}
{% set vnc_passwd_file = home + '/.vncpasswd' %}
{% set vnc_display_port = kiosk.vnc_display_port %}
{% set novnc_port = kiosk.novnc_port %}
{% set novnc_web_dir = '/usr/share/novnc' %} # Path might vary depending on package

# Create VNC password file
# Note: Storing plain text password in pillar is not ideal.
# Consider pre-generating the hash or using Salt's encrypted pillar.
# This command needs x11vnc installed.
generate_vnc_password_file:
  cmd.run:
    - name: |
        x11vnc -storepasswd "{{ vnc_password }}" {{ vnc_passwd_file }}
    - unless: test -f {{ vnc_passwd_file }}
    - runas: {{ user }}
    - require:
      - pkg: kiosk_base_packages # Ensure x11vnc is installed
      - user: kiosk_user_account # Ensure user exists

# Secure the VNC password file
vnc_password_file_perms:
  file.managed:
    - name: {{ vnc_passwd_file }}
    - user: {{ user }}   # <-- OWNED BY KIOSK USER
    - group: {{ user }}  # <-- OWNED BY KIOSK USER
    - mode: 600          # <-- Read/Write only for owner
    - watch:
      - cmd: generate_vnc_password_file

# Systemd service file for x11vnc
x11vnc_service_file:
  file.managed:
    - name: /etc/systemd/system/x11vnc.service
    - source: salt://kiosk/files/systemd/x11vnc.service
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
        kiosk_user: {{ user }} # Pass user to template
        vnc_passwd_file: {{ vnc_passwd_file }}
        vnc_display_port: {{ vnc_display_port }}
    - require:
      - file: vnc_password_file_perms # Require password file exists

# Systemd service file for noVNC (via websockify)
novnc_service_file:
  file.managed:
    - name: /etc/systemd/system/novnc.service
    - source: salt://kiosk/files/systemd/novnc.service
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
        novnc_web_dir: {{ novnc_web_dir }}
        kiosk_user: {{ user }} # Pass user to template
        novnc_port: {{ novnc_port }}
        vnc_display_port: {{ vnc_display_port }}
    - require:
      - pkg: kiosk_base_packages # Ensure novnc/websockify installed

# Reload systemd, enable and start services
reload_systemd_for_vnc:
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: x11vnc_service_file
      - file: novnc_service_file

x11vnc_service:
  service.running:
    - name: x11vnc
    - enable: True
    - watch:
      - file: x11vnc_service_file
      - cmd: generate_vnc_password_file # Restart if password changes
      - file: vnc_password_file_perms
    # We need X to be running. This dependency is tricky via systemd only.
    # The service file itself tries to handle restarts/waits.

novnc_service:
  service.running:
    - name: novnc
    - enable: True
    - watch:
      - file: novnc_service_file
      - service: x11vnc_service # Restart novnc if x11vnc restarts