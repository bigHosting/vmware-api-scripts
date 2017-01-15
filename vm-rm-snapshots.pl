#!/usr/bin/perl

# perl vm-rm-snapshots.pl --username='secvmapi@domain.com' --password='*****' --server=10.53.0.11 --vmname=ns1.domain.com
# https://github.com/jbarber/vmware-perl/blob/dc3b9fea62f8087a6ec8993dda714af461e47c53/find_snapshots.pl
#
=head1 NAME

find_snapshots.pl

=head1 SYNOPSIS

./find_snapshots.pl --username admin --password foo --host virtualcenter

=head1 ARGUMENTS

=over

=item --help

Show the arguments for this program.

=back

=head1 DESCRIPTION

Enumerate all VMs with snapshots.

=head1 SEE ALSO

L<VMware Perl SDK|http://www.vmware.com/support/developer>

=head1 AUTHOR

Jonathan Barber - <jonathan.barber@gmail.com>

=cut

use strict;
use warnings;
use VMware::VIRuntime;

$Util::script_version = "1.0";

my %opts = (
	vmname => {
		type => "=s",
		help => "VM Name",
		required => 1,
	},
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate();


my $vmname = Opts::get_option('vmname');

Util::connect();

# find VM
my $vm_view = Vim::find_entity_views(view_type => 'VirtualMachine', filter => {'name' => $vmname});
if (!$vm_view)
{
        print "[*] $0: ERROR: Failed to locate VM\n";
        Util::disconnect();
        exit(1);
}

# Iterate over the VMs, printing their name if they have any snapshots
foreach my $vm (@{ $vm_view }) {
        print $vm->name, "\n" if $vm->snapshot;
        my $snapshots = $vm->snapshot;
        if(defined $snapshots)
        {
            eval {
                    print "\nRemoving snapshots for " . $vm->name . " ... ";
                    $vm->RemoveAllSnapshots();
                    $@ ? print "Failed.\n" : print "Done.\n";
            }
        }
}

Util::disconnect();
