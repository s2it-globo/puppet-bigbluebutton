class bigbluebutton::install_bbb (

    $public_ip = undef,

    ) {


    #liberando as portas tcp no firewall
    exec { 'ufw-allow-ports-tcp':
        command      => '/bin/echo allow proto tcp from any to any port 80,1935,9123',
    }

    #liberando as portas udp no firewall
    exec { 'ufw-allow-ports-udp':
        command      => '/bin/echo allow proto udp from any to any port 16384,32768',
    }

	#adicionando multiverse ao source_list
    exec { 'add-multiverse':
        command      => '/bin/echo "deb http://us.archive.ubuntu.com/ubuntu/ trusty multiverse" | sudo tee -a /etc/apt/sources.list',
        unless => '/usr/bin/dpkg -l |grep bigbluebutton',
    }

    exec { 'apt-get-update1':
        command      => '/usr/bin/apt-get update',
        unless => '/usr/bin/dpkg -l |grep bigbluebutton',
    }

    #instalando pacote software-properties-common
    package { 'software-properties-common':
        ensure => 'installed',
    }

    #adicionando repositório libre office
    exec { 'add-repository-libre-office':
        command      => '/usr/bin/add-apt-repository ppa:libreoffice/libreoffice-4-4',
    }

    #adicionando a chave do bigblueButton
    exec { 'bigblueButton-key':
        command      => '/usr/bin/wget http://ubuntu.bigbluebutton.org/bigbluebutton.asc -O- | sudo apt-key add -',
        unless => '/usr/bin/dpkg -l |grep bigbluebutton',
    }

	#adicionando repositorio bigbluebutton
    exec { 'source-list-bbb':
        command      => '/bin/echo "deb http://ubuntu.bigbluebutton.org/trusty-090/ bigbluebutton-trusty main" | sudo tee /etc/apt/sources.list.d/bigbluebutton.list',
        unless => '/usr/bin/dpkg -l |grep bigbluebutton',
    }

    exec { 'apt-get-update2':
        command      => '/usr/bin/apt-get update',
        unless => '/usr/bin/dpkg -l |grep bigbluebutton',
    }

    #instalando dependencias ffmpeg
    $enhancers = ["build-essential", "git-core", "checkinstall", "yasm", "texi2html", "libvorbis-dev", "libx11-dev", "libxfixes-dev", "zlib1g-dev", "pkg-config", "netcat", "libncurses5-dev", "wget", "ant", "openjdk-7-jdk", "curl","openssl", "vim"]
    package { $enhancers:
        ensure => installed,
    }

    #download ffmpeg
    exec { 'download-ffmpeg':
        command      => '/usr/bin/wget "http://ffmpeg.org/releases/ffmpeg-2.3.3.tar.bz2"',
        cwd => '/usr/local/src',
        unless => '/usr/bin/dpkg -l |grep ffmpeg',
    }
    #descompacta ffmepg
    exec { 'descompacta-ffmepg':
        command      => '/bin/tar -xjf "ffmpeg-2.3.3.tar.bz2"',
        cwd => '/usr/local/src',
        unless => '/usr/bin/dpkg -l |grep ffmpeg',
    }

    #configura ffmpeg para instalação
    exec { 'configure-ffmpeg':
        command      => '/usr/local/src/ffmpeg-2.3.3/configure',
        cwd => '/usr/local/src/ffmpeg-2.3.3',
        timeout     => 1800,
        unless => '/usr/bin/dpkg -l |grep ffmpeg',
    }

    #executa make para o ffmpeg
    exec { 'make-ffmpeg':
        command      => '/usr/bin/make',
        cwd => '/usr/local/src/ffmpeg-2.3.3',
        timeout     => 1800,
        unless => '/usr/bin/dpkg -l |grep ffmpeg',
    }

    #install ffmpeg
    exec { 'install-ffmpeg':
        command      => '/usr/bin/checkinstall --pkgname=ffmpeg --pkgversion="5:2.3.3" --backup=no --deldoc=yes --default',
        cwd => '/usr/local/src/ffmpeg-2.3.3',
        timeout => 1800,
        unless => '/usr/bin/dpkg -l |grep ffmpeg',
    }

    #install bigbluebutton
    package { 'bigbluebutton':
        ensure => installed,
    }

    #install bbb-demo
    package { 'bbb-demo':
        ensure => installed,
    }

    #install bbb-check
    package { 'bbb-check':
        ensure => installed,
    }

    #enable webrtc
    exec { 'enable-webrtc':
        command      => '/usr/bin/bbb-conf --enablewebrtc',
    }
    


    Exec["ufw-allow-ports-tcp"] ->
    Exec["ufw-allow-ports-udp"] ->
	Exec["add-multiverse"] ->

    Exec["apt-get-update1"] ->

    Package['software-properties-common'] ->
    Exec["add-repository-libre-office"] ->
    Exec["bigblueButton-key"] ->
    Exec["source-list-bbb"]->
    
    Exec["apt-get-update2"] ->

    Package[$enhancers] ->

    Exec["download-ffmpeg"] ->
    Exec["descompacta-ffmepg"] ->
    Exec["configure-ffmpeg"]->
    Exec["make-ffmpeg"]->
    Exec["install-ffmpeg"]->

    Package["bigbluebutton"]->
    Package["bbb-demo"]->
    Package["bbb-check"] ->
    Exec["enable-webrtc"]
}
