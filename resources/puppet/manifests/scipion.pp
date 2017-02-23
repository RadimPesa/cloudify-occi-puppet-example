# clean firewall rules
resources { 'firewall':
  purge => true,
}

include ::firewall
include wget

############################################################
# Install Scipion prerequisities
package { ['mc','gcc-c++','glibc-headers','gcc','cmake']:
  ensure => present,
}
package { ['java-1.8.0-openjdk-devel.x86_64','libXft-devel.x86_64','openssl-devel.x86_64']:
  ensure => present,
}
package { ['libXext-devel.x86_64','libxml++.x86_64','libquadmath-devel.x86_64','libxslt.x86_64']:
  ensure => present,
}
package { ['openmpi-devel.x86_64','gsl-devel.x86_64','libX11.x86_64','gcc-gfortran.x86_64']:
  ensure => present,
}

############################################################
# Download binary version
wget::fetch { 'Download binary':
  source      => 'http://dior.ics.muni.cz/~cuda/scipion_web_bin.tgz',
  destination =>'/opt/',
  timeout     => 0,
  verbose     => false,
  before      => Exec['unpack_scipion'],
}

#############################################################
# Extract binary version
exec {'unpack_scipion':
  unless  => '/usr/bin/test -f /opt/scipion-web/scipion',
  cwd     => '/opt',
  command => 'tar xvzf /opt/scipion_web_bin.tgz',
  path    => '/bin/',
  before  => Exec['configure_o'],
}

##############################################################
# Configure Scipion --overwrite

exec {'configure_o':
  command => 'python /opt/scipion-web/scipion config --overwrite',
  path    => '/usr/bin/',
  before  => File_line['change mpi_libdir', 'change mpi_incdir','change mpi_bindir'],
}

##############################################################
#Change scipion.conf
file_line { 'change mpi_libdir':
  path  => '/opt/scipion-web/config/scipion.conf',
  line  => 'MPI_LIBDIR = /usr/lib64/openmpi/lib',
  match => '^MPI_LIBDIR',
}

file_line { 'change mpi_incdir':
  path  => '/opt/scipion-web/config/scipion.conf',
  line  => 'MPI_INCLUDE = /usr/include/openmpi-x86_64',
  match => '^MPI_INCLUDE',
}

file_line { 'change mpi_bindir':
  path   => '/opt/scipion-web/config/scipion.conf',
  line   => 'MPI_BINDIR = /usr/lib64/openmpi/bin',
  match  => '^MPI_BINDIR',
  before => Exec['configure'],
}

##############################################################
# Configure Scipion

exec {'configure':
  command => 'python /opt/scipion-web/scipion config 2> /tmp/sciconf.log',
  path    => '/usr/bin/',
  user    => 'cfy',
  environment => 'HOME=/home/cfy',
  before  => File['own_scipion'],
}

##############################################################
# Set owner and group

file { 'own_scipion':
  ensure  => directory,
  owner   => 'cfy',
  group   => 'cfy',
  path    => '/opt/scipion-web',
  recurse => true,
  before  => File['create_service'],
}

##############################################################
# Create directory /services

file { 'create_service':
  ensure  => directory,
  owner   => 'cfy',
  group   => 'cfy',
  path    => '/services',
  before  => File['delete_binary'],
}

##############################################################
# Delete binary tar file

file { 'delete_binary':
  ensure  => absent,
  path    => '/opt/scipion_web_bin.tgz',
#  before  => Exec['RWebserver'],
}

##############################################################
#run server

#exec {'RWebserver':
#  command     => 'python /opt/scipion-web/scipion webserver 2> /tmp/scipion.log',
#  path        => '/usr/bin/',
#  user        => 'cfy',
#  environment => 'HOME=/home/cfy',
#}
