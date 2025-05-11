# salt/kiosk/power.sls
{%- from tpldir ~ "/map.jinja" import kiosk with context %}

# Ensure cron package is installed (handled by packages.sls)
# kiosk_base_packages: ...
{% if kiosk.power.enabled %}
# Add cron job for root user to shutdown at 10 PM (22:00) daily
scheduled_shutdown:
  cron.present:
    - name: /sbin/poweroff # Use poweroff or shutdown -h now
    - user: root
    - minute: {{ kiosk.power.shutdown_time_minute }}
    - hour: {{ kiosk.power.shutdown_time }}
    - identifier: KIOSK_AUTO_SHUTDOWN
    - require:
      - pkg: kiosk_base_packages # Ensure cron is installed

{% endif %}

{% if kiosk.rtcwake.enabled %}
# Schedule wake from hibernate
scheduled_wake:
  cron.present:
    - name: /usr/sbin/rtcwake -m {{ kiosk.rtcwake.mode }} -s {{ kiosk.rtcwake.duration }}
    - user: root
    - minute: {{ kiosk.rtcwake.start_minute }}
    - hour: {{ kiosk.rtcwake.start_hour }}
    - identifier: KIOSK_HIBERNATE_WAKE
    - require:
      - pkg: kiosk_base_packages
{% endif %}
