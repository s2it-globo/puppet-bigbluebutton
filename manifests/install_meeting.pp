class bigbluebutton::install_meeting(

	$user_name = undef,
	$user_home = undef,
	$public_ip = undef,

	){

	$tools_dir = "${user_home}/dev/tools"

	#clonando a meeting da Globo
    exec { 'clone-meeting':
        command      => '/usr/bin/git clone https://github.com/s2it-globo/bigbluebutton-meeting.git',
        user=>$user_name,
        cwd => "${user_home}/dev/bigbluebutton-0.9.1",
        unless =>'/bin/ls |grep bigbluebutton-meeting',
        timeout=>1800,
    }
    #cria a pasta onde vão ficar os certificados para o SSL
    file { '/etc/nginx/ssl':
        ensure => directory,
    }
    #copia os certificados para a pasta do nginx
    exec { 'copy-cert-ssl':
        command      => '/bin/cp bigbluebutton.key /etc/nginx/ssl && /bin/cp bigbluebutton.crt /etc/nginx/ssl',
        cwd =>"${user_home}/dev/bigbluebutton-0.9.1/bigbluebutton-meeting/certs/",
    }
	#ajustando permissão nos certificados
    exec { 'define-permission-certs':
        command      => '/bin/chmod 0600 bigbluebutton.key bigbluebutton.crt',
        cwd =>'/etc/nginx/ssl/',
    }
    #gerando uma chave pem para uso do ssl
    exec { 'generate-key-pem':
        command      => '/usr/bin/openssl dhparam -out /etc/nginx/ssl/dhp-2048.pem 2048',
        cwd => '/etc/nginx/ssl',
        unless =>'/bin/ls |grep dhp-2048.pem',
        timeout=> 1800, 
    }
    #configura a porta 7443 no arquivo /opt/freeswitch/conf/sip_profiles/external.xml
    exec { 'configure-file-external-xml':
        command      => "/bin/sed -i '102i\\<param name=\"wss-binding\" value=\":7443\"/>' /opt/freeswitch/conf/sip_profiles/external.xml",
        unless => "/bin/cat /opt/freeswitch/conf/sip_profiles/external.xml |grep '<param name=\"wss-binding\" value=\":7443\"/>'",
    }
    #copy sip
    exec { 'copy-sip-nginx':
        command      => '/bin/cp sip.nginx /etc/bigbluebutton/nginx',
        cwd => "${user_home}/dev/bigbluebutton-0.9.1/bigbluebutton-meeting",
    }
    #ajusta a configuração do sip para https
    exec { 'configure-sip-nginx':
        command      => "/bin/sed -i \"s|http://10.0.2.15:5066|https://${public_ip}:7443|\" sip.nginx",
        cwd => '/etc/bigbluebutton/nginx',
    }

    #ajusta a configuração do arquivo bbb_webrtc
    exec { 'configure-webrtc-ssl':
        command      => '/bin/sed -i "s|ws://|wss://|" bbb_webrtc_bridge_sip.js',
        cwd =>'/var/www/bigbluebutton/client/lib',
        unless=> '/bin/cat bbb_webrtc_bridge_sip.js |grep wss://',
    }

    #ajusta confituração do arquivo bigbluebutton.properties
    exec { 'configure_bbb-properties':
        command      => "/bin/sed -i \"128s|bigbluebutton.web.serverURL=http://|bigbluebutton.web.serverURL=https://${public_ip}\\n#|\" bigbluebutton.properties",
        cwd => '/var/lib/tomcat7/webapps/bigbluebutton/WEB-INF/classes',
        unless=> '/bin/cat bbb_webrtc_bridge_sip.js |grep bigbluebutton.web.serverURL=https://',
    }

    exec { 'configure-config-xml':
        command      => "/bin/sed -i -r 's/(\\b[0-9]{1,3}\\.){3}[0-9]{1,3}\\b'/${public_ip}/ /var/www/bigbluebutton/client/conf/config.xml",
        cwd => '/var/www/bigbluebutton/client/lib/',
    }

    #adiciona https a chamada do bbb
    exec { 'configure-bbb-api-conf-https':
        command      => "/bin/sed -e 's|http://|https://|g' -i bbb_api_conf.jsp",
        cwd => "${user_home}/dev/bigbluebutton-0.9.1/bigbluebutton-meeting/src/main/webapp",
    }
    #inserindo a regra do meeting no nginx
    exec { 'add-meeting-role-nginx':
        command      => '/bin/cp meeting.nginx /etc/bigbluebutton/nginx/',
        cwd =>"${user_home}/dev/bigbluebutton-0.9.1/bigbluebutton-meeting",
    }

    # resources
    # exec { 'configure-salt-bbb-conf':   
    #     command      => "/bin/bash -c \"salt=\"\$(/usr/bin/bbb-conf --salt|grep Salt|cut -c13-44)\" && /bin/sed -i 's/bced839c079b4fe2543aefa73c7f6a57/\$salt/' bbb_api_conf.jsp\"",
    #     cwd          => "${user_home}/dev/bigbluebutton-0.9.1/bigbluebutton-meeting/src/main/webapp",
    # }

    exec { 'configure-salt-bbb-conf':   
        command      => "/bin/bash set_salt.sh",
        cwd          => "${user_home}/dev/bigbluebutton-0.9.1/bigbluebutton-meeting",
        environment =>["HOME=${user_home}"],
    }

    exec { 'configure-host-bbb-conf':
        command      => "/bin/sed -i \"s/172.16.42.29/${public_ip}/g\" bbb_api_conf.jsp",
        cwd          =>"${user_home}/dev/bigbluebutton-0.9.1/bigbluebutton-meeting/src/main/webapp",
    }



    #resolve as dependências do meeting
    exec { 'resolveDeps-meeting':
        command      => "${tools_dir}/gradle/bin/gradle resolveDeps",
        cwd => "${user_home}/dev/bigbluebutton-0.9.1/bigbluebutton-meeting",
        user => $user_name,
    }
    #compilando o meeting
    exec { 'build-meeting':
        command      => "${tools_dir}/gradle/bin/gradle build",
        cwd =>"${user_home}/dev/bigbluebutton-0.9.1/bigbluebutton-meeting",
        user => $user_name,
    }
    #remove possíveis meetings antigos
    exec { 'remove-meeting-deploy':
        command      => '/bin/rm -rf /var/lib/tomcat7/webapps/meeting*',
    }
    #compilando o meeting
    exec { 'copy-meeting-tomcat':
        command      => '/bin/cp build/libs/meeting.war /var/lib/tomcat7/webapps/',
        cwd =>"${user_home}/dev/bigbluebutton-0.9.1/bigbluebutton-meeting",
    }
    #habilita o meeting para ficar na raiz exemplo http://172.16.42.1
    exec { 'define-meeting-enter-point':
        command      => '/bin/cp bigbluebutton /etc/nginx/sites-available/',
        cwd =>"${user_home}/dev/bigbluebutton-0.9.1/bigbluebutton-meeting",
    }
    #alter ip of host in nginx
    exec { 'alter-servername-nginx':
        command      => "/bin/sed -i \"s/172.16.42.29/${public_ip}/g\" bigbluebutton",
        cwd => '/etc/nginx/sites-available',
    }

    #setando o IP na qual o BibBlueButton vai responder, nesse caso pegamos o IP da interface eth1
    exec { 'setip-bbb':
        command      => "/usr/bin/bbb-conf --setip ${public_ip}",
    }

     #gerando certificado java para SSL do bbb
    exec { 'generate-cert-java':
        command      => "/bin/echo | openssl s_client -connect ${public_ip}:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/certificate_x.pem",
    }
    #gerando certificado java para SSL do bbb
    # exec { 'import-cert-java':
    #     command      => "/usr/lib/jvm/java-7-openjdk-amd64/jre/bin/keytool -import -noprompt -alias root -keystore /etc/ssl/certs/java/cacerts -file /tmp/certificate_x.pem -storepass changeit",
    # }

     #restart tomcat7
    exec { 'restart-tomcat':
        command      => '/usr/bin/service tomcat7 restart',
    }


    Exec["clone-meeting"]->

    File["/etc/nginx/ssl"]->
    Exec["copy-cert-ssl"]->
    Exec["define-permission-certs"]->
    Exec["generate-key-pem"]->
    Exec["configure-file-external-xml"]->
    Exec["copy-sip-nginx"]->
    Exec["configure-sip-nginx"]->
    Exec["configure-webrtc-ssl"]->

    Exec["configure_bbb-properties"]->

    Exec["configure-config-xml"]->
    Exec["configure-bbb-api-conf-https"]->

    Exec["add-meeting-role-nginx"]->

    Exec["configure-salt-bbb-conf"]->
    Exec["configure-host-bbb-conf"]->

    Exec["resolveDeps-meeting"] ->
    Exec["build-meeting"] ->
    Exec["remove-meeting-deploy"]->
    Exec["copy-meeting-tomcat"] ->
    Exec["define-meeting-enter-point"]->
    Exec["alter-servername-nginx"]->

    Exec["setip-bbb"] ->

    Exec["generate-cert-java"]->
    # Exec["import-cert-java"]->

    Exec["restart-tomcat"]

}