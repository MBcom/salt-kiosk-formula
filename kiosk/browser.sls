# salt/kiosk/browser.sls
{%- from tpldir ~ "/map.jinja" import kiosk with context %}

{% set user = kiosk.user %}
{% set home = kiosk.user_home %}
{% set start_url = kiosk.start_url %}
{% set additionalChromeArgs = kiosk.additionalChromeArgs %}


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
        
    - require:
      - user: kiosk_user_account
      - pkg: kiosk_base_packages # Ensure xinit is installed
      - pkg: google_chrome_installed
