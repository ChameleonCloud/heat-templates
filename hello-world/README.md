This is a basic complex appliance, for learning purposes. It creates a login
server with a public IP and then several instances that can only be accessed
via the login server.

This appliance accepts the following parameters:

    instance_count: the number of instance nodes to provision (in addition to the login server)
    key_name: name of a key pair to enable SSH access to the instances (defaults to "default")
    reservation_id: ID of the Blazar reservation to use for launching instances
