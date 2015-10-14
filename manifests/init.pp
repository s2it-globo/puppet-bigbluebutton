class bigbluebutton (

    $user_name = 'bigbluebutton',
    $user_home = '/home/bigbluebutton',

    $public_ip = '172.16.42.230',
    $enableAuthentication = 'true',

    ) {

    #create user bigbluebutton
    user { $user_name:
      home    => $user_home,
      ensure  => present,
    }
    file { $user_home:
        ensure => directory,
        owner    =>$user_name,
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
        enableAuthentication => $enableAuthentication,
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
    Class["bigbluebutton::install_meeting"]
    #comandos deploy meeting
 }