#!/usr/bin/perl

#
# SecurityGuy 2017.05
#
#
# perl check_vm_tools.pl --username='apiuser@domain.com' --password='******' --server=vcenter.domain.com --search=sec
#

use strict;
use warnings;


use VMware::VIRuntime;
$SIG{__DIE__} = sub{Util::disconnect()};




my %ERRORS = ('UNKNOWN' , '3',
              'OK' , '0',
              'WARNING', '1',
              'CRITICAL', '2');

my $state = "OK";
my $line = '';
my @vms = ();



my %opts = (
    search => {
        type     => "=s",
        variable => "search",
        help     => "search for string in VM name",
        required => 1,
    },
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate();
Util::connect();


my $search = Opts::get_option('search');


# find VMs that have word 'sec' in the name
my $vms = Vim::find_entity_views(
          view_type => 'VirtualMachine',
          properties => ['name', 'config.template', 'guest', 'runtime' ],
          filter => {
                'config.name' => qr/$search/i,
          }
);

if (!$vms)
{
        print "check_vm_snapshots.pl: Search for VMs failed.\n";
        exit $ERRORS{$state};
}

if (!(scalar @{$vms}))
{
        print "check_vm_snapshots.pl: Found no VMs.\n";
        exit $ERRORS{$state};
}

foreach my $vm (@{$vms})
{
      next if ($vm->get_property('config.template') eq 'true');   # templates don't participate in name matches
      next if ($vm->runtime->powerState->val !~ m/poweredOn/i);   # must be powered on
      #next if (!defined ($vm->guest->toolsStatus) );              
      if($vm->guest->toolsStatus->val !~ m/toolsOk/i)
      {
              push @vms, $vm;
      }
}

foreach my $vm (sort { $a->name cmp $b->name } @vms)
{
        my $vm_name          = $vm->name;
        my $vm_tools_status  = $vm->guest->toolsStatus->val;
        $line .= "$vm_name [$vm_tools_status], ";
}

Util::disconnect();

if (length ($line) > 5)
{
        $state = "WARNING";
        $line =~ s/, $//;
        print "$state: VMWARE_VMTOOLS  " . $line;
        exit $ERRORS{$state};
}
exit $ERRORS{$state};

