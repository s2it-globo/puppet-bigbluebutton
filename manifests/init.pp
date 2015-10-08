class bigbluebutton (

    $user_name = 'bigbluebutton',
    $user_home = '/home/bigbluebutton',

    $public_ip = '172.16.42.230',

    $bbb_version="v0.9.1",

    $environment="globo",

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
        bbb_version=> $bbb_version,
        environment => $environment,
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
        command=> "${user_home}/.meteor/meteor &",
        cwd    => "${user_home}/dev/bigbluebutton/bigbluebutton-html5/app",
        environment =>["HOME=${user_home}", 'JASMINE_SERVER_UNIT=0', 'JASMINE_SERVER_INTEGRATION=0', 'JASMINE_CLIENT_INTEGRATION=0', 'JASMINE_BROWSER=PhantomJS', 'JASMINE_MIRROR_PORT=3000', 'ROOT_URL=http://127.0.0.1/html5client'],
    }

    #enable webrtc
    exec { 'enable-webrtc':
        command      => '/usr/bin/bbb-conf --enablewebrtc',
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
    Exec["enable-webrtc"]->
    Exec["bbb-clean"] ->
    Exec["runserver-bbb-html5"]
 }