# salt/kiosk/power.sls
{%- from tpldir ~ "/map.jinja" import kiosk with context %}

# Ensure cron package is installed (handled by packages.sls)
# kiosk_base_packages: ...
{%- for key,value in kiosk.power.items() %}
{%-   if value.enabled %}
# Add cron job for scheduled shutdown
scheduled_shutdown_{{ key }}:
  cron.present:
    - name: /sbin/poweroff # Use poweroff or shutdown -h now
    - user: root
    - minute: "{{ value.shutdown_time_minute }}"
    - hour: "{{ value.shutdown_time }}"
    - daymonth: "{{ value.shutdown_daymonth }}"
    - month: "{{ value.shutdown_month }}"
    - dayweek: "{{ value.shutdown_dayweek }}"
    - identifier: KIOSK_AUTO_SHUTDOWN_{{ key }}
    - require:
      - pkg: kiosk_base_packages # Ensure cron is installed
{%-   else %}
# Remove shutdown cron job if disabled
scheduled_shutdown_{{ key }}:
  cron.absent:
    - identifier: KIOSK_AUTO_SHUTDOWN_{{ key }}
    - user: root
{%-   endif %}
{%- endfor %}

{%- for key,value in kiosk.rtcwake.items() %}
{%-   if value.enabled %}
# Schedule wake from hibernate
scheduled_wake_{{ key }}:
  cron.present:
    - name: /usr/sbin/rtcwake -m {{ value.mode }} -s {{ value.duration }}
    - user: root
    - minute: "{{ value.start_minute }}"
    - hour: "{{ value.start_hour }}"
    - daymonth: "{{ value.start_daymonth }}"
    - month: "{{ value.start_month }}"
    - dayweek: "{{ value.start_dayweek }}"
    - identifier: KIOSK_HIBERNATE_WAKE_{{ key }}
    - require:
      - pkg: kiosk_base_packages
{%-   else %}
# Remove rtcwake cron job if disabled
scheduled_wake_{{ key }}:
  cron.absent:
    - identifier: KIOSK_HIBERNATE_WAKE_{{ key }}
    - user: root
{%-   endif %}
{%- endfor %}
