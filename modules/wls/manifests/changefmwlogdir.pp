# == Define: wls::changefmwlogdir
#
# generic changefmwlogdir wlst script, runs the WLST command from the oracle common home  
# Moves the fmw log files like  AdminServer-diagnostic.log or AdminServer-owsm.log
# to a different location outside your domain
#
# pass on the weblogic username or password
# or provide userConfigFile and userKeyFile file locations
#  
# === Examples
#  
#  # set the defaults
#
#  Wls::Changefmwlogdir {
#    mdwHome      => $osMdwHome,
#    user         => 'oracle',
#    group        => 'dba',    
#  }
#
#  wls::changefmwlogdir{
#   'adminServer':
#    address      => "localhost",
#    wlsUser      => "weblogic",
#    password     => "weblogic1",
#    port         => "7001",
#    wlsServer    => "AdminServer",
#    logDir       => "/data/logs",
#    downloadDir  => "/install/",
#  }
#
#
# 

define wls::changefmwlogdir ($mdwHome        = undef, 
                             $address        = "localhost",
                             $port           = '7001',
                             $wlsUser        = undef,
                             $password       = undef,
                             $userConfigFile = undef,
                             $userKeyFile    = undef,
                             $user           = 'oracle', 
                             $group          = 'dba',
                             $wlsServer      = undef,
                             $logDir         = undef,
                             $downloadDir    = '/install/',
                            ) {


   case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES, Solaris: { 

        $execPath         = "/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $path             = $downloadDir

        Exec { path      => $execPath,
               user      => $user,
               group     => $group,
               logoutput => true,
             }
        File {
               ensure  => present,
               replace => 'yes',
               mode    => 0555,
               owner   => $user,
               group   => $group,
             }     
     }
     windows: { 

        $execPath         = "C:\\unxutils\\bin;C:\\unxutils\\usr\\local\\wbin;C:\\Windows\\system32;C:\\Windows"
        $path             = $downloadDir 


        Exec { path      => $execPath,
               logoutput => true,
             }
        File { ensure  => present,
               replace => 'yes',
               mode    => 0777,
             }     
     }
   }

   # use userConfigStore for the connect
	 if $password == undef {
     $useStoreConfig = true  
   } else {	
     $useStoreConfig = false  
   }
   
   # the py script used by the wlst
   file { "${path}/${title}changeFMWLogFolder.py":
      path    => "${path}/${title}changeFMWLogFolder.py",
      content => template("wls/wlst/changeFMWLogFolder.py.erb"),
   }
     
   case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: { 

        exec { "execwlst ${title}changeFMWLogFolder.py":
          command     => "${mdwHome}/oracle_common/common/bin/wlst.sh ${path}/${title}changeFMWLogFolder.py",
          environment => ["CONFIG_JVM_ARGS=-Djava.security.egd=file:/dev/./urandom"],
          unless      => "ls -l ${logDir}/${wlsServer}-diagnostic.log",
          require     => File["${path}/${title}changeFMWLogFolder.py"],
        }    

        case $operatingsystem {
           CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: { 

            exec { "rm ${path}/${title}changeFMWLogFolder.py":
              command => "rm -I ${path}/${title}changeFMWLogFolder.py",
              require => Exec["execwlst ${title}changeFMWLogFolder.py"],
            }
           }
           Solaris: { 

            exec { "rm ${path}/${title}changeFMWLogFolder.py":
              command => "rm ${path}/${title}changeFMWLogFolder.py",
              require => Exec["execwlst ${title}changeFMWLogFolder.py"],
            }
           }
        }     




     }
     windows: { 

        exec { "execwlst ${title}changeFMWLogFolder.py":
          command     => "C:\\Windows\\System32\\cmd.exe /c ${mdwHome}/oracle_common/common/bin/wlst.cmd ${path}/${title}changeFMWLogFolder.py",
          unless      => "C:\\Windows\\System32\\cmd.exe /c dir ${logDir}/${wlsServer}-diagnostic.log",
          require     => File["${path}/${title}changeFMWLogFolder.py"],
        }    


        exec { "rm ${path}/${title}changeFMWLogFolder.py":
           command => "C:\\Windows\\System32\\cmd.exe /c rm ${path}/${title}changeFMWLogFolder.py",
           require => Exec["execwlst ${title}changeFMWLogFolder.py"],
        }
     }
   }



}

