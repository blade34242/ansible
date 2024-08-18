#!/bin/bash

# Role name
ROLE_NAME="deploy_docker_ipsecjobs"

# Create directory structure
mkdir -p $ROLE_NAME/{defaults,files,handlers,meta,tasks,templates}

# Create default variables file
cat <<EOL > $ROLE_NAME/defaults/main.yml
---
docker_compose_dir: "/root/apps/ipsecjobs"
allowed_ip: "144.2.101.158"
docker_compose_file: "docker-compose.yml"
EOL

# Create handlers file
cat <<EOL > $ROLE_NAME/handlers/main.yml
---
- name: Restart Docker Compose services
  community.docker.docker_compose:
    project_src: "{{ docker_compose_dir }}"
    state: restarted
EOL

# Create meta file
cat <<EOL > $ROLE_NAME/meta/main.yml
---
dependencies: []
EOL

# Create tasks file
cat <<EOL > $ROLE_NAME/tasks/main.yml
---
- name: Ensure Docker is installed
  ansible.builtin.package:
    name: docker.io
    state: present

- name: Deploy Docker Compose file
  ansible.builtin.template:
    src: docker-compose.yml.j2
    dest: "{{ docker_compose_dir }}/{{ docker_compose_file }}"

- name: Wait for Docker container to start
  ansible.builtin.pause:
    seconds: 10

- name: Get container IP address
  shell: "docker inspect -f '{{ '{{ .NetworkSettings.Networks.tool_network.IPAddress }}' }}' ipsecjobs"
  register: container_ip

- name: Debug container IP address
  ansible.builtin.debug:
    msg: "Container IP is {{ container_ip.stdout }}"

- name: Allow UFW 4500/udp traffic from IPHOME to the container
  ansible.builtin.ufw:
    rule: allow
    to_ip: "{{ container_ip.stdout }}"
    port: 4500
    proto: udp
    from_ip: "{{ allowed_ip }}"

- name: Allow UFW 500/udp traffic from IPHOME to the container
  ansible.builtin.ufw:
    rule: allow
    to_ip: "{{ container_ip.stdout }}"
    port: 500
    proto: udp
    from_ip: "{{ allowed_ip }}"
EOL

# Create Docker Compose template
cat <<EOL > $ROLE_NAME/templates/docker-compose.yml.j2
version: '3.8'

services:
  ipsecjobs:
    build: .
    container_name: ipsecjobs
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    volumes:
      - ./backup.sh:/usr/local/bin/backup.sh
      - /root/apps/backups:/backupsDone
      - /root/apps/backups:/backupsToDo:ro
      - ./fritzbox.conf:/etc/vpnc/fritzbox.conf
      - ./crontab:/etc/cron.d/backup-cron
      - ./ssh_keys:/root/.ssh
      - /var/log/ipsecjobs:/var/log
    environment:
      - TZ=Europe/Zurich
    command: /usr/local/bin/start.sh
    logging:
      driver: gelf
      options:
        gelf-address: "udp://172.21.0.88:1526"
        tag: "backup-job"
    networks:
      graylog_graylog_network:
      tool_network:

volumes:
  backup-data:

networks:
    graylog_graylog_network:
      external: true
    tool_network:
      driver: bridge
EOL

# Create README file
cat <<EOL > $ROLE_NAME/README.md
# Ansible Role: Deploy Docker IPSEC Jobs

This Ansible role deploys a Docker Compose setup for an IPSEC job service, retrieves the dynamic IP address of the container, and configures UFW rules to allow traffic from a specified IP address to the container.

## Requirements

- Docker and Docker Compose must be installed on the target system.
- Ansible Collection: \`community.docker\`

## Role Variables

- \`docker_compose_dir\`: Directory where the Docker Compose file will be deployed.
- \`allowed_ip\`: IP address to allow through UFW.
- \`docker_compose_file\`: Name of the Docker Compose file.

## Example Playbook

\`\`\`yaml
- hosts: servers
  become: true
  roles:
    - deploy_docker_ipsecjobs
      vars:
        docker_compose_dir: "/root/apps/ipsecjobs"
        allowed_ip: "144.2.101.158"
\`\`\`
EOL

# Done
echo "Ansible role structure for $ROLE_NAME has been created."

