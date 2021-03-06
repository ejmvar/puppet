class orautils::params {

  $osOracleHome = $::hostname ? { 
                                    xxxxxx     => "/data/wls",
                                    devagent1  => "/opt/oracle/wls",
                                    devagent10 => "/opt/oracle/wls",
                                    devagent30 => "/opt/oracle/wls",
                                    wls12      => "/oracle/product",
                                    default    => "/opt/wls", 
                                }

  $osDomainType = $::hostname ? {
                                    devagent30 => "web",
                                    devagent31 => "soa",
                                    wls12      => "admin",
                                    default    => "web", 
                                }


  $osDownloadFolder = $::hostname ? {
  	                                  devagent1  => "/data/install/oracle", 
                                      default    => "/data/install", 
                                     }

	$shell        = $::operatingsystem ? { Solaris => "!/usr/bin/ksh",
  															         default => "!/bin/sh",
  															       }   

  $osMdwHome     = $::hostname ?  { wls12    => "${osOracleHome}/Middleware12c",
                                    default  => "${osOracleHome}/Middleware11gR1",
                                  }   

  $osWlHome     = $::hostname ?  { wls12    => "${osOracleHome}/Middleware12c/wlserver",
                                   default  => "${osOracleHome}/Middleware11gR1/wlserver_10.3",
                                 }   

  $oraUser      = $::hostname ? { default => "oracle", }

  $userHome     = $::operatingsystem ? { Solaris => "/export/home",
  															         default => "/home", 
  															       }
  $oraInstHome  = $::operatingsystem ? { Solaris => "/var/opt",
  															         default => "/etc", 
  															       }

  $osDomain     = $::hostname ? {   wls12      => "Wls12c",
                                    default    => "osbSoaDomain", 
                                }
                                
  $osDomainPath = $::hostname ? { 
                                    default    => "${osMdwHome}/user_projects/domains/${osDomain}", 
                                }

  $nodeMgrPath = $::hostname ? { 
                                    wls12      => "${osMdwHome}/user_projects/domains/${osDomain}/bin", 
                                    default    => "${osMdwHome}/server/bin", 
                                }


  $nodeMgrPort = $::hostname ?  { 
                                    default    => "5556", 
                                }                                 

  $wlsUser     = $::hostname ?  { 
                                    default    => "weblogic", 
                                }                                 

  $wlsPassword = $::hostname ?  { 
                                    default    => "weblogic1", 
                                }       

  $wlsAdminServer = $::hostname ?  { 
                                    default    => "AdminServer", 
                                }       

}