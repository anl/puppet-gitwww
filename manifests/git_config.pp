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
define gitwww::git_config($git_dir, $git_user) {

  $site = $name

  if $git_dir =~ /\/$/ {
    $git_dir_slash = $git_dir
  } else {
    $git_dir_slash = "${git_dir}/"
  }

  vcsrepo { "${git_dir_slash}${site}":
    ensure   => bare,
    provider => git,
    user     => $git_user,
    require  => File[$git_dir],
  }
}
