# Include this module
include nginx

class { 'gitwww':
  sites      => [ 'www.example.com' ],
  web_module => 'nginx'
}
