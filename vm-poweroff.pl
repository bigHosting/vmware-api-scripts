#! /usr/bin/perl

# perl vm-poweroff.pl --username='secvmapi@domain.com' --password='*****' --server=10.53.0.11 --vmname=ns1.domain.com
# https://github.com/esacs2004/infrastructure/blob/0390105b20b25251010e05698331e609809fc1fd/VMBuilder/etc/poweroff.pl
#
use strict;
use warnings;

use VMware::VIRuntime;
use VMware::VILib;
#use Data::Dumper;

$SIG{__DIE__} = sub{Util::disconnect()};

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
$ENV{'HTTP_PROXY'} = undef;
$ENV{'HTTPS_PROXY'} = undef; 
$ENV{'http_proxy'} = undef;
$ENV{'https_proxy'} = undef; 

my %opts = (
	vmname => {
		type => "=s",
		help => "VM Name",
		required => 0,
	},
);
Opts::add_options(%opts);
Opts::parse();
Opts::validate();

my $vmname = Opts::get_option('vmname');

Util::connect();

my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine', filter => {'name' => $vmname});
if ($vm_view)
{
	$vm_view->PowerOffVM();
	print "Success\n";
} else {
	print "Failed to locate VM\n";
}
Util::disconnect();
