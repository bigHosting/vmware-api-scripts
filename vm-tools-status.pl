#!/usr/bin/perl

# perl vm-tools-status.pl --username='secvmapi@domain.com' --password='*****' --server=10.53.0.11 --output=/tmp/file.txt

=head1 NAME

vm-tools-status.pl

=head1 SYNOPSIS

perl vm-tools-status.pl --username admin --password foo --server virtualcenter

=head1 ARGUMENTS

=over

=item --help

Show the arguments for this program.

=back

=head1 DESCRIPTION

Find the VMs with no vmtools installed or not running B<virtualcenter>.

=head1 SEE ALSO

L<VMware Perl SDK|http://www.vmware.com/support/developer>

=head1 AUTHOR

Security Guy

=cut

use strict;
use warnings;
use VMware::VIRuntime;

$SIG{__DIE__} = sub{Util::disconnect()};
$Util::script_version = "1.0";

Opts::parse();
Opts::validate();
Util::connect();


# Get all VMs
my $vms = Vim::find_entity_views(
        view_type => 'VirtualMachine',
);

unless (defined $vms){
        die "No VMs found!\n";
}

my $counter = 0;

# Iterate over the VMs. Let's sort by vm names!
foreach my $vm (@{ $vms }) {
#foreach my $vm( sort {$a->config->name cmp $b->config->name} @$vms) {
        # is VM powered ON ?
        next if ($vm->runtime->powerState->val !~ m/poweredOn/i);

        # can we get vmtools status ?
        #next if (!defined ($vm->guest->toolsStatus) );

        # is vmtools software installed
        if($vm->guest->toolsStatus->val !~ m/toolsOk/i)
        {
                $counter++;
                print $vm->name . "\n";
        }

}
Util::disconnect();

print "[*] $0: INFO: " . $counter . " VMs found where vmtools package not installed or not running\n";
exit(0);

