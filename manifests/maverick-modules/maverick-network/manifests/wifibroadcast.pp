class maverick-network::wifibroadcast (
) {
    
    ensure_packages(["libpcap-dev", "gcc", "make", "libcap2-bin"])
    
    oncevcsrepo { "git-wifibroadcast":
        gitsource   => "https://github.com/fnoop/wifibroadcast",
        dest        => "/srv/maverick/software/wifibroadcast",
        owner       => "mav",
        require     => [ Package["gcc"], Package["make"] ]
    } ->
    exec { "compile-wifibroadcast":
        command     => "/usr/bin/make all",
        creates     => "/srv/maverick/software/wifibroadcast/tx",
        user        => "mav",
        cwd         => "/srv/maverick/software/wifibroadcast",
    } ->
    file { "/srv/maverick/software/wifibroadcast/tx":
        mode        => 755,
        owner       => "mav",
        group       => "mav",
    } ->
    exec { "setcaps-wtx":
        command     => "/sbin/setcap cap_net_raw,cap_net_admin=eip /srv/maverick/software/wifibroadcast/tx",
        # unless      => "",
    } ->
    exec { "copy-patched-9271-firmware":
        command     => "/bin/cp -f /srv/maverick/software/wifibroadcast/patches/AR9271/firmware/htc_9271.fw /lib/firmware",
        onlyif      => "/usr/bin/diff /srv/maverick/software/wifibroadcast/patches/AR9271/firmware/htc_9271.fw /lib/fimware/htc_9271.fw |/bin/grep differ",
    } ->
    file { "/srv/maverick/software/maverick/bin/wifibroadcast-if.sh":
        ensure      => link,
        target      => "/srv/maverick/software/maverick/manifests/maverick-modules/maverick-network/files/wifibroadcast-if.sh"
    } ->
    file { "/etc/systemd/system/wifibroadcast@.service":
        content     => template("maverick-network/wifibroadcast@.service.erb"),
        owner       => "root",
        group       => "root",
        mode        => 644,
        notify      => [ Exec["maverick-systemctl-daemon-reload"] ]
    }

}