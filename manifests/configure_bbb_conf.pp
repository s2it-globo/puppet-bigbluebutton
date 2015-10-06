class bigbluebutton::configure_bbb_conf {
    # resources
    $salt = regsubst(generate("/bin/bash", "-c", "/usr/bin/bbb-conf --salt|grep Salt|cut -c13-44"),'\n', '')

    exec { 'configure-salt-bbb-conf':   
        command      => "/bin/sed -i 's/bced839c079b4fe2543aefa73c7f6a57/${salt}/' bbb_api_conf.jsp",   
        cwd          =>'/home/vagrant/dev/bigbluebutton-master/bigbluebutton-meeting/src/main/webapp',
    }

    exec { 'configure-host-bbb-conf':
        command      => '/bin/sed -i "s/172.16.42.29/172.16.42.231/g" bbb_api_conf.jsp',
        cwd          =>'/home/vagrant/dev/bigbluebutton-master/bigbluebutton-meeting/src/main/webapp',
    }


    notify{"msg":
        message=> "${salt}",
    }

    Exec["configure-salt-bbb-conf"]->
    Exec["configure-host-bbb-conf"]->
    Notify["msg"]
}