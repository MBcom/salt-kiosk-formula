{%- from tpldir ~ "/map.jinja" import kiosk with context %}

# Disable unused TTYs if configured
{%- if kiosk.disable_unused_ttys %}
{%-   for tty in range(2, 7) %}
kiosk_disable_tty{{ tty }}:
  service.dead:
    - name: getty@tty{{ tty }}.service
    - enable: False
{%-   endfor %}
{%- endif %}