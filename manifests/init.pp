class bigbluebutton (

    $user_name = 'bigbluebutton',
    $user_home = '/home/bigbluebutton',

    $public_ip = '172.16.42.230',

    ) {

    #create user bigbluebutton
    user { $user_name:
      home    => $user_home,
      ensure  => present,
    }

    # Install BigBlueButton
    class{"bigbluebutton::install_bbb": 
        public_ip => $public_ip,
    }

    # Install html5
    class{"bigbluebutton::install_html5": 
        user_name => $user_name,
        user_home => $user_home,
        public_ip => $public_ip,
    }

    # Install Metting
    class{"bigbluebutton::install_meeting": 
        user_name => $user_name,
        user_home => $user_home,
        public_ip => $public_ip,
    }


    # Restartando tudo do bigbluebutton
    exec { 'bbb-clean':
        command      => '/usr/bin/bbb-conf --clean',
    }

    # Starta html5
    exec { 'runserver-bbb-html5':
        command=> '/bin/bash start.sh &',
        cwd    => "${user_home}/dev/bigbluebutton-master/bigbluebutton-html5/app",
        path   => "\$PATH:${user_home}/.meteor"
        user   => $user_name,
        environment =>["HOME=${user_home}"],
    }

    file { $user_home:
        ensure => directory,
        owner    =>$user_name,
    }


    #create user bigbluebutton
    User[$user_name]->
    File[$user_home]->

    # Add Packages
    Class["bigbluebutton::install_bbb"] ->
    # Add Packages

    # Package environment DEV for HTML5
    Class["bigbluebutton::install_html5"] ->
    # Package environment DEV for HTML5

    #comandos deploy meeting
    Class["bigbluebutton::install_meeting"] ->
    #comandos deploy meeting

    # Finalizando configurações
    Exec["bbb-clean"] ->
    Exec["runserver-bbb-html5"]
 }