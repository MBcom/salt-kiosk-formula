# salt/kiosk/browser.sls
{%- from tpldir ~ "/map.jinja" import kiosk with context %}

{% set user = kiosk.user %}
{% set home = kiosk.user_home %}
{% set start_url = kiosk.start_url %}
{% set additionalChromeArgs = kiosk.additionalChromeArgs %}

# load kiosk.chromePolicies and store them to /etc/opt/chrome/policies/managed/kiosk.json
{% if kiosk.chromePolicies %}
kiosk_chrome_policies:
  file.managed:
    - name: /etc/opt/chrome/policies/managed/kiosk.json
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - makedirs: True
    - contents: |
        {{ kiosk.chromePolicies | tojson }}
{% else %}
kiosk_chrome_policies:
  file.absent:
    - name: /etc/opt/chrome/policies/managed/kiosk.json
{% endif %}

{%- if kiosk.chromeEnrollmentToken %}
# Create the Chrome enrollment token file
kiosk_chrome_enrollment_token:
  file.managed:
    - name: /etc/opt/chrome/policies/enrollment/CloudManagementEnrollmentToken
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - makedirs: True
    - contents: |
        {{ kiosk.chromeEnrollmentToken }}
{% else %}
kiosk_chrome_enrollment_token:
  file.absent:
    - name: /etc/opt/chrome/policies/enrollment/CloudManagementEnrollmentToken
{%- endif %}

# Create the .xinitrc file in the kiosk user's home directory
kiosk_user_xinitrc:
  file.managed:
    - name: {{ home }}/.xinitrc
    - source: salt://kiosk/files/user/dot_xinitrc
    - user: {{ user }}
    - group: {{ user }}
    - mode: 755  # Needs to be executable
    - template: jinja
    - context:
        startUrl: {{ start_url }}
        additionalChromeArgs: "{{ additionalChromeArgs }}"
        kioskmode: {% if kiosk.chromeKioskMode %}"--kiosk"{% else %}""{% endif %}
        screenPowerManagement: {{ kiosk.screen_power_management.enabled }}
        blank_time: {{ kiosk.screen_power_management.blank_time }}
        poweroff_time: {{ kiosk.screen_power_management.poweroff_time }}
        displays: {{ kiosk.displays }}
        clock:
          enabled: {{ kiosk.clock.enabled }}
          format: "{{ kiosk.clock.format }}"
          height: "{{ kiosk.clock.height }}"
          font: "{{ kiosk.clock.font }}"
          color: "{{ kiosk.clock.color }}"
          bgcolor: "{{ kiosk.clock.bgcolor }}"
        disable_unused_ttys: {{ kiosk.disable_unused_ttys }}
        disable_keys: {{ kiosk.disable_keys }}
        
    - require:
      - user: kiosk_user_account
      - pkg: kiosk_base_packages # Ensure xinit is installed
      - pkg: google_chrome_installed

{%- if kiosk.certificates.import_system_cas %}
{% set nssdb = home + '/.pki/nssdb' %}

# Ensure Chrome's certificate directory exists
ensure_chrome_cert_dir:
  file.directory:
    - name: {{ nssdb }}
    - user: {{ user }}
    - group: {{ user }}
    - mode: 700
    - makedirs: True
    - require:
      - user: kiosk_user_account

# Initialize NSS database if it doesn't exist
init_nss_db:
  cmd.run:
    - name: certutil -d sql:{{ nssdb }} -N --empty-password
    - runas: {{ user }}
    - unless: test -f {{ nssdb }}/cert9.db
    - require:
      - file: ensure_chrome_cert_dir
      - pkg: kiosk_base_packages

{%-   for cert in salt['cmd.run']('find /usr/share/ca-certificates/ -type f -name "*.crt"').split() %}
{%-     set cert_name = cert | regex_replace('\.crt$/', '') %}
import_system_ca_{{ cert | replace('/', '_') }}:
  cmd.run:
    - name: certutil -d sql:{{ nssdb }} -A -t "C,," -n "{{ cert_name }}" -i "{{ cert }}"
    - runas: {{ user }}
    - unless: certutil -d sql:{{ nssdb }} -L -n "{{ cert_name }}"
    - require:
      - cmd: init_nss_db
{%-   endfor %}
{%- endif %}