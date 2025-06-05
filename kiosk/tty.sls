{%- from tpldir ~ "/map.jinja" import kiosk with context %}

# Disable unused TTYs if configured
{%- if kiosk.disable_unused_ttys %}
{%-   for tty in range(2, 7) %}
kiosk_disable_tty{{ tty }}:
  service.dead:
    - name: getty@tty{{ tty }}.service
    - enable: False
{%-   endfor %}

kiosk_limit_ttys:
  file.managed:
    - name: /etc/systemd/logind.conf.d/disable-ttys.conf
    - makedirs: True
    - contents: |
        [Login]
        NAutoVTs=1
        ReserveVT=1

# Prevent VT switching in X11
kiosk_prevent_vt_switch:
  file.managed:
    - name: /etc/X11/xorg.conf.d/10-novtswitch.conf
    - makedirs: True
    - contents: |
        Section "ServerFlags"
            Option "DontVTSwitch" "true"
        EndSection
{% else %}
# Ensure unused TTYs are enabled if not configured to disable them
kiosk_limit_ttys:
  file.absent:
    - name: /etc/systemd/logind.conf.d/disable-ttys.conf

kiosk_prevent_vt_switch:
  file.absent:
    - name: /etc/X11/xorg.conf.d/10-novtswitch.conf
{%- endif %}

# Reload systemd to apply changes
kiosk_reload_systemd:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: kiosk_limit_ttys