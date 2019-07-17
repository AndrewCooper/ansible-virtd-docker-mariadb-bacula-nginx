ansible-supportsite
===================

This repository contains ansible plays for the Support Site
-----------------------------------------------------------

To have the full functionality of the project clone this project with recursion enabled (`git clone --recursive repo`).

The `playbook_supportsite_basicsetup.yml` should be ran on the host support site machine with command '`ansible-playbook playbook`'.
This playbook is used to setup the basic on the support site server, but does not setup docker or any of it's needed files.

The `playbook_supportsite_setup.yml` is ran on the users system, with the command looking like '`ansible-playbook playbook_supportsite_setup.yml -i production --ask-sudo-pass`'.
The support site setup playbook will setup the docker containers for the support site and get needed files out of svn and git.
When the playbook is ran it will prompt the user for the sudo password of the base Support Site (CentOS).

The `playbook_convert.yml` is ran on the users system, with the command looking like '`ansible-playbook playbook_convert.yml -i production`'.
The convert playbook converted the old build system db and files to the new build system, and converted the old support site db and files to the support site.

The `playbook_replication_setup_repair.yml` is ran on the users system, with the command looking like '`ansible-playbook playbook_replication_setup_repair.yml -i production --ask-sudo-pass`'.
The replication playbook setups up the database replication with the build system as the master and the support site as the slave with ssl encryption.
When the playbook is ran it will prompt the user for the sudo password of the base Support Site (CentOS).

The `playbook_setup_testing_buildsystem.yml` is a playbook to setup a testing/development build system on a developers system.
To run the playbook their are optional tags of `prompts`, `svn_checkout`, `dump_live_system`, `git_docker_checkout`, `docker_build_image`, `import_sql` that can be skipped if not needed.
The running of the playbook should look like '`ansible-playbook playbook_setup_testing_buildsystem.yml --skip-tags=tag1,tag2 --ask-sudo-pass`'.
The playbook does have some requirements depending on the tags that may be skipped.
When the playbook is ran it will prompt the user for the sudo password of the local system.

The `playbook_setup_testing_supportsite.yml` is a playbook to setup a testing/development support site on a developers system.
To run the playbook their are optional tags of `prompts`, `svn_checkout`, `dump_live_system`, `git_docker_checkout`, `gen_ssl`, `docker_build_image`, `import_sql` that can be skipped if not needed.
The running of the playbook should look like '`ansible-playbook playbook_setup_testing_supportsite.yml --skip-tags=tag1,tag2 --ask-sudo-pass`'.
The playbook does have some requirements depending on the tags that may be skipped.
When the playbook is ran it will prompt the user for the sudo password of the local system.

On the system running the plays some setup with the '`~/.ssh/config`' file along with the correct keys may be needed.
Below is a general setup of a config file.

    host daedalus.novatech-llc.com
      HostName 172.16.0.100
      IdentityFile ~/.ssh/id_rsa_daedalus
      User ansibleremote

    host buildsystem.novatech-llc.com
      HostName 172.16.0.105
      IdentityFile ~/.ssh/id_rsa_buildsystem
      User ansibleremote

    host supportsite_current_production
      User deploy
      HostName 67.207.129.52
      Port 29322
      Identityfile ~/.ssh/ssdeploy

    host supportsite_server
      HostName 23.253.56.181
      Port 29322
      User deploy
      IdentityFile ~/.ssh/id_rsa_new_supportsite_deploy

    host supportsite_docker_container
      HostName 127.0.0.1
      Port 22
      User root
      Identityfile ~/.ssh/id_rsa_buildsystem
      StrictHostKeyChecking no
      UserKnownHostsFile=/dev/null
      ProxyCommand ssh -q supportsite_server nc %h %p

