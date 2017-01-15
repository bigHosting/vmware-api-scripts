#!/usr/bin/perl -w
#
# Security Guy - added timestamp when snapshotting VMs
#
# Copyright 2006 VMware, Inc.  All rights reserved.
#
# This script snapshots all powered on VM's
#
# perl vm-snapshot.pl --username='secvmapi@domain.com' --password='*****' --server=10.53.0.11 --vmname=ns1.domain.com
# https://github.com/zinneranast/ESXi_Controller-VM/blob/0b43cb7cfef05c3f1e89255686575b9296b7950e/share/doc/vmware-vcli/samples/vm/snapshot.pl
#
use strict;
use warnings;

use VMware::VIRuntime;

use POSIX qw(strftime);
my $now_string = strftime "%Y%m%d-%H%M%S", gmtime;


$SIG{__DIE__} = sub{Util::disconnect()};

my %opts = (
   'vmname' => {
      type => "=s",
      help => "Name of the virtual machine",
      required => 0,
   },
);

# read/validate options
Opts::add_options(%opts);
Opts::parse();
Opts::validate();

Util::connect();

# look up virtual machine and unregister it
my $vm_name = Opts::get_option('vmname');

if (defined($vm_name)) {
   my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine',
                                       filter => {'config.name' => $vm_name,
                                                  'runtime.powerState' => 'poweredOn' });
   if (!defined($vm_view)) {
      die "Did not find virtual machine '$vm_name' powered on!";
   }
   Util::trace(0, "Snapshotting VM " . $vm_view->name . "\n");
   $vm_view->CreateSnapshot(name => "$now_string",
                            description => "Snapshot created $now_string with vm-snapshot.pl",
                            memory => 0,
                            quiesce => 0);
   Util::trace(0, "Snapshot $now_string complete for VM: " . $vm_view->name . "\n");
} else {
   die "You must specify a VM to snapshot!!";
}

Util::disconnect();
