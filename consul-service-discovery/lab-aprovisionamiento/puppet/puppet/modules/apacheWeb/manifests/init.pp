class apacheWeb {
  package { 'apache2':
    ensure => present,
  }

  service { 'apache2':
    ensure => running,
    enable => true,
    require => Package['apache2'],
  }

  file { '/var/www/html/index.html':
    ensure => present,
    content => template('apacheWeb/index.html.erb'),
    require => Package['apache2'],
  }
}
