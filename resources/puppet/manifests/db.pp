if ($::cloudify_ctx_type == 'node-instance') {
  # clean firewall rules
  resources { 'firewall':
     purge => true,
  }

  include ::firewall

  # setup PostgreSQL and database
  include ::postgresql::server

  postgresql::server::db { hiera('mydb::name'):
    user     => hiera('mydb::user'),
    password => postgresql_password(hiera('mydb::user'), hiera('mydb::password')),
  }

} elsif ($::cloudify_ctx_type == 'relationship-instance') {
  ctx { 'db_ip_address':
    value => $::ipaddress,
    side  => 'source',
  }

  ctx { 'db_name':
    value => hiera('mydb::name'),
    side  => 'source',
  }

  ctx { 'db_username':
    value => hiera('mydb::user'),
    side  => 'source',
  }

  ctx { 'db_password':
    value => hiera('mydb::password'),
    side  => 'source',
  }

} else {
  fail('Standalone execution')
}
