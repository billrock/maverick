class maverick_web::nginx (
    $port,
    $ssl_port,
) {
    
    # Nginx doesn't have repo for ARM, so don't try to use it
    if $::architecture =~ "arm" {
        $manage_repo = false
    } else {
        $manage_repo = true
    }

    # Make sure apache system services are stopped
    service_wrapper { "apache2":
        ensure      => stopped,
        enable      => false,
    } ->
    file { "/etc/systemd/system/maverick-nginx.service":
        owner       => "root",
        group       => "root",
        mode        => "644",
        source      => "puppet:///modules/maverick_web/maverick-nginx.service",
        notify      => Exec["maverick-systemctl-daemon-reload"],
    } ->
    class { 'nginx':
        confd_purge     => true,
        server_purge    => true,
        manage_repo     => $manage_repo,
        service_manage  => true,
        service_name    => "maverick-nginx",
    }

    nginx::resource::server { "${::hostname}.local":
        listen_port => $port,
        ssl         => true,
        ssl_port    => $ssl_port,
        ssl_cert    => "/srv/maverick/data/web/ssl/${::hostname}.local-webssl.crt",
        ssl_key     => "/srv/maverick/data/web/ssl/${::hostname}.local-webssl.key",
        www_root    => '/srv/maverick/software/maverick-fcs/public',
        require     => [ Class["maverick_gcs::fcs"], ],
        notify      => Service["maverick-nginx"],
    }
    
    nginx::resource::location { "mavca":
        ensure          => present,
        ssl             => true,
        location        => "/security/mavCA.crt",
        location_alias  => "/srv/maverick/data/security/ssl/ca/mavCA.pem",
        index_files     => [],
        server          => "${::hostname}.local",
        require         => [ Class["maverick_gcs::fcs"], ],
        notify          => Service["maverick-nginx"],
    }

}