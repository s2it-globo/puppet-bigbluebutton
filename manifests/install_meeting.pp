class bigbluebutton::install_meeting(

	$user_name = undef,
	$user_home = undef,
	$public_ip = undef,
    $enableMailAuth = undef,

	){

	$tools_dir = "${user_home}/dev/tools"

    #criando diretório de ferramentas de dev
    exec { 'cria-pasta-dev-tools':
        command      => "/bin/mkdir -p ${tools_dir}",
        user => $user_name,
    }

    #download gradle
    exec { 'download-gradle':
        command      => '/usr/bin/wget "http://services.gradle.org/distributions/gradle-1.10-bin.zip"',
        cwd => $tools_dir,
        user => $user_name,
        unless => '/bin/ls |grep gradle-1.10',
        timeout => 1800,
    }
    #descompacta gradle
    exec { 'descompacta-gradle':
        command      => '/usr/bin/unzip gradle-1.10-bin.zip && /bin/rm gradle-1.10-bin.zip',
        cwd => $tools_dir,
        user => $user_name,
        unless => '/usr/bin/find -type d |grep ./gradle-1.10',
    }
    #cria link gradle
    exec { 'cria-link-gradle':
        command      => '/bin/ln -s gradle-1.10 gradle',
        cwd => $tools_dir,
        user => $user_name,
        unless => '/usr/bin/find -type l |grep ./gradle',
    }

    exec { 'remove-meeting':
        command => "/bin/rm -fr ${user_home}/dev/bigbluebutton-meeting",
        user    => $user_name,
        unless  => "/bin/ls |grep ${user_home}/dev/bigbluebutton-meeting",
    }
	# Clone and pull repository bigbluebutton-meeting
    exec { 'clone-meeting':
        command => '/usr/bin/git clone https://github.com/s2it-globo/bigbluebutton-meeting.git',
        user    => $user_name,
        cwd     => "${user_home}/dev",
        unless  => '/bin/ls |grep bigbluebutton-meeting',
        timeout => 1800,
    }

    if $enableMailAuth == 'true'{
        exec { 'enableMailAuth':
            command      => "/bin/sed -i \"s|boolean enableMailAuth = false;|boolean enableMailAuth = true;|\" $user_home/dev/bigbluebutton-meeting/src/main/webapp/bbb_api_conf.jsp",
        } 
        exec { 'generate-cert-java-authapi':
            command => "/bin/echo | openssl s_client -connect authapi.globoi.com:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/certificate_y.pem",
            unless  => '/usr/lib/jvm/java-7-openjdk-amd64/jre/bin/keytool -list -keystore /etc/ssl/certs/java/cacerts -storepass changeit -keypass changeit |grep authapi'
        } 
        exec { 'import-cert-java-authapi':
             command => "/usr/lib/jvm/java-7-openjdk-amd64/jre/bin/keytool -import -noprompt -alias authapi -keystore /etc/ssl/certs/java/cacerts -file /tmp/certificate_x.pem -storepass changeit -keypass changeit",
             unless  => '/usr/lib/jvm/java-7-openjdk-amd64/jre/bin/keytool -list -keystore /etc/ssl/certs/java/cacerts -storepass changeit -keypass changeit |grep authapi'
        }
    }

    #cria a pasta onde vão ficar os certificados para o SSL
    file { '/etc/nginx/ssl':
        ensure => directory,
    }
    #copia os certificados para a pasta do nginx
    exec { 'copy-cert-ssl':
        command => '/bin/cp bigbluebutton.key /etc/nginx/ssl && /bin/cp bigbluebutton.crt /etc/nginx/ssl',
        cwd     =>"${user_home}/dev/bigbluebutton-meeting/certs/",
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
        command      => "/bin/cp ${user_home}/dev/bigbluebutton-meeting/sip.nginx /etc/bigbluebutton/nginx",
    }
    #ajusta a configuração do sip com o IP
    exec { 'configure-sip-nginx-ip':
        command      => "/bin/sed -i -e 's|HOST|${public_ip}|g' /etc/bigbluebutton/nginx/sip.nginx",
    }

    #ajusta a configuração do arquivo bbb_webrtc
    exec { 'configure-webrtc-ssl':
        command      => '/bin/sed -i "s|ws://|wss://|" /var/www/bigbluebutton/client/lib/bbb_webrtc_bridge_sip.js',
        unless=> '/bin/cat /var/www/bigbluebutton/client/lib/bbb_webrtc_bridge_sip.js |grep wss://',
    }

    #ajusta confituração do arquivo bigbluebutton.properties
    exec { 'configure_bbb-properties':
        command      => "/bin/sed -i \"128s|bigbluebutton.web.serverURL=http://|bigbluebutton.web.serverURL=https://${public_ip}\\n#|\" bigbluebutton.properties",
        cwd => '/var/lib/tomcat7/webapps/bigbluebutton/WEB-INF/classes',
        unless=> "/bin/cat bigbluebutton.properties |grep bigbluebutton.web.serverURL=https://${public_ip}",
    }

    exec { 'configure-config-xml':
         command      => "/bin/sed -e 's|http://|https://|g' -i /var/www/bigbluebutton/client/conf/config.xml",
    }

    # adiciona https a chamada do bbb
    exec { 'configure-meeting-https':
        command      => "/bin/sed -e 's|http://|https://|g' -i ${user_home}/dev/bigbluebutton-meeting/src/main/webapp/bbb_api_conf.jsp",
    }
    exec { 'configure-meeting-ip':
        command      => "/bin/sed -i -r 's/(\\b[0-9]{1,3}\\.){3}[0-9]{1,3}\\b'/${public_ip}/ ${user_home}/dev/bigbluebutton-meeting/src/main/webapp/bbb_api_conf.jsp",
    }
    exec { 'configure-salt-bbb-conf':   
        command      => "/bin/bash set-salt.sh",
        cwd          => "${user_home}/dev/bigbluebutton-meeting",
        environment =>["HOME=${user_home}"],
    }

    #inserindo a regra do meeting no nginx
    exec { 'add-meeting-role-nginx':
        command      => '/bin/cp meeting.nginx /etc/bigbluebutton/nginx/',
        cwd =>"${user_home}/dev/bigbluebutton-meeting",
    }

    #resolve as dependências do meeting
    exec { 'resolveDeps-meeting':
        command      => "${tools_dir}/gradle/bin/gradle resolveDeps",
        cwd => "${user_home}/dev/bigbluebutton-meeting",
        user => $user_name,
    }
    #compilando o meeting
    exec { 'build-meeting':
        command      => "${tools_dir}/gradle/bin/gradle build",
        cwd =>"${user_home}/dev/bigbluebutton-meeting",
        user => $user_name,
    }
    #remove possíveis meetings antigos
    exec { 'remove-meeting-deploy':
        command      => '/bin/rm -rf /var/lib/tomcat7/webapps/meeting*',
    }
    #compilando o meeting
    exec { 'copy-meeting-tomcat':
        command      => '/bin/cp build/libs/meeting.war /var/lib/tomcat7/webapps/',
        cwd =>"${user_home}/dev/bigbluebutton-meeting",
    }
    #habilita o meeting para ficar na raiz exemplo http://172.16.42.1
    exec { 'define-meeting-enter-point':
        command      => '/bin/cp bigbluebutton /etc/nginx/sites-available/',
        cwd =>"${user_home}/dev/bigbluebutton-meeting",
    }
    #alter ip of host in nginx
    exec { 'alter-servername-nginx':
        command      => "/bin/sed -i \"s/172.16.42.29/${public_ip}/g\" bigbluebutton",
        cwd => '/etc/nginx/sites-available',
    }

    #enable webrtc
    exec { 'enable-webrtc':
        command      => '/usr/bin/bbb-conf --enablewebrtc',
    }

    #setando o IP na qual o BibBlueButton vai responder, nesse caso pegamos o IP da interface eth1
    exec { 'setip-bbb':
        command  => "/usr/bin/bbb-conf --setip ${public_ip}",
        #unless   => "/usr/bin/curl -i -X GET --fail 'http://${public_ip}/'",
        timeout  => 1800,
    }
    exec { 'bbb-restart':
        command      => '/usr/bin/bbb-conf --restart',
        timeout  => 1800,
    }

     #gerando certificado java para SSL do bbb
    exec { 'generate-cert-java':
        command => "/bin/echo | openssl s_client -connect ${public_ip}:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/certificate_x.pem",
        unless  => '/usr/lib/jvm/java-7-openjdk-amd64/jre/bin/keytool -list -keystore /etc/ssl/certs/java/cacerts -storepass changeit -keypass changeit |grep bigbluebutton'
    }
    exec { 'import-cert-java':
         command => "/usr/lib/jvm/java-7-openjdk-amd64/jre/bin/keytool -import -noprompt -alias bigbluebutton -keystore /etc/ssl/certs/java/cacerts -file /tmp/certificate_x.pem -storepass changeit -keypass changeit",
         unless  => '/usr/lib/jvm/java-7-openjdk-amd64/jre/bin/keytool -list -keystore /etc/ssl/certs/java/cacerts -storepass changeit -keypass changeit |grep bigbluebutton'
    }
    #gerando certificado java para SSL do bbb

    #Restartando tudo do bigbluebutton
    exec { 'bbb-clean':
        command      => '/usr/bin/bbb-conf --clean',
        timeout  => 1800,
    }

    Exec["cria-pasta-dev-tools"] ->
    Exec["download-gradle"] ->
    Exec["descompacta-gradle"] ->
    Exec["cria-link-gradle"] ->

    Exec["remove-meeting"]->
    Exec["clone-meeting"]->

    File["/etc/nginx/ssl"]->
    Exec["copy-cert-ssl"]->
    Exec["define-permission-certs"]->
    Exec["generate-key-pem"]->
    Exec["configure-file-external-xml"]->
    Exec["copy-sip-nginx"]->
    Exec["configure-sip-nginx-ip"]->
    Exec["configure-webrtc-ssl"]->

    Exec["configure_bbb-properties"]->

    Exec["configure-config-xml"]->

    Exec["configure-meeting-https"]->
    Exec["configure-meeting-ip"]->
    Exec["configure-salt-bbb-conf"]->

    Exec["add-meeting-role-nginx"]->

    Exec["resolveDeps-meeting"] ->
    Exec["build-meeting"] ->
    Exec["remove-meeting-deploy"]->
    Exec["copy-meeting-tomcat"] ->
    Exec["define-meeting-enter-point"]->
    Exec["alter-servername-nginx"]->

    Exec["enable-webrtc"]->
    Exec["setip-bbb"] ->
    Exec["bbb-restart"] ->


    Exec["generate-cert-java"]->
    Exec["import-cert-java"] ->

    Exec["bbb-clean"]
}