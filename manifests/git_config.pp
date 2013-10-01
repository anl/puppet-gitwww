# == Define: gitwww::git_config
#
# Git-specific configuration for push-to-deploy websites.  When called, $name
# is expected to be the name (FQDN) of the website.
#
# === Parameters
#
# [*git_dir*]
#   Parent directory of bare git repos; assumed to already be created as a
#   "file" resource.  Default: /srv/git
#
# [*git_user*]
#   System user that will own git repo.
#
# === Examples
#
# gitwww::git_config { 'www.example.com':
#   git_dir  => '/srv/git',
#   git_user => 'git',
# }
#
# === Authors
#
# Andrew Leonard
#
# === Copyright
#
# Copyright 2013 Andrew Leonard
#
define gitwww::git_config($git_dir, $git_user, $www_dir) {

  $site = $name

  if $git_dir =~ /\/$/ {
    $git_dir_slash = $git_dir
  } else {
    $git_dir_slash = "${git_dir}/"
  }

  if $www_dir =~ /\/$/ {
    $www_dir_slash = $www_dir
  } else {
    $www_dir_slash = "${www_dir}/"
  }

  $site_dir = "${www_dir_slash}${site}"

  vcsrepo { "${git_dir_slash}${site}.git":
    ensure   => bare,
    provider => git,
    user     => $git_user,
    require  => File[$git_dir],
  }

  file { "${git_dir_slash}${site}.git/hooks/post-receive":
    owner   => $git_user,
    group   => $git_user,
    mode    => '0555',
    content => template('gitwww/post-receive.erb'),
    require => Vcsrepo["${git_dir_slash}${site}.git"],
  }
}
