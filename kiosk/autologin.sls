# salt/kiosk/autologin.sls

{%- from tpldir ~ "/map.jinja" import kiosk with context %}
{% set user = kiosk.user %}

# Configure systemd getty service for automatic login on tty1
# Create an override file
autologin_override_dir:
  file.directory:
    - name: /etc/systemd/system/getty@tty1.service.d
    - makedirs: True

# Configure the override
# Note: '-o "-p -- \\u"' suppresses the password prompt
# Note: '--noclear' keeps boot messages visible briefly
autologin_override_conf:
  file.managed:
    - name: /etc/systemd/system/getty@tty1.service.d/override.conf
    - source: salt://kiosk/files/systemd/autologin_override.conf
    - template: jinja
    - context:
        kiosk_user: {{ user }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: autologin_override_dir

# Create a script or modify .bash_profile/.profile for the kiosk user
# This script will automatically run 'startx' if on tty1
# Using .profile ensures it runs for login shells
kiosk_user_profile:
  file.managed:
    - name: {{ pillar.get('kiosk:user_home', '/home/' + user) }}/.profile
    - source: salt://kiosk/files/user/dot_profile
    - user: {{ user }}
    - group: {{ user }}
    - mode: 644
    - template: jinja # In case you need variables later
    - require:
      - user: kiosk_user_account

# Reload systemd daemon after changing service files
reload_systemd_for_autologin:
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: autologin_override_conf