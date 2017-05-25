#!/usr/bin/perl

#
# SecurityGuy 2017.05
#
# perl check_vm_snapshots.pl --username='apiuser@domain.com' --password='*****' --server=vcenter1.domain.com --mindays=7 --search=sec
#

use strict;
use warnings;

use Date::Parse;
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
    mindays => {
        type     => "=i",
        variable => "mindays",
        help     => "days after a snapshot is alarmed",
        required => 1,
    },
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate();
Util::connect();


my $search = Opts::get_option('search');
my $mindays = Opts::get_option('mindays');


# find VMs that have word 'sec' in the name
my $vms = Vim::find_entity_views(
          view_type => 'VirtualMachine',
          properties => ['name', 'config.template', 'guest', 'snapshot', ],
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
      push @vms, $vm;
}

foreach my $vm (sort { $a->name cmp $b->name } @vms)
{
        my $vm_name = $vm->name;
        if ($vm->snapshot)
        {
                #print "$vm_name ";
                $line .= "$vm_name ";

                foreach my $snap (@{$vm->snapshot->rootSnapshotList})
                {
                        printSnaps($snap);
                }
                $line .= ", ";
        }
}

Util::disconnect();

if (length ($line) > 5)
{
        $state = "WARNING";
        $line =~ s/, $//;
        print "$state: VMWARE_SNAPSHOTS  " . $line;
        exit $ERRORS{$state};
}
exit $ERRORS{$state};


sub printSnaps
{
        my ($snapshotTree) = shift;

        my $epoch_snap = str2time( $snapshotTree->createTime );
        my $days_snap  = sprintf("%0.1f", ( time() - $epoch_snap ) / 86400 );

        # skip if snapshot was taken 7 days or less
        #if ( $days_snap >= $vm_snap_old_min)
        if ( $days_snap >= $mindays)
        {

                $line .=  ' ["' .$snapshotTree->name . '" ';
                $line .=  $days_snap . " days_old" . '] ';

                # recursive
                if ($snapshotTree->childSnapshotList)
                {
                        foreach my $snaps (@{$snapshotTree->childSnapshotList})
                        {
                                printSnaps($snaps);
                        }
                }
        }
}

