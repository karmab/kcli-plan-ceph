dnf -y install --assumeyes centos-release-ceph-{{ version }}
dnf -y install --assumeyes cephadm

mkdir -p /etc/ceph
mon_ip=$(hostname -I)
cephadm bootstrap --mon-ip $mon_ip --allow-fqdn-hostname --initial-dashboard-password {{ admin_password }} --dashboard-password-noupdate
fsid=$(cat /etc/ceph/ceph.conf | grep fsid | awk '{ print $3}')
{% for number in range(1, nodes) %}
  {% set ip = '{0}-node-0{1}'.format(plan, number)|kcli_info('ip', client=client|default(config_client), wait=True) %}
  echo {{ ip }} {{ plan }}-node-0{{ number }}.{{domain}} >> /etc/hosts
  ssh-copy-id -f -i /etc/ceph/ceph.pub -o StrictHostKeyChecking=no root@{{ plan }}-node-0{{ number }}.{{domain}}
  cephadm shell --fsid $fsid -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring ceph orch host add {{ plan }}-node-0{{ number }}.{{domain}} {{ ip }}
{% endfor %}
cephadm shell --fsid $fsid -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring ceph orch apply osd --all-available-devices
