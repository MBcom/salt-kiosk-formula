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
{% endif %}

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
          enabled: "{{ kiosk.clock.enabled }}"
          format: "{{ kiosk.clock.format }}"
          height: "{{ kiosk.clock.height }}"
          font: "{{ kiosk.clock.font }}"
          color: "{{ kiosk.clock.color }}"
          bgcolor: "{{ kiosk.clock.bgcolor }}"
        
    - require:
      - user: kiosk_user_account
      - pkg: kiosk_base_packages # Ensure xinit is installed
      - pkg: google_chrome_installed
