package Ubic::Service::Spark2;
BEGIN {
  $Ubic::Service::Spark2::VERSION = '1.0';
}

use strict;
use warnings;

# ABSTRACT: Helper for running node.js applications with ubic and spark2

=head1 NAME

Ubic::Service::Spark2 - ubic-style Spark2 service

=head1 VERSION

version 1.0

=head1 SYNOPSIS

    use Ubic::Service::Spark2;
    return Ubic::Service::Spark2->new({
        app      => '/var/www/app.js',
        app_name => 'app',
        status   => sub { ... },
        port     => 4444,
        ubic_log => '/var/log/app/ubic.log',
        stdout   => '/var/log/app/stdout.log',
        stderr   => '/var/log/app/stderr.log',
        user     => 'www-data',
    });

=head1 DESCRIPTION

This service is a common ubic wrap for node.js applications. It uses spark2 for running these applications.

Spark2 is a fork of the Spark command-line tool used to start up node server instances.
For more info on Spark2 see http://github.com/davglass/spark2

=cut

use base qw(Ubic::Service::Common);

use Params::Validate qw(:all);

use Ubic::Daemon qw(:all);
use Ubic::Service::Common;

sub new {
    my $class = shift;

    my $params = validate(@_, {
        app_name    => { type => SCALAR },
        server_args => { type => HASHREF, default => {} },
        app         => { type => SCALAR, optional => 1 },
        user        => { type => SCALAR, optional => 1 },
        status      => { type => CODEREF, optional => 1 },
        port        => { type => SCALAR, regex => qr/^\d+$/, optional => 1 },
        ubic_log    => { type => SCALAR, optional => 1 },
        stdout      => { type => SCALAR, optional => 1 },
        stderr      => { type => SCALAR, optional => 1 },
        pidfile     => { type => SCALAR, optional => 1 },
        app_pidfile => { type => SCALAR, optional => 1 },
    });

    my $spark_bin = '/usr/bin/spark2';
    my $pidfile = $params->{pidfile} || "/tmp/$params->{app_name}.pid";
    my $app_pidfile = $params->{app_pidfile} || "/tmp/spark2-$params->{app_name}.pid";

    my $options = {
        start => sub {
            my %args = (
                $class->defaults,
                pidfile => $app_pidfile,
                %{$params->{server_args}},
            );
            if ($params->{port}) {
                $args{port} = $params->{port};
            }
            my @cmd = ($spark_bin, '--force');
            foreach my $key (keys %args) {
                push @cmd, "--$key";
                my $v = $args{$key};
                push @cmd, $v if defined($v);
            }
            push @cmd, $params->{app} if $params->{app};

            my $daemon_opts = { bin => \@cmd, pidfile => $pidfile, term_timeout => 5 };
            for (qw/ubic_log stdout stderr/) {
                $daemon_opts->{$_} = $params->{$_} if $params->{$_};
            }
            start_daemon($daemon_opts);
            return;
        },
        stop => sub {
            return stop_daemon($pidfile, { timeout => 7 });
        },
        status => sub {
            my $running = check_daemon($pidfile);
            return 'not running' unless ($running);
            if ($params->{status}) {
                return $params->{status}->();
            } else {
                return 'running';
            }
        },
        user => $params->{user} || 'root',
        timeout_options => { start => { trials => 15, step => 0.1 }, stop => { trials => 15, step => 0.1 } },
    };

    if ($params->{port}) {
        $options->{port} = $params->{port};
    }

    my $self = $class->SUPER::new($options);

    return $self;
}

sub defaults {
    return ();
}

=head1 AUTHORS

Sergey Belov <peimei@ya.ru>

=cut

1;
