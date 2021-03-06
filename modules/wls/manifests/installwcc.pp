# == Define: wls::installwcc
#
# installs Oracle Webcenter content addon   
#
# === Examples
#
#    $jdkWls11gJDK = 'jdk1.7.0_09'
#    $wls11gVersion = "1036"
#
#  case $operatingsystem {
#     CentOS, RedHat, OracleLinux, Ubuntu, Debian: { 
#       $osMdwHome    = "/opt/wls/Middleware11gR1"
#       $osWlHome     = "/opt/wls/Middleware11gR1/wlserver_10.3"
#       $oracleHome   = "/opt/wls/"
#       $user         = "oracle"
#       $group        = "dba"
#     }
#     windows: { 
#       $osMdwHome    = "c:/oracle/wls11g"
#       $osWlHome     = "c:/oracle/wls11g/wlserver_10.3"
#       $user         = "Administrator"
#       $group        = "Administrators"
#     }
#  }
#
#
#  Wls::Installwcc {
#    mdwHome      => $osMdwHome,
#    wlHome       => $osWlHome,
#    fullJDKName  => $jdkWls11gJDK, 
#    user         => $user,
#    group        => $group,    
#  }
#  
#
#  wls::installwcc{'wccPS6':
#    wccFile1      => 'ofm_wcc_generic_11.1.1.7.0_disk1_1of2.zip',
#    wccFile2      => 'ofm_wcc_generic_11.1.1.6.0_disk1_2of2.zip',
#  }
#
## 


define wls::installwcc($mdwHome         = undef,
                       $wlHome          = undef,
                       $oracleHome      = undef,
                       $fullJDKName     = undef,
                       $wccFile1        = undef,
                       $wccFile2        = undef,
                       $user            = 'oracle',
                       $group           = 'dba',
                       $downloadDir     = '/install',
                       $puppetDownloadMntPoint  = undef,  
                    ) {

   case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: { 

        $execPath        = "/usr/java/${fullJDKName}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $path            = $downloadDir
        $wccOracleHome   = "${mdwHome}/Oracle_WCC1"
        $oraInventory    = "${oracleHome}/oraInventory"
        
        $wccInstallDir   = "linux64"
        $jreLocDir       = "/usr/java/${fullJDKName}"
        
        Exec { path      => $execPath,
               user      => $user,
               group     => $group,
               logoutput => true,
             }
        File {
               ensure  => present,
               mode    => 0775,
               owner   => $user,
               group   => $group,
             }        
     }
     Solaris: { 

        $execPath        = "/usr/jdk/${fullJDKName}/bin/amd64:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $path            = $downloadDir
        $wccOracleHome   = "${mdwHome}/Oracle_WCC1"
        $oraInventory    = "${oracleHome}/oraInventory"

        $wccInstallDir   = "intelsolaris"
        $jreLocDir       = "/usr/jdk/${fullJDKName}"
                
        Exec { path      => $execPath,
               user      => $user,
               group     => $group,
               logoutput => true,
             }
        File {
               ensure  => present,
               mode    => 0775,
               owner   => $user,
               group   => $group,
             }        
     }
     windows: { 

        $execPath         = "C:\\oracle\\${fullJDKName}\\bin;C:\\unxutils\\bin;C:\\unxutils\\usr\\local\\wbin;C:\\Windows\\system32;C:\\Windows"
        $checkCommand     = "C:\\Windows\\System32\\cmd.exe /c" 
        $path             = $downloadDir 
        $wccOracleHome    = "${mdwHome}/Oracle_WCC1"
        
        Exec { path      => $execPath,
             }
        File { ensure  => present,
               mode    => 0777,
             }   
     }
   }

     # check if the wcc already exists
     $found = oracle_exists( $wccOracleHome )
     if $found == undef {
       $continue = true
     } else {
       if ( $found ) {
         notify {"wls::installwcc ${title} ${wccOracleHome} already exists":}
         $continue = false
       } else {
         notify {"wls::installwcc ${title} ${wccOracleHome} does not exists":}
         $continue = true 
       }
     }

