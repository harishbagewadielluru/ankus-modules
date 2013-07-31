# == Class: hadoop-hive
#
# This module installs and manages:
#   - hive: which is a data warehouse system for Hadoop
#   - hive-metastore: stores the metadata for Hive tables and partitions in a relational database,
#                     and provides clients (including Hive) access to this information via the
#                     metastore service API
#
# === Parameters
#
# None
#
# === Variables
#
# [*hbase_install*]
#   specifies whether to integrate hive and hbase
#   possible values -> enabled | disabled
#
# [*hadoop_controller*]
#   specifies the controller, host on which postgresql is running
#
# [*impala*]
#   specifies whether to integrate hive and impala
#   possible values -> enabled | disabled
#
# [*hbase_master*]
#   fqdn of hbase master if hbase is enabled
#
# [*hbase_zookeeper_quorum*]
#   zookeeper quorum (list of zookeeper servers used by hbase service)
#
# === Requires
#
# Java
# Hadoop
#
# === Sample Usage
#
# include hadoop-hive
#
# === Copyright
#
# Copyright 2012 Cloudwick Technologies, unless otherwise noted.
#

class hadoop-hive {
  include java
  require utilities::repo
  $hbase_deploy = hiera('hbase_deploy')
  $hadoop_controller = hiera('controller')
  $impala = hiera('impala', 'disabled')
	if ($hbase_deploy != "disabled"){
		$hbase_master = $hbase_deploy['hbase_master']
		$hbase_zookeeper_quorum = hiera('zookeeper_quorum')
	}
  $hive_packages = [ "hive", "hive-metastore" ]

  case $operatingsystem {
    'Ubuntu': {
      package { "hive":
        ensure => latest,
        require => [ File["java-app-dir"], Apt::Source['cloudera_precise'] ],
      }
      package { "hive-metastore":
        ensure => installed,
        require => Package['hive']
      }
    }
    'CentOS': {
      package { "hive":
        ensure => latest,
        require => [ File["java-app-dir"], Yumrepo["cloudera-repo"] ],
      }
      package { "hive-metastore":
        ensure => installed,
        require => Package['hive']
      }
    }
  }

  file { "/usr/lib/hive/lib/postgresql-8.4-703.jdbc3.jar":
    owner => "root",
    group => "root",
    source => "puppet:///modules/hadoop-hive/postgresql-8.4-703.jdbc3.jar",
    alias => "postgres-jdbc-jar",
    require => Package["hive"],
  }

  file { "/etc/hive/conf/hive-site.xml":
    content => template('hadoop-hive/hive-site.xml.erb'),
    require => Package["hive"],
    alias   => 'hive-conf',
    notify  => Service['hive-metastore'],
  }

  file { "/etc/hive/conf/hive-env.sh":
    content => template('hadoop-hive/hive-env.sh.erb'),
    require => Package['hive'],
    alias   => 'hive-env',
    notify  => Service['hive-metastore'],
  }

  service { "hive-metastore":
    enable => true,
    ensure => running,
    require => [ File['hive-conf'], File['hive-env'] ]
  }

  # if( $impala == "enabled" ) {
  #   #export hive-site.xml
  #   @@file { "/etc/impala/conf/hive-site.xml":
  #     ensure => present,
  #     content => template('hadoop-hive/hive-site.xml.erb'),
  #     tag => "hive-site-conf",
  #   }
  # }
}