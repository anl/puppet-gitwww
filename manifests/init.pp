# == Class: gitwww
#
# Push-to-deploy Git website infrastructure.
#
# === Parameters
#
# [*git_dir*]
#   Parent directory of bare git repos; default: /srv/git
#
# [*git_ssh_key*]
#   SSH public key for git user; default: false (no key will be installed).
#
# [*git_ssh_key_type*]
#   Key type for $git_ssh_key; default: ssh-rsa
#
# [*git_user*]
#   System user that will own git_dir and www_dir contents.  It is assumed
#   that this user will belong to a group with the same name as the username.
#   Default: git
#
# [*log_dir*]
#   Parent directory of site logs; default: /srv/logs
#
# [*server_module*]
#   Name of Puppet module configuring web server.  If set, orders gitwww module
#   before $server_module.  Default: false
#
# [*sites*]
#   Array of site names (FQDNs) that will be configured for
#   push-to-deploy.  Used in configuring directories and Git
#   repositories.  Default: [] (empty array)
#
# [*unmanaged_dir*]
#   Parent directory of site files not managed by git; it is assumed that
#   these will be linked into the site by symlinks or another mechanism
#   outside the control of this module.  Default: /srv/unmanaged
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
  $git_ssh_key = false,
  $git_ssh_key_type = 'ssh-rsa',
  $git_user = 'git',
  $log_dir = '/srv/logs',
  $server_module = false,
  $sites = [],
  $unmanaged_dir = '/srv/unmanaged',
  $www_dir = '/srv/www',
  $www_group = 'www-data',
  $www_user = 'www-data'
  ) {

  validate_absolute_path($git_dir)
  validate_absolute_path($unmanaged_dir)
  validate_absolute_path($www_dir)

  validate_re($git_ssh_key_type,[ 'ssh-dss', 'ssh-rsa', 'ecdsa-sha2-nistp256',
    'ecdsa-sha2-nistp384', 'ecdsa-sha2-nistp521' ])

  # Set up optional resource ordering - this class comes before server
  # software:
  if $server_module {
    Class['gitwww'] -> Class[$server_module]
  }

  if $log_dir =~ /\/$/ {
    $log_dir_slash = $log_dir
  } else {
    $log_dir_slash = "${log_dir}/"
  }

  if $unmanaged_dir =~ /\/$/ {
    $unmanaged_dir_slash = $unmanaged_dir
  } else {
    $unmanaged_dir_slash = "${unmanaged_dir}/"
  }

  if $www_dir =~ /\/$/ {
    $www_dir_slash = $www_dir
  } else {
    $www_dir_slash = "${www_dir}/"
  }

  ensure_packages(['git'])

  ensure_resource('user', $git_user, {
    'ensure'     => 'present',
    'comment'    => 'Git user',
    'managehome' => true,
    'shell'      => '/bin/bash', # can't be git-shell for vcsrepo to work
  } )

  if $git_ssh_key {
    # Security options on key ref.
    # http://joeyh.name/blog/entry/locking_down_ssh_authorized_keys/
    ssh_authorized_key { "${git_user} push-to-deploy key":
      ensure  => present,
      key     => $git_ssh_key,
      options => [ 'command="perl -e \'exec qw(/usr/bin/git-shell -c), $ENV{SSH_ORIGINAL_COMMAND}\'"',
  'no-port-forwarding', 'no-agent-forwarding', 'no-X11-forwarding', 'no-pty' ],
      type    => $git_ssh_key_type,
      user    => $git_user,
    }
  }

  file { [$git_dir, $log_dir, $unmanaged_dir, $www_dir]:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    require => User[$git_user],
  }

  gitwww::git_config { $sites:
    git_dir  => $git_dir,
    git_user => $git_user,
    www_dir  => $www_dir,
  }

  $log_sites = prefix($sites, $log_dir_slash)
  $unmanaged_sites = prefix($sites, $unmanaged_dir_slash)
  $root_dirs = flatten([$log_sites, $unmanaged_sites])

  file { $root_dirs:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => [ File[$log_dir], File[$unmanaged_dir] ],
  }

  $www_sites = prefix($sites, $www_dir_slash)

  file { $www_sites:
    ensure  => directory,
    owner   => $git_user,
    group   => $git_user,
    mode    => '0755',
    require => File[$www_dir],
  }
}
