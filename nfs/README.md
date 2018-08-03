This appliance deploys an NFS server with a configurable number of clients. The NFS server creates a directory at /exports/example, changes its ownership to the "cc" user and group, and exports it. The NFS clients add this NFS share to /etc/fstab and mount it.

This appliance accepts the following parameters:

    nfs_client_count: Number of NFS client instances (defaults to 1)
    key_name: name of a key pair to enable SSH access to the instance (defaults to "default")
    reservation_id: ID of the Blazar reservation to use for launching instances

The following outputs are provided:

    server_ip: the public IP address of the NFS server
    client_ips: the private IP addresses of the NFS clients

