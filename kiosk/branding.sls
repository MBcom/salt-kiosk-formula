{%- from tpldir ~ "/map.jinja" import kiosk with context %}

{% set user = kiosk.user %}
{% set home = kiosk.user_home %}

kiosk_touch_hushlogin:
  file.managed:
    - name: {{ home }}/.hushlogin
    - user: {{ user }}
    - group: {{ user }}
    - mode: 644  # Readable by the user and group, but not executable
    - contents: ""  # Empty file to suppress login messages
    - require:
      - user: kiosk_user_account