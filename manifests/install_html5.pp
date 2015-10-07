class bigbluebutton::install_html5(

	$user_name     = undef,
	$user_home     = undef,
    $public_ip     = undef,
    $bbb_version   = undef,
    $environment   = undef,

	) {

	$env_java_home = '/usr/lib/jvm/java-7-openjdk-amd64'
    $env_grails_home = "/dev/tools/grails"
    $env_flex_home = "/dev/tools/flex"
    $env_gradle_home = "/dev/tools/gradle"
    $env_sbt_home = "/dev/tools/sbt"
    $env_apache_flex = "/dev/tools/apache-flex-sdk-4.13.0-bin/bin"
    $env_ant_opts = '-Xmx512m -XX:MaxPermSize=512m -XX:ReservedCodeCacheSize=1024m'
    $env_path = "\$PATH:${user_home}${env_grails_home}/bin:${user_home}${env_flex_home}/bin:${user_home}${env_gradle_home}/bin:${user_home}${env_sbt_home}/bin:${user_home}${env_apache_flex}/bin:"	

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
    #download grails
    exec { 'download-grails':
        command      => '/usr/bin/wget "http://dist.springframework.org.s3.amazonaws.com/release/GRAILS/grails-2.3.6.zip"',
        cwd => $tools_dir,
        user=>$user_name,
        unless => '/bin/ls |grep grails-2.3.6',
        timeout => 1800,
    }
    #descompacta grails
    exec { 'descompacta-grails':
        command      => '/usr/bin/unzip grails-2.3.6.zip && /bin/rm grails-2.3.6.zip',
        cwd => $tools_dir,
        user => $user_name,
        unless => '/usr/bin/find -type d |grep ./grails-2.3.6',
    }
    #cria link grails
    exec { 'cria-link-grails':
        command      => '/bin/ln -s grails-2.3.6 grails',
        cwd => $tools_dir,
        user =>$user_name,
        unless => '/usr/bin/find -type l |grep ./grails',
    }
    #download SBT
    exec { 'download-sbt':
        command      => '/usr/bin/wget "https://dl.bintray.com/sbt/native-packages/sbt/0.13.9/sbt-0.13.9.tgz"',
        cwd => $tools_dir,
        user=>$user_name,
        unless => '/usr/bin/find -type d |grep ./sbt',
        timeout => 1800,
    }

    #descompacta apache
    exec { 'descompacta-sbt':
        command      => '/bin/tar -xvzf sbt-0.13.9.tgz && /bin/rm sbt-0.13.9.tgz',
        cwd => $tools_dir,
        user => $user_name,
        unless => '/usr/bin/find -type d |grep ./sbt',
    }

    #download apache
    exec { 'download-apache':
        command      => '/usr/bin/wget "https://archive.apache.org/dist/flex/4.13.0/binaries/apache-flex-sdk-4.13.0-bin.tar.gz"',
        cwd => $tools_dir,
        user=>$user_name,
        unless => '/usr/bin/find -type d |grep ./apache-flex-sdk-4.13.0-bin',
        timeout => 1800,
    }

    #descompacta apache
    exec { 'descompacta-apache':
        command      => '/bin/tar -xvzf apache-flex-sdk-4.13.0-bin.tar.gz && /bin/rm apache-flex-sdk-4.13.0-bin.tar.gz',
        cwd => $tools_dir,
        user => $user_name,
        unless => '/usr/bin/find -type d |grep ./apache-flex-sdk-4.13.0-bin',
    }

    #criando a pasta in dentro de /var/www/dev/apache-flex-sdk-4.13.0-bin
    file { "${tools_dir}/apache-flex-sdk-4.13.0-bin/in":
        ensure => directory,
        owner=>$user_name,
    }

    #downfload fles
    exec { 'download-flex':
        command      => '/usr/bin/wget "http://download.macromedia.com/pub/flex/sdk/builds/flex4.6/flex_sdk_4.6.0.23201B.zip"',
        cwd => "${tools_dir}/apache-flex-sdk-4.13.0-bin/in",
        user=>$user_name,
        timeout => 1800,
        unless => '/bin/ls |grep flex_sdk_4.6.0.23201B.zip',
    }

    #resolve dependências apache
    exec { 'compila-apache':
        command      => '/bin/bash -c "\"yes\"|ant -f frameworks/build.xml thirdparty-downloads"',
        cwd => "${tools_dir}/apache-flex-sdk-4.13.0-bin",
        user=> $user_name,
    }

    #executa find 
    exec { 'find-apache':
        command      => '/usr/bin/find apache-flex-sdk-4.13.0-bin -type d -exec chmod o+rx "{}" \;',
        cwd => $tools_dir,
    }

    # atribui permissão 775 
    exec { 'permissao-775-apache':
        command      => '/bin/chmod 755 apache-flex-sdk-4.13.0-bin/bin/*',
        cwd => $tools_dir,
        user=>$user_name,
    }

    #chmod +r
    exec { 'chmod-r':
        command      => '/bin/chmod -R +r apache-flex-sdk-4.13.0-bin',
        cwd => $tools_dir,
    }

    # cria link flex
    exec { 'cria-link-flex':
        command      => '/bin/ln -s apache-flex-sdk-4.13.0-bin flex',
        cwd =>$tools_dir,
        user=>$user_name,
        unless => '/usr/bin/find -type l |grep ./flex',
    }
    #criando diretório 11.2 que vai conter o player
    file { "${tools_dir}/apache-flex-sdk-4.13.0-bin/frameworks/libs/player":
        ensure => directory,
        owner => $user_name,
    }
    file { "${tools_dir}/apache-flex-sdk-4.13.0-bin/frameworks/libs/player/11.2":
        ensure => directory,
        owner => $user_name,
    }

    #download player flash
    exec { 'download-flash':
        command      => '/usr/bin/wget "http://fpdownload.macromedia.com/get/flashplayer/installers/archive/playerglobal/playerglobal11_2.swc"',
        cwd => "${tools_dir}/apache-flex-sdk-4.13.0-bin/frameworks/libs/player/11.2",
        user=>$user_name,
        timeout => 1800,
        unless => '/bin/ls |grep playerglobal.swc',
    }

    #renomeia flash
    exec { 'renomeia-flash':
        command      => '/bin/mv -f playerglobal11_2.swc playerglobal.swc',
        cwd => "${tools_dir}/apache-flex-sdk-4.13.0-bin/frameworks/libs/player/11.2",
        user=>$user_name,
        unless => '/bin/ls |grep playerglobal.swc',
    }

    # #ajustando config.xml do flex
    exec { 'sed-config-xml-1':
        command      => '/bin/sed -i "s/11.1/11.2/g" frameworks/flex-config.xml',
        cwd => "${tools_dir}/apache-flex-sdk-4.13.0-bin",
    }

    exec { 'sed-config-xml-2':
        command      => '/bin/sed -i "s/<swf-version>14<\/swf-version>/<swf-version>15<\/swf-version>/g" frameworks/flex-config.xml',
        cwd => "${tools_dir}/apache-flex-sdk-4.13.0-bin",
    }

    exec { 'sed-config-xml-3':
        command      => '/bin/sed -i "s/{playerglobalHome}\/{targetPlayerMajorVersion}.{targetPlayerMinorVersion}/libs\/player\/11.2/g" frameworks/flex-config.xml',
        cwd => "${tools_dir}/apache-flex-sdk-4.13.0-bin",
    }

    if $environment == 'globo'{
        $url = "https://gitlab.globoi.com/time-evolucao-infra/bigbluebutton/repository/archive.zip?ref=${bbb_version}"
    }
    elsif $environment=='bigbluebutton' {
        $url = "https://codeload.github.com/bigbluebutton/bigbluebutton/zip/${bbb_version}"
    }

    #fazendo download do fonte do bigbluebutton
    exec { 'download-bigbluebutton':
        command      => "/usr/bin/wget ${url} -o v0.9.1.zip",
        cwd => "${user_home}/dev",
        user=>$user_name,
        unless => '/usr/bin/find -type d |grep ./bigbluebutton',
        timeout => 1800,
    }

    #descompacta bigbluebutton
    exec { 'descompacta-bigbluebutton':
        command      => "/usr/bin/unzip v0.9.1.zip && /bin/rm v0.9.1.zip && /bin/mv \"bigbluebutton\"\* bigbluebutton",
        cwd =>"${user_home}/dev",
        user=> $user_name,
        unless => '/usr/bin/find -type d |grep ./bigbluebutton',
    }

    #copia config.xml
    exec { 'copia-config-xml':
        command      => '/bin/cp bigbluebutton-client/resources/config.xml.template bigbluebutton-client/src/conf/config.xml',
        cwd =>"${user_home}/dev/bigbluebutton",
        user=>$user_name,
    }

    exec { 'set-head-xml':
        command      => '/usr/bin/head -n 10 bigbluebutton-client/src/conf/config.xml',
        cwd =>"${user_home}/dev/bigbluebutton",
        user=>$user_name,
    }

    # #configura config.xml
    exec { 'configura-config-xml':
        command      => "/bin/sed -i s/HOST/${public_ip}/g bigbluebutton-client/src/conf/config.xml",
        cwd =>"${user_home}/dev/bigbluebutton",
        user=>$user_name,
    }

    file { '/etc/bigbluebutton/nginx/client_dev':
        ensure => present,
        content=>"location /client/BigBlueButton.html {
                    root ${user_home}/dev/bigbluebutton/bigbluebutton-client;
                    index index.html index.htm;
                    expires 1m;
                }

                # BigBlueButton Flash client.
                location /client {
                    root ${user_home}/dev/bigbluebutton/bigbluebutton-client;
                    index index.html index.htm;
                }",
    }

    #ajusta link simbólico bbb
    exec { 'ajusta-link-simbolico-bbb-nginx':
        command      => '/bin/ln -f -s /etc/bigbluebutton/nginx/client_dev /etc/bigbluebutton/nginx/client.nginx',
    }

    #service { 'nginx':
    #    enable      => true,
    #    ensure      => running,
    #    hasrestart => true,
    #}

    exec { 'ant-locales':
        command      => "/usr/bin/ant locales",
        environment => ["JAVA_HOME=${env_java_home}", "GRAILS_HOME=${user_home}${env_grails_home}", "FLEX_HOME=${user_home}${env_flex_home}", "GRADLE_HOME=${user_home}${env_gradle_home}", "SBT_HOME=${user_home}${env_sbt_home}"],
        path => $env_path, 
        cwd =>"${user_home}/dev/bigbluebutton/bigbluebutton-client",
        user=>$user_name,
        timeout=>1800,
    }

    exec { "ant":
        environment => ["JAVA_HOME=${env_java_home}", "GRAILS_HOME=${user_home}${env_grails_home}", "FLEX_HOME=${user_home}${env_flex_home}", "GRADLE_HOME=${user_home}${env_gradle_home}", "SBT_HOME=${user_home}${env_sbt_home}", "ANT_OPTS=${env_ant_opts}"],
        path => $env_path, 
        command=> '/usr/bin/ant',
        cwd =>"${user_home}/dev/bigbluebutton/bigbluebutton-client",
        user=>$user_name,
        timeout=>1800,
        # unless => "/bin/bash -c \"[ -d client ] && echo 'client' || echo ''\"",
    }

    exec { 'downlaod-meteor':
        command      => '/usr/bin/curl https://install.meteor.com/ | sh',
        environment =>["HOME=${user_home}"],
        user=>$user_name,
        timeout=>1800,
        cwd => "${user_home}",
        unless =>'/usr/bin/which meteor |grep meteor',
    }

    exec { 'ajusta-config-xml-html5':

        command      => '/bin/sed -i "s/pngImagesRequired=false/pngImagesRequired=true/" bigbluebutton.properties' ,
        cwd =>'/var/lib/tomcat7/webapps/bigbluebutton/WEB-INF/classes',
    }

    file { '/etc/bigbluebutton/nginx/html5.nginx':
        ensure => present,
        content =>'location /html5client {
                  proxy_pass http://127.0.0.1:3000;
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection "Upgrade";
                }

                location /_timesync {
                  proxy_pass http://127.0.0.1:3000;
                }',
    }

    exec { 'sed-config-start-sh':
        command      => "/bin/sed -i 's/HOME=\/usr\/share\/meteor //' start.sh",
        cwd=> "${user_home}/dev/bigbluebutton/bigbluebutton-html5/app",
        user=>$user_name,
    }

    file { "${user_home}/.profile":
        ensure => present,
        content=>"
        if [ -n \"\$BASH_VERSION\" ]; then
        # include .bashrc if it exists
        if [ -f \"\$HOME/.bashrc\" ]; then
                . \"\$HOME/.bashrc\"
            fi
        fi
        if [ -d \"\$HOME/bin\" ] ; then
            PATH=\"\$HOME/bin:\$PATH\"
        fi      
        export GRAILS_HOME=\$HOME${env_grails_home}
        export FLEX_HOME=\$HOME${env_flex_home}
        export GRADLE_HOME=\$HOME${env_gradle_home}
        export SBT_HOME=\$HOME${env_sbt_home}
        export ANT_OPTS=\"${env_ant_opts}\"

        export PATH=\$PATH:\$GRAILS_HOME/bin:\$GRADLE_HOME/bin:\$SBT_HOME/bin:\$GRADLE_HOME/bin:\$FLEX_HOME/bin",
    }



    Exec["cria-pasta-dev-tools"]->
    Exec["download-gradle"]->
    Exec["descompacta-gradle"]->
    Exec["cria-link-gradle"]->

    Exec["download-grails"]->
    Exec["descompacta-grails"]->
    Exec["cria-link-grails"]->

    Exec["download-sbt"]->
    Exec["descompacta-sbt"]->

    Exec["download-apache"]->
    Exec["descompacta-apache"]->
    
    File["${tools_dir}/apache-flex-sdk-4.13.0-bin/in"]->
    Exec["download-flex"]->
    Exec["compila-apache"]->
    
    Exec["find-apache"]->
    Exec["permissao-775-apache"]->
    Exec["chmod-r"]->
    Exec["cria-link-flex"]->
    File["${tools_dir}/apache-flex-sdk-4.13.0-bin/frameworks/libs/player"]->
    File["${tools_dir}/apache-flex-sdk-4.13.0-bin/frameworks/libs/player/11.2"]->
    Exec["download-flash"]->
    Exec["renomeia-flash"]->

    Exec["sed-config-xml-1"]->
    Exec["sed-config-xml-2"]->
    Exec["sed-config-xml-3"]->

    Exec["download-bigbluebutton"]->
    Exec["descompacta-bigbluebutton"]->
    Exec["copia-config-xml"]->
    Exec["set-head-xml"]->
    Exec["configura-config-xml"]->
    File["/etc/bigbluebutton/nginx/client_dev"]->
    Exec["ajusta-link-simbolico-bbb-nginx"]->
    #Service["nginx"]->
    Exec["ant-locales"]->
    Exec["ant"]->

    Exec["downlaod-meteor"]->
    Exec["ajusta-config-xml-html5"]->
    File["/etc/bigbluebutton/nginx/html5.nginx"]->
    Exec["sed-config-start-sh"]->

    File["${user_home}/.profile"]

}