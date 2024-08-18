# Ansible Role: Deploy Docker IPSEC Jobs

This Ansible role deploys a Docker Compose setup for an IPSEC job service, retrieves the dynamic IP address of the container, and configures UFW rules to allow traffic from a specified IP address to the container.

## Requirements

- Docker and Docker Compose must be installed on the target system.
- Ansible Collection: `community.docker`

## Role Variables

- `docker_compose_dir`: Directory where the Docker Compose file will be deployed.
- `allowed_ip`: IP address to allow through UFW.
- `docker_compose_file`: Name of the Docker Compose file.

## Example Playbook

```yaml
- hosts: servers
  become: true
  roles:
    - deploy_docker_ipsecjobs
      vars:
        docker_compose_dir: "/root/apps/ipsecjobs"
        allowed_ip: "144.2.101.158"
```
