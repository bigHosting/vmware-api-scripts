#!/usr/bin/perl -w

#
# perl vm-search.pl --username='secvmapi@domain.com' --password='*****' --server=10.53.0.11 --find=sec
#

use strict;
use warnings;

use VMware::VIRuntime;
use VMware::VILib;

my %opts = (
        find => {
                type => "=s",
                help => "Search for vm name, case insensitive",
                required => 1,
        }
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate();

Util::connect();

my $find = Opts::get_option('find');

my $vms = Vim::find_entity_views(
	view_type => 'VirtualMachine',
	properties => [ 'name', 'config' ],
	filter => { 
		'config.template' => 'false',
		'config.name' => qr/$find/i,
		#'runtime.powerState' => 'poweredOn'
	} 
);

foreach my $vm (@$vms) {
	print $vm->name . "\n";
}

Util::disconnect();

