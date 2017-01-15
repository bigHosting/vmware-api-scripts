#!/usr/bin/perl -w
#
# perl vm-setboot.pl --username='secvmapi@domain.com' --password='*****' --server=10.53.0.11 --vmname=ns1.domain.com --bootorder=net
# https://github.com/tbe/openqrm/blob/3b179f2df4e3ee8b2d73d1c953d9d7a26120118f/src/plugins/vmware-esx/bin/perl/vmsetboot.pl
#
# this is a perl script to set the boot order of a VM
#
# openQRM Enterprise developed by openQRM Enterprise GmbH.
#
# All source code and content (c) Copyright 2012, openQRM Enterprise GmbH unless specifically noted otherwise.
#
# This source code is released under the GNU General Public License version 2, unless otherwise agreed with openQRM Enterprise GmbH.
# The latest version of this license can be found here: src/doc/LICENSE.txt
#
# By using this software, you acknowledge having read this license and agree to be bound thereby.
#
#           http://openqrm-enterprise.com
#
# Copyright 2012, openQRM Enterprise GmbH <info@openqrm-enterprise.com>
#

use strict;
use warnings;

#use lib "/usr/lib/vmware-vcli/apps/";

$SIG{__DIE__} = sub{Util::disconnect()};

use VMware::VIRuntime;
use VMware::VILib;
#use Data::Dumper;

my %opts = (
	vmname => {
		type => "=s",
		help => "The name of the VM",
		required => 1,
	},
	bootorder => {
	  type => "=s",
	  help => "one of net, hd or cd",
	  required => 1,
	},
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate();
Util::connect();

my %filterhash = ();
my $vmname = Opts::get_option('vmname');
my $bootorder = Opts::get_option('bootorder');
my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine', filter => {name => $vmname});
if($vm_view) {
	my $vm_config_spec = VirtualMachineConfigSpec->new(
		name => $vmname,
		extraConfig => [OptionValue->new( key => 'bios.bootDeviceClasses',
		value => $bootorder ),]
	);
    $vm_view->ReconfigVM( spec => $vm_config_spec );
}
Util::disconnect();

