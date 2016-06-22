# clean firewall rules
resources { 'firewall':
   purge => true,
}

include ::firewall

# setup Apache
include ::apache

# setup "application"
validate_re($::db_name, '^.+$')
validate_re($::db_password, '^.+$')
validate_re($::db_username, '^.+$')
validate_ip_address($::db_ip_address)

include ::postgresql::client

file { '/var/www/cgi-bin/pgactivity':
  ensure  => file,
  require => Class['::apache'],
  mode    => '0755',
  content => "#!/bin/bash
echo 'Content-type: text/plain'
echo
PGPASSWORD='${::db_password}' psql -h ${::db_ip_address} -U ${::db_username} ${::db_name} -c 'select * from pg_stat_activity'
",
}

file { '/var/www/html/index.html':
  ensure  => file,
  require => File['/var/www/cgi-bin/pgactivity'],
  content => "
<html>
  <body>
    <h1>MyApplication</h1>
    <p>
      Running on host ${::fqdn} (IP: ${::ipaddress}). Configured by Cloudify and Puppet ${::puppetversion} when host had ${::uptime} uptime.
    </p>

    <h3>Database activity</h3>
    <iframe src='cgi-bin/pgactivity' width='100%' height='400'>
    </iframe>
  </body>
</html>
",
}
