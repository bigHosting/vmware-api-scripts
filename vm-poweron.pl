#! /usr/bin/perl


# perl vm-poweron.pl --username='secvmapi@domain.com' --password='*****' --server=10.53.0.11 --vmname=ns1.domain.com
# https://raw.githubusercontent.com/esacs2004/infrastructure/0390105b20b25251010e05698331e609809fc1fd/VMBuilder/etc/poweron.pl

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
		required => 1,
	},
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate();


my $vmname = Opts::get_option('vmname');
my $state="";

Util::connect();

# find VM
my $vm_view = Vim::find_entity_views(view_type => 'VirtualMachine', filter => {'name' => $vmname});
if (!$vm_view)
{
	print "[*] $0: ERROR: Failed to locate VM\n";
        Util::disconnect();
        exit(1);
}

# check state to be poweredOn
foreach my $vm (@$vm_view) {
	if ($vm->runtime->powerState->val !~ m/poweredOff/i)
        {
               	print "[*] $0: ERROR: VM " . $vm->name . " is NOT powered Off. \n";
	        Util::disconnect();
                exit(1);
        }
}

# powerOnVM
$vm_view = Vim::find_entity_view(view_type => 'VirtualMachine', filter => {'name' => $vmname});
$vm_view->PowerOnVM();
print "[*] $0: SUCCESS: powering on the VM\n\n";

Util::disconnect();

