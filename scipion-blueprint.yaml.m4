include(scipion-macros.m4)dnl
tosca_definitions_version: cloudify_dsl_1_2

description: >
  This is example Blueprint to show how to interact with FedCloud OCCI and Ansible.

imports:
  - http://getcloudify.org/spec/cloudify/3.3.1/types.yaml
  - http://getcloudify.org/spec/fabric-plugin/1.3.1/plugin.yaml
  - http://getcloudify.org/spec/diamond-plugin/1.3.1/plugin.yaml
  - https://raw.githubusercontent.com/vholer/cloudify-occi-plugin-experimental/master/plugin.yaml
  - https://raw.githubusercontent.com/RadimPesa/cloudify-ansible-plugin/master/plugin.yaml
  - types/puppet.yaml
  - types/server.yaml
  - types/webserver.yaml


inputs:
  # OCCI
  occi_endpoint:
    default: ''
    type: string
  occi_auth:
    default: ''
    type: string
  occi_username:
    default: ''
    type: string
  occi_password:
    default: ''
    type: string
  occi_user_cred:
    default: ''
    type: string
  occi_ca_path:
    default: ''
    type: string
  occi_voms:
    default: False
    type: boolean

  # contextualization
  cc_username:
    default: cfy
    type: string
  cc_public_key:
    type: string
  cc_private_key_filename:
    type: string
  cc_data:
    default: {}

  # VM parameters
  os_tpl:
    type: string
  resource_tpl:
    type: string
  os_availability_zone:
    type: string

dsl_definitions:
  occi_configuration: &occi_configuration
    endpoint: { get_input: occi_endpoint }
    auth: { get_input: occi_auth }
    username: { get_input: occi_username }
    password: { get_input: occi_password }
    user_cred: { get_input: occi_user_cred }
    ca_path: { get_input: occi_ca_path }
    voms: { get_input: occi_voms }

  cloud_configuration: &cloud_configuration
    username: { get_input: cc_username }
    public_key: { get_input: cc_public_key }
    data: { get_input: cc_data }

  fabric_env: &fabric_env
    user: { get_input: cc_username }
    key_filename: { get_input: cc_private_key_filename }

  agent_configuration: &agent_configuration
    install_method: remote
    user: { get_input: cc_username }
    key: { get_input: cc_private_key_filename }

node_templates:

  scipionNode:
    type: _NODE_SERVER_
    properties:
      name: 'Scipion server'
      resource_config:
        os_tpl: { get_input: os_tpl }
        resource_tpl: { get_input: resource_tpl }
        availability_zone: { get_input: os_availability_zone }
      agent_config: *agent_configuration
      cloud_config: *cloud_configuration
      occi_config: *occi_configuration
      fabric_env:
        <<: *fabric_env
        host_string: { get_attribute: [scipionNode, ip] } # req. by relationship ref.

  my_app:
    type: cloudify.nodes.ApplicationModule
    interfaces:
      cloudify.interfaces.lifecycle:
        configure:
          implementation: ansible.ansible_plugin.tasks.configure
          inputs:
            user: cfy
            key: resources/ssh/id_rsa
        start:
          implementation: ansible.ansible_plugin.tasks.ansible_playbook
          inputs:
            inventory:
              - { get_attribute: [ scipionNode, ip ] }
#              - hosts
#               - []
            playbooks:
              - resources/ansible/scipion.yaml
    relationships:
      - type: cloudify.relationships.contained_in
        target: scipionNode

outputs:
  endpoint:
    description: Web application endpoint
    value:
      url: { concat: ['http://', { get_attribute: [scipionNode, ip] }] }
