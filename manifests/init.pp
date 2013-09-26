# == Class: gitwww
#
# Push-to-deploy website infrastructure.
#
# === Parameters
#
# [*git_dir*]
#   Parent directory of bare git repos; default: /srv/git
#
# [*git_user*]
#   System user that will own git_dir and www_dir contents.  It is assumed
#   that this user will belong to a group with the same name as the username.
#   Default: git
#
# [*unmanaged_dir*]
#   Parent directory of site files not managed by git; it is assumed that
#   these will be linked into the site by symlinks or another mechanism
#   outside the control of this module.  Default: /srv/unmanaged
#
# [*web_module*]
#   If set, require web_module before this one; default: false.
#
# [*www_dir*]
#   Parent directory of site document roots.  Default: /srv/www
#
# [*www_group*]
#   System group that web server software runs as; assumed to be created by
#   web server installation and not managed by this module - see $www_user.
#   Default: www-data
#
# [*www_user*]
#   System user that web server software runs as; will be given ownership of
#   directory trees under $unmanaged_dir.  Assumed to be created by web server
#   installation and not managed by this module.  Default: www-data
#
# === Examples
#
#  include gitwww
#
# === Authors
#
# Andrew Leonard
#
# === Copyright
#
# Copyright 2013 Andrew Leonard
#
class gitwww (
  $git_dir = '/srv/git',
  $git_user = 'git',
  $unmanaged_dir = '/srv/unmanaged',
  $web_module = false,
  $www_dir = '/srv/www',
  $www_group = 'www-data',
  $www_user = 'www-data'
  ) {

  if $web_module {
    Class[$web_module] -> Class['gitwww']
  }

  ensure_packages(['git'])

  ensure_resource('user', 'git', {
    'ensure'     => 'present',
    'comment'    => 'Git user',
    'managehome' => true,
    'shell'      => '/bin/false'
  } )

  file { [$git_dir, $www_dir]:
    ensure  => directory,
    owner   => $git_user,
    group   => $git_user,
    mode    => '0555',
    require => User[$git_user],
  }

  file { $unmanaged_dir:
    ensure => directory,
    owner  => $www_user,
    group  => $www_group,
    mode   => '0555',
  }
}
