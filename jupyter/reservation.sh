#!/usr/bin/env bash
node_type=compute_haswell

lease_name="${USER:-my}-jupyter-server-$(date +%b%d)"
network_name="jupyter_net" # Should match default in Heat template
public_network_id=$(openstack network show public -f value -c id)

echo "Requesting lease for:"
echo " - 1 bare metal node (type=$node_type)"
echo " - 1 isolated network"
echo " - 1 Floating IP"
echo

blazar lease-create \
  --physical-reservation min=1,max=1,resource_properties="[\"=\", \"\$node_type\", \"$node_type\"]" \
  --reservation resource_type=network,network_name="$network_name",resource_properties='["==","$physical_network","physnet1"]' \
  --reservation resource_type=virtual:floatingip,network_id="$public_network_id",amount=1 \
  --start-date "$(date +'%Y-%m-%d %H:%M')" \
  --end-date "$(date +'%Y-%m-%d %H:%M' -d'+1 day')" \
  "$lease_name"

echo "Waiting for lease to start"
echo

timeout 300 bash -c 'until [[ $(blazar lease-show $0 -f value -c status) == "ACTIVE" ]]; do sleep 1; done' "$lease_name" \
    && echo "Lease started successfully!"

reservations=$(blazar lease-show "$lease_name" -f json \
  | jq -r '.reservations')
host_reservation_id=$(jq -rs 'map(select(.resource_type=="physical:host"))[].id' <<<"$reservations")
fip_reservation_id=$(jq -rs 'map(select(.resource_type=="virtual:floatingip"))[].id' <<<"$reservations")

fip_id=$(openstack floating ip list --tags "reservation:$fip_reservation_id" \
  -f value -c "ID")

echo
echo "Stack parameters:"
echo "- floating_ip=$fip_id"
echo "- network_name=$network_name"
echo "- reservation_id=$host_reservation_id"
