# Copyright (c) The University of Chicago
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os
import sys
import hashlib

from urllib.parse import parse_qsl, unquote, urlencode
from dockerspawner import DockerSpawner
from jupyterhub.handlers import BaseHandler
from jupyterhub.utils import url_path_join
from tornado import web
from tornado.httputil import url_concat

c = get_config()

##################
# Logging
##################

c.Application.log_level = 'INFO'
c.JupyterHub.log_level = 'INFO'
c.Spawner.debug = False
c.DockerSpawner.debug = False

##################
# Base spawner
##################

# This is where we can do other specific bootstrapping for the user environment
def pre_spawn_hook(spawner):
    username = spawner.user.name
    # Run as authenticated user
    spawner.environment['NB_USER'] = username
    spawner.environment['OS_INTERFACE'] = 'public'
    spawner.environment['OS_KEYPAIR_PRIVATE_KEY'] = '/home/{}/.ssh/id_rsa'.format(username)
    spawner.environment['OS_KEYPAIR_PUBLIC_KEY'] = '/home/{}/.ssh/id_rsa.pub'.format(username)
    spawner.environment['OS_PROJECT_DOMAIN_NAME'] = 'default'
    spawner.environment['OS_REGION_NAME'] = 'CHI@UC'

origin = '*'
c.Spawner.args = ['--NotebookApp.allow_origin={0}'.format(origin)]
c.Spawner.pre_spawn_hook = pre_spawn_hook
c.Spawner.mem_limit = '2G'
c.Spawner.http_timeout = 600


##################
# Docker spawner
##################

# Set spawner names to work for multiple servers
c.DockerSpawner.name_template = '{prefix}-{username}'

# Spawn single-user servers as Docker containers wrapped by the option form
c.JupyterHub.spawner_class = DockerSpawner

# Spawn containers from this image
c.DockerSpawner.image = os.environ['DOCKER_NOTEBOOK_IMAGE']

# Connect containers to this Docker network
network_name = os.environ['DOCKER_NETWORK_NAME']
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.network_name = network_name

# Pass the network name as argument to spawned containers
c.DockerSpawner.extra_host_config = { 'network_mode': network_name }
notebook_dir = os.environ['DOCKER_NOTEBOOK_DIR']

# This directory will be symlinked to the `notebook_dir` at runtime.
c.DockerSpawner.notebook_dir = '~/work'

# Mount the real user's Docker volume on the host to the
# notebook directory in the container for that server
c.DockerSpawner.volumes = { '{prefix}-{username}': '/work' }

# Remove containers once they are stopped
c.DockerSpawner.remove_containers = True
c.DockerSpawner.extra_create_kwargs.update({
    # Need to launch the container as root in order to grant sudo access
    'user': 'root'
})

c.DockerSpawner.environment = {
    'CHOWN_EXTRA': notebook_dir,
    'CHOWN_EXTRA_OPTS': '-R',
    # Allow users to have sudo access within their container
    'GRANT_SUDO': 'yes',
    # Enable JupyterLab application
    'JUPYTER_ENABLE_LAB': 'yes',
}

c.DockerSpawner.cmd = ['start-notebook.sh']

##################
# Authentication
##################

# Authenticate users with Keystone
c.JupyterHub.authenticator_class = 'keystoneauthenticator.KeystoneAuthenticator'
c.KeystoneAuthenticator.auth_url = os.environ['OS_AUTH_URL']
# KeystoneAuthenticator uses auth_state to store Keystone token information
c.Authenticator.enable_auth_state = True
# Check state of authentication token before allowing a new server launch;
# The Keystone authenticator will fail if the user's unscoped token has expired,
# forcing them to log in, which is the right thing.
c.Authenticator.refresh_pre_spawn = True
# Automatically check the auth state this often. Not super useful for us, as
# there's nothing we can really do about this.
c.Authenticator.auth_refresh_age = 60 * 60
# Keystone tokens only last 7 days; limit sessions to this amount of time too.
c.JupyterHub.cookie_max_age_days = 7
