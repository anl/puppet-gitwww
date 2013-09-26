# Include this module
include nginx

class { 'gitwww':
  web_module => 'nginx'
}