if ( $continue ) {

   if $puppetDownloadMntPoint == undef {
     $mountPoint =  "puppet:///modules/wls/"      
   } else {
     $mountPoint =  $puppetDownloadMntPoint
   }

   wls::utils::orainst{'create wcc oraInst':
            oraInventory    => $oraInventory, 
            group           => $group,
   }

   $wccTemplate =  "wls/silent_wcc.xml.erb"

#   if ! defined(File["${path}/${title}silent_wcc.xml"]) {
     file { "${path}/${title}silent_wcc.xml":
       ensure  => present,
       content => template($wccTemplate),
       require => Wls::Utils::Orainst ['create wcc oraInst'],
     }
#   }

   # wcc file 1 installer zip
   if ! defined(File["${path}/${wccFile1}"]) {
    file { "${path}/${wccFile1}":
     source  => "${mountPoint}/${wccFile1}",
     require => File ["${path}/${title}silent_wcc.xml"],
    }
   }

   # wcc file 2 installer zip
   if ! defined(File["${path}/${wccFile2}"]) {
    file { "${path}/${wccFile2}":
     source  => "${mountPoint}/${wccFile2}",
     require => [File ["${path}/${title}silent_wcc.xml"],File["${path}/${wccFile1}"]],
    }
   }


   
   $command  = "-silent -response ${path}/${title}silent_wcc.xml "
    
   case $operatingsystem {
     CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: { 

        if ! defined(Exec["extract ${wccFile1}"]) {
         exec { "extract ${wccFile1}":
          command => "unzip -o ${path}/${wccFile1} -d ${path}/wcc",
          creates => "${path}/wcc/Disk1",
          require => [File ["${path}/${wccFile2}"],File ["${path}/${wccFile1}"]],
         }
        }

        if ! defined(Exec["extract ${wccFile2}"]) {
         exec { "extract ${wccFile2}":
          command => "unzip -o ${path}/${wccFile2} -d ${path}/wcc",
          creates => "${path}/wcc/Disk2",
          require => [File ["${path}/${wccFile2}"],Exec["extract ${wccFile1}"]],
         }
        }

        
        exec { "install wcc ${title}":
          command     => "${path}/wcc/Disk1/install/${wccInstallDir}/runInstaller ${command} -invPtrLoc /etc/oraInst.loc -ignoreSysPrereqs -jreLoc ${jreLocDir}",
          require     => [File["${path}/${title}silent_wcc.xml"],Exec["extract ${wccFile1}"],Exec["extract ${wccFile2}"]],
          creates     => $wccOracleHome,
          environment => ["CONFIG_JVM_ARGS=-Djava.security.egd=file:/dev/./urandom"],
        }    

        exec { "sleep 4 min for wcc install ${title}":
          command     => "/bin/sleep 240",
          require     => Exec ["install wcc ${title}"],
        }    

             
     }
     Solaris: { 

        if ! defined(Exec["extract ${wccFile1}"]) {
         exec { "extract ${wccFile1}":
          command => "unzip ${path}/${wccFile1} -d ${path}/wcc",
          creates => "${path}/wcc/Disk1",
          require => [File ["${path}/${wccFile2}"],File ["${path}/${wccFile1}"]],
         }
        }

        if ! defined(Exec["extract ${wccFile2}"]) {
         exec { "extract ${wccFile2}":
          command => "unzip -o ${path}/${wccFile2} -d ${path}/wcc",
          creates => "${path}/wcc/Disk2",
          require => [File ["${path}/${wccFile2}"],Exec["extract ${wccFile1}"]],
         }
        }

        exec { "add -d64 oraparam.ini wcc":
          command => "sed -e's/JRE_MEMORY_OPTIONS=\" -Xverify:none\"/JRE_MEMORY_OPTIONS=\"-d64 -Xverify:none\"/g' ${path}/wcc/Disk1/install/${wccInstallDir}/oraparam.ini > /tmp/wcc.tmp && mv /tmp/wcc.tmp ${path}/wcc/Disk1/install/${wccInstallDir}/oraparam.ini",
          require => [Exec["extract ${wccFile1}"],Exec["extract ${wccFile2}"]],
        }

        exec { "install wcc ${title}":
          command     => "${path}/wcc/Disk1/install/${wccInstallDir}/runInstaller ${command} -invPtrLoc /var/opt/oraInst.loc -ignoreSysPrereqs -jreLoc ${jreLocDir}",
          require     => [File["${path}/${title}silent_wcc.xml"],Exec["extract ${wccFile1}"],Exec["extract ${wccFile2}"],Exec["add -d64 oraparam.ini wcc"]],
          creates     => $wccOracleHome,
        }    

        exec { "sleep 4 min for wcc install ${title}":
          command     => "/bin/sleep 240",
          require     => Exec ["install wcc ${title}"],
        }    

             
     }

     windows: { 


        if ! defined(Exec["extract ${wccFile1}"]) {
         exec { "extract ${wccFile1}":
          command => "${checkCommand} unzip ${path}/${wccFile1} -d ${path}/wcc",
          require => [Registry_Value ["HKEY_LOCAL_MACHINE\\SOFTWARE\\Oracle\\inst_loc"],File ["${path}/${wccFile1}"]],
          creates => "${path}/wcc/Disk1",
         }
        }

        if ! defined(Exec["extract ${wccFile2}"]) {
         exec { "extract ${wccFile2}":
          command => "${checkCommand} unzip -o ${path}/${wccFile2} -d ${path}/wcc",
          require => [Exec["extract ${wccFile1}"],File ["${path}/${wccFile2}"]],
          creates => "${path}/wcc/Disk2",
         }
        }


        exec {"icacls wcc disk ${title}": 
           command    => "${checkCommand} icacls ${path}\\wcc\\* /T /C /grant Administrator:F Administrators:F",
           logoutput  => false,
           require    => [Exec["extract ${wccFile2}"],Exec["extract ${wccFile1}"]],
        } 

        exec { "install wcc ${title}":
          command     => "${path}\\wcc\\Disk1\\setup.exe ${command} -ignoreSysPrereqs -jreLoc C:\\oracle\\${fullJDKName}",
          logoutput   => true,
          require     => [Exec["icacls wcc disk ${title}"],File["${path}/${title}silent_wcc.xml"],Exec["extract ${wccFile2}"],Exec["extract ${wccFile1}"]],
          creates     => $wccOracleHome, 
        }    

        exec { "sleep 4 min for wcc install ${title}":
          command     => "${checkCommand} sleep 240",
          require     => Exec ["install wcc ${title}"],
        }    


     }
   }
}
}
