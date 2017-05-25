#!/usr/bin/perl -w

# 
# /usr/bin/perl check_vm_e1000.pl --username='apiuser@domain.com' --password='*****' --server=vcenter1.domain.com --search=sec
#
use strict;
use warnings;

use VMware::VIRuntime;
$SIG{__DIE__} = sub{Util::disconnect()};


sub uniq {
  my (@input) = @_;
  my %all = ();
  @all{@input} = 1;
  return (keys %all);
}


my %ERRORS = ('UNKNOWN' , '3',
              'OK' , '0',
              'WARNING', '1',
              'CRITICAL', '2');

my $state = "OK";
my ( @vms, @list ) = ();
my %hash;

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

my $vms = Vim::find_entity_views(
          view_type => 'VirtualMachine',
          #properties => ['name', 'config.template', 'hardware', 'config', ],
          filter => {
                'config.template' => 'false',
                'runtime.powerState' => 'poweredOn',
                'config.name' => qr/$search/i,
          }
);

if (!$vms)
{
        print "check_vm_e1000.pl: Search for VMs failed.\n";
        exit $ERRORS{$state};
}

if (!(scalar @{$vms}))
{
        print "check_vm_e1000.pl: Found no VMs.\n";
        exit $ERRORS{$state};
}


foreach my $vm ( @{ $vms } )
{
      # skip check for some instances
      next  if ($vm->name =~ /ksrv/);

      my $vm_name = $vm->name;

      my $config=$vm->config if $vm->config;

      my $hardware=$config->hardware if $config->hardware;

      my $device=$hardware->device if $hardware->device;

      foreach my $dev (@{ $device })
      {
          #print ref($dev)."\n";
          my $type=ref($dev);
          if(grep(/$type/,("VirtualE1000"))>0)
          {
                  push ( @{ $hash{$vm_name} }, $dev->macAddress );
          }
      }
}

Util::disconnect();

#@list = (sort { $a->name cmp $b->name } @list);
@list = sort (&uniq(keys %hash));
if (scalar (@list) > 0)
{
        $state = "WARNING";
        print "$state: VMWARE_E1000  " . join(', ',@list);
        exit $ERRORS{$state};
}
exit $ERRORS{$state};


