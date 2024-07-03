dnf -y install --assumeyes centos-release-ceph-reef
dnf -y install --assumeyes cephadm

mkdir -p /etc/ceph
mon_ip=$(hostname -I)
cephadm bootstrap --mon-ip $mon_ip --allow-fqdn-hostname --initial-dashboard-password {{ admin_password }}
fsid=$(cat /etc/ceph/ceph.conf | grep fsid | awk '{ print $3}')
{% for number in range(1, nodes) %}
  ssh-copy-id -f -i /etc/ceph/ceph.pub -o StrictHostKeyChecking=no root@{{ prefix }}-node-0{{ number }}
  cephadm shell --fsid $fsid -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring ceph orch host add {{ prefix }}-node-0{{ number }}.{{domain}}
{% endfor %}
cephadm shell --fsid $fsid -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring ceph orch apply osd --all-available-devices
