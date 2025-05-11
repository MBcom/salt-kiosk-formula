# salt/kiosk/user.sls
{%- from tpldir ~ "/map.jinja" import kiosk with context %}

{% set user = kiosk.user %}
{% set home = kiosk.user_home %}
{% set password = kiosk.user_password %}

# Create the kiosk user group
kiosk_user_group:
  group.present:
    - name: {{ user }}

# Create the kiosk user
kiosk_user_account:
  user.present:
    - name: {{ user }}
    - fullname: Kiosk User
    - shell: /bin/bash
    - home: {{ home }}
    - password: {{ password }}  # Consider using user.present with password hash for better security
    - groups:
      - {{ user }}
      - video  # Often needed for direct graphics access
      - audio  # If sound is needed
      # Add other groups if necessary (e.g., tty)
    - require:
      - group: kiosk_user_group