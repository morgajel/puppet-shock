define wordpress::app (
  $domain,
  $install_dir,
  $install_url,
  $version,
  $db_name,
  $db_host,
  $db_user,
  $db_password,
  $wp_owner,
  $wp_group,
) {
  validate_string($domain,$install_dir,$install_url,$version,$db_name,$db_host,$db_user,$db_password,$wp_owner,$wp_group)

  ## Resource defaults
  File {
    owner  => $wp_owner,
    group  => $wp_group,
    mode   => '0644',
  }
  Exec {
    path      => ['/bin','/sbin','/usr/bin','/usr/sbin'],
    cwd       => $install_dir,
    logoutput => 'on_failure',
    user      => $wp_owner,
    group     => $wp_group,
  }


  ## Installation directory
  file { $install_dir:
    ensure  => directory,
    recurse => true,
  }


  ## Download and extract
  exec { "$domain Download wordpress":
    command => "wget ${install_url}/wordpress-${version}.tar.gz",
    creates => "${install_dir}/wordpress-${version}.tar.gz",
    require => File[$install_dir],
  }
  -> exec { "$domain Extract wordpress":
    command => "tar zxvf ./wordpress-${version}.tar.gz --strip-components=1",
    creates => "${install_dir}/index.php",
  }

  ## Configure wordpress
  #
  # Template uses no variables
  file { "${domain} ${install_dir}/wp-keysalts.php":
    ensure  => present,
    path    => "${install_dir}/wp-keysalts.php",
    content => template('wordpress/wp-keysalts.php.erb'),
    replace => false,
    require => Exec["$domain Extract wordpress"],
  }
  concat { "${install_dir}/wp-config.php":
    owner   => $wp_owner,
    group   => $wp_group,
    mode    => '0755',
    require => Exec["$domain Extract wordpress"],
  }
  concat::fragment { "$domain wp-config.php keysalts":
    target  => "${install_dir}/wp-config.php",
    source  => "${install_dir}/wp-keysalts.php",
    order   => '10',
    require => File["$domain ${install_dir}/wp-keysalts.php"],
  }
  # Template uses: $db_name, $db_user, $db_password, $db_host
  concat::fragment { "$domain wp-config.php body":
    target  => "${install_dir}/wp-config.php",
    content => template('wordpress/wp-config.php.erb'),
    order   => '20',
  }
}
