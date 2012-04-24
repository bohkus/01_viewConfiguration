#!/usr/bin/perl -w
# version 	beta 1.00

#	CHANGES:
#	beta 1.00
#	- deleteView() better support for force and request if not
# 	beta 0.6
#	- m option
#	- g option
#	- check_perl() to block sde_perl version below 5.6 (still default after installation:-()
# 	beta 0.5
#	- verbose option reworked with [marks]
# 	beta 0.4
#	- renamed to viewConfiguration
#	- 
# 	beta 0.3
#	- timestamp()
#	- use strict
# 	beta 0.2
#	- removed dotnotation for TIMESTAMP

use strict;
use warnings;
use Getopt::Std;

use Win32::TieRegistry( TiedHash => '%RegHash' );

use ENV;

$::VERSION	= "00.01.00";

my $option_view 					= "TIMESTAMP";
my $option_platformModule 			= "CRH1090921";
my $option_baselineLabel 			= "CRH1090921_R1C016";


my @option_singleModule; 			 
$option_singleModule[0] = "CRH1091033";
my $option_inputFile				= "";;

my $option_CPATH_LETTER				= get_cme_drive();
my $option_CRH_PATH 				= "LD_SubSystems_009\\crh1090921_thorium\\1551_crh1090921.cfg";
my $options_verbose					= 0;
my $options_force					= 0;
my $options_enviroment				= 0;
my $option_modules					= 0;

my $prefix_view;


# -------------------------------------------------------------------------------------------------------------------
sub check_perl{

	my $cmd;
	my $output;

	$cmd = "sde_perl -v | findstr \"v[0-9]\.[0-9]\"";
	$output = qx($cmd);
	chomp($output);
	if ($output =~ /v5.6.0/){
		printf("\nThe script will not supporte the sde_perl version");
		printf("\n$output");
		printf("\n");
		printf("\nPLEASE UPDATE to a newer version with:");
		printf("\nsde_options PerlVer Perl-5.8");
		printf("\nsde_options PerlVer Perl-5.10");
		printf("\nSWITCH BACK with:");
		printf("\nsde_options PerlVer perl will activate Perl-5.6");
		printf("\nWARNING DONT USE Perl-5.6 as option to switch back to version 5.6");
		printf("\nThe failure shown up below is th reason for it:\n");
		exit;
	}	


	
}

# -------------------------------------------------------------------------------------------------------------------
sub get_cme_drive{
	my (%reghash,$Registry,$key,$value);
	
	$Registry = \%RegHash;
	
	%reghash =(%{$Registry->{"HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\Mvfs\\Parameters\\"}});
	
	while (($key,$value) = each %reghash){
		#print ("\n$key $value");
		last if ($key eq "\\drive");
	};
	
	return $value;
}

# -------------------------------------------------------------------------------------------------------------------
 sub timestamp
{
	my $stamp;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
	$year = $year + 1900;
	$mon  = $mon + 1;
	
	$mon = "0".$mon if ($mon < 10);
	$mday = "0".$mday if ($mday < 10);
	$hour = "0".$hour if ($hour < 10);
	$min = "0".$min if ($min < 10);
	$sec = "0".$sec if ($sec < 10);
	
	$stamp = $year.$mon.$mday.$hour.$min.$sec;
	return $stamp;
 }



# -------------------------------------------------------------------------------------------------------------------
 sub deleteView
{
  my ($view,$cpath_letter) = @_;
  my $cmd = "cme rmview $view";
  my $output;
  my $input = "";
  my $view_path = $cpath_letter.":\\".$view;

  printf("\n [deleteView] $view") if ($options_verbose == 1);
  if (-d $view_path){
		if ($options_force == 1){
  			$output = qx($cmd);
			print (" OK ") if ($options_verbose == 1);
			return;
		}else{
			while (($input ne "YES") && ($input ne "NO")){
				print ("\n [deleteView] THE VIEW ALREADY EXIST, DO YOU WANT TO DELETE IT ? [YES or any for NO] ");
				$input = <STDIN>;
				chomp($input);
			}
			if ($input eq "YES"  || $input eq "yes" || $input eq "Y" || $input eq "y" ){
				$output = qx($cmd);
				return;
			}
			print ("\n [GOODBYE] ");
			exit;
		}
  }
  printf(" NOT NEEDED ") if ($options_verbose == 1);
 }

# -------------------------------------------------------------------------------------------------------------------
 
sub createView
{

  my ($view) = @_;
  my $cmd;
  my $output;
  
  print("\n [createView] $prefix_view") if ($options_verbose == 1);
  $cmd = "cme mkview $view";
  $output = qx($cmd);
  $output =~ /Success/  || die("\n failed: $cmd $!");

}

# -------------------------------------------------------------------------------------------------------------------
 sub addModuleToView
{
  my ($module,$label,$view) = @_;
  my $cmd;
  my $output;
  
  printf("\n [addModuleToView] - adding $module\@$label")  if ($options_verbose == 1);

  $cmd = "cme setcs -module $module -label $label $view";
  $output = qx($cmd);
  $output =~ /Success/  || die("failed: $cmd $!\n");
 }

# -------------------------------------------------------------------------------------------------------------------
 sub getModules_from_file
{
  my ($file) = @_;
  my $FILE;
  $option_singleModule[0] = "";
  open ($FILE,"<$file") || die "can't open $file";
  while (<$FILE>) {  
	chomp $_;
	s/^\s+//;
	s/\s+$//;
  	push(@option_singleModule,$_)
  }
  
  
  close $FILE;



}
# -------------------------------------------------------------------------------------------------------------------
 sub util_lowcast_module
{
	my ($module) = @_;
	$module =~ s/CNH/cnh/;
	$module =~ s/CRH/crh/;	
	return $module;
}
# -------------------------------------------------------------------------------------------------------------------
 sub getModuleLabelFromConfig
{

  my ($path1551,$view) = @_;

  my $cmd;
  my $output;
  my $Flag1551_subsystems	= 0;
  my $Flag1551_modules		= 0;
  my $module;
  my $label;
  my $FILE;
  my $singleModule;
  
  open ($FILE,"<$path1551") || die "can't open $path1551";
  printf("\n [getModuleLabelFromConfig] - found Project File  $path1551")  if ($options_verbose == 1);
  while (<$FILE>) {    

          	if (/^\[SubSystems\]/) {
				$Flag1551_subsystems	= 1;
				$Flag1551_modules		= 0;
          		next;
          	}
          	if (/^\[Modules\]/) {   
				$Flag1551_subsystems	= 0 if ($option_modules == 1);
				$Flag1551_modules		= 1 if ($option_modules == 1);
				next;
          	}
          	
  			if ($Flag1551_subsystems){
  				if (/^(CRH|crh|CNH|cnh)\d*@[0-9a-zA-Z]*/) {
  					($module,$label) = split(/@/);
					chomp ($label);
					chomp ($module);
					
					foreach $singleModule (@option_singleModule){
  						if ( ($module eq $singleModule) || ($singleModule eq "all") ){
  							print("\n [getModuleLabelFromConfig] - add $module \@ $label")  if ($options_verbose == 1);
							chomp($label);
							$cmd = "cme addmodule -module $module -label $label $view";
  							$output = qx($cmd);
  							$output =~ /Success/  || print("\n [getModuleLabelFromConfig] - failed add: $cmd \n");
  						}
					}
  				}
  			}
  			if ($Flag1551_modules){
				
  				if (/\s([_0-9a-zA-Z]{1,})$/) {
  					$label = $1; 
  					$label =~ s/^\s+//;
  					m/^([_0-9a-zA-Z]*\\)((CRH|crh|CNH|cnh)\d{7})_/;
  					$module = $2; 
					chomp ($label);
					chomp ($module);

  					foreach $singleModule (@option_singleModule){
						$singleModule = util_lowcast_module($singleModule);
						$module = util_lowcast_module($module);
  						if ( ($module eq $singleModule) || ($singleModule eq "all") ){
  							print("\n [getModuleLabelFromConfig] - add $module \@ $label")  if ($options_verbose == 1);
							chomp($label);
							$cmd = "cme addmodule -module $module -label $label $view";
  							$output = qx($cmd);
  							$output =~ /Success/  || print("\n [getModuleLabelFromConfig] - failed add: $cmd ");
  						}
  					}
  				}
  			}

  			if (($Flag1551_subsystems && /^\[/)||($Flag1551_modules && /^\[/)){
  					$Flag1551_subsystems 	= 0;  
  					$Flag1551_modules 		= 0;  
  			}
  			if (/EOF/){
  					print("\n");
  			}
  }
  
  close $FILE;
 }
# -------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------
#		MAIN 
# -------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------------------
my %options=();
getopts("V:M:L:C:S:P:X:hvcfemg",\%options);


check_perl(); #Sytem check


if (defined $options{h}){
    print "HELP  "; 
    print "\n\nInstructions with parameters:";
    print "\n-V Viewname without username Prefix                                                         ";
    print "\n                     # default value is TIMESTAMP (year.mon.mday.hour.min.sec)              ";
    print "\n                     # TIMESTAMP will use the actual time as name  (-V TIMESTAMP)           ";
    print "\n-M PlatformModule (CRH TOP Module)                                                          ";
    print "\n                     # default is CRH1090921                                                ";
    print "\n-L Baseline Label (CRH TOP Module)                                                          ";
    print "\n                     # default is CRH1090921_R1C016                                         ";
    print "\n-C CPATH_LETTER is the Network Dive given by one Character                                  ";
    print "\n                     # default is M                                                         ";
    print "\n-S SingleModule is to add just one of CRH module from the TOP CRH                           ";
    print "\n                     # default is CRH1091033                                                ";
    print "\n                     # use all to add all modules from  1551  [SubSystems\]   (-S all)      ";
    print "\n-P CRH_PATH defines the relative path in the view to the PROJECTFILE 1551_...cfg            ";
    print "\n                     # default is LD_SubSystems_009\\crh1090921_thorium\\1551_crh1090921.cfg";
    print "\n-X List off Modules to added, deletes -S settings , will be later a XML file                ";
    print "\n";
    print "\n\nInstructions :";
    print "\n-f force to overwite Views               # default is disabled                              ";
    print "\n-m modules from 1551 projectfile [Modules] and the default chapter [SubSystems]             ";
    print "\n-v verbose is is the noisy output                                                           ";
    print "\n\nSingle Instructions:";
    print "\n-g version will be printed and nothing else                                                 ";
    print "\n-c the ClearCase Mvfs drive version will be printed and nothing else                        ";
    print "\n-h that will show this help                                                                 ";
    print "\n";
    print "\nEXAMPLE:";
    print "\nsde_perl viewConfiguration.pl -L CRH1090921_R1C028";
    
    exit;
};
if (defined $options{g}){
	print "Version: $::VERSION";
	exit;
}
if (defined $options{c}){
	print get_cme_drive();
	exit;
}
if (defined $options{v}){
	$options_verbose	 = 1;
}
if (defined $options{f}){
	$options_force		 = 1;
}
if (defined $options{e}){
	$options_enviroment	 = 1;
}
if (defined $options{m}){
	$option_modules	 = 1;
}

print "\n -V $options{V}" 				if (defined $options{V}) && ($options_verbose ==1);
$option_view 					=  $options{V}  if defined $options{V};
print "\n -M $options{M}" 				if (defined $options{M}) && ($options_verbose ==1);
$option_platformModule 			=  $options{M}  	if defined $options{M};
print "\n -L $options{L}" 				if (defined $options{L}) && ($options_verbose ==1);
$option_baselineLabel  			=  $options{L}  	if defined $options{L};
print "\n -C $options{C}" 				if (defined $options{C}) && ($options_verbose ==1);
$option_CPATH_LETTER 			=  $options{C}  if defined $options{C};
$option_CPATH_LETTER 			=~ s/://;
print "\n -S $options{S}" 				if (defined $options{S}) && ($options_verbose ==1);
$option_singleModule[0] 		=  $options{S} 	if defined $options{S};
print "\n -X $options{X}" 				if (defined $options{X}) && ($options_verbose ==1);
$option_inputFile		 		=  $options{X} 	if defined $options{X};
print "\n -P $options{P}" 				if (defined $options{P}) && ($options_verbose ==1);
$option_CRH_PATH 				=  $options{P}  if defined $options{P};


$option_view 					= timestamp() if ($option_view eq "TIMESTAMP");
$prefix_view					= $ENV{username}."_".$option_view;
$::CPATH1551					= $option_CPATH_LETTER.":\\".$prefix_view."\\".$option_CRH_PATH;

print "\n" if ($options_verbose ==1);# MAIN INITIALIZATION DONE


my $Register = "SYSTEM\\CurrentControlSet\\Services\\Mvfs\\Parameters";
my ($hkey, @key_list, $key);
my $SubKey="drive";
my $Value ="nothing" ;
my $type;

#CONFIGURAITION via FILE
getModules_from_file($option_inputFile) if not ($option_inputFile eq "");

#Delete view in case it already exists
deleteView($prefix_view,$option_CPATH_LETTER);

#Create new VIEW
createView($option_view);
#Add top product CRH1090921 with specific LABEL into VIEW
addModuleToView($option_platformModule, $option_baselineLabel, $prefix_view);
#Search for module in 1551- of top product and if it is found add it into view
getModuleLabelFromConfig($::CPATH1551, $prefix_view);

print ("\n RESULT = ") if ($options_verbose == 1);
printf("$prefix_view");


__END__

=pod

=head1 NAME

viewConfiguration.pl

=head1 WARNINGS

You have to update your system form the defaulte SDE_PERL

Versin to at least 5.8

simple execute sde_perl viewConfiguration.pl -h

for more info.



=head1 VERSION

VERSION 0.8

=head1 SYNOPSIS

sde_perl viewConfiguration.pl [instructions with parameters][Instructions][Single Instructions]

sde_perl viewConfiguration.pl [Single Instructions]



B<Instructions with parameters:>

-V Viewname without username Prefix

                     # default value is TIMESTAMP (year.mon.mday.hour.min.sec)

                     # TIMESTAMP will use the actual time as name  (-V TIMESTAMP)

-M PlatformModule (CRH TOP Module)

                     # default is CRH1090921

-L Baseline Label (CRH TOP Module)

                     # default is CRH1090921_R1C016

-C CPATH_LETTER is the Network Dive given by one Character

                     # default is M

-S SingleModule is to add just one of CRH module from the TOP CRH

                     # default is CRH1091033

                     # use all to add all modules from  1551  [SubSystems]   (-S all)

-P CRH_PATH defines the relative path in the view to the PROJECTFILE 1551_...cfg

                     # default is LD_SubSystems_009\crh1090921_thorium\1551_crh1090921.cfg



B<Instructions :>

-f force to overwite Views               # default is disabled

-m modules from 1551 projectfile [Modules] and the default chapter [SubSystems]



B<Single Instructions:>

-v verbose is is the noisy output

-g version will be printed and nothing else

-c the ClearCase Mvfs drive version will be printed and nothing else

-h that will show this help


=head1 DESCRIPTION

Flash Packages generation script with routine for automatic CME view handling. 

Main usage is to generate the view for a toplabel according its SERVER_PATH and TOP_PRODUCT_LABEL.

B<Example for THORIUM ITP:>


sde_perl viewConfiguration.pl -L CRH1090921_R1C028 

The SERVER_PATH (Mvfs drive) will be taken from the ClearCase settings but can be set, see L</"SYNOPSIS">.

The PlatformModule is THORIUM (CRH1090921) but can be set, see L</"SYNOPSIS">

Only the Label has to be set via option -L [LABEL]

B<Example for how to add Module to View :>


a different PlatformModule and Sub Module will be choosed

sde_perl viewConfiguration.pl -L CRH1090921_R1C028 -M CRH1090921 -S CRH1091033

all modules from the 1551 Project file under [SubSystems] will be added to the view

B<Example for enhanced module adding (getModuleLabelFromConfig)  :>

sde_perl viewConfiguration.pl -L CRH1090921_R1C028 -S all

all modules from the 1551 Project file under [SubSystems] and [Modules] will be added to the view

sde_perl viewConfiguration.pl -L CRH1090921_R1C028 -S all -m


=head1 Prediction


The -X Option will will give you the possibility to use the script via a XML fie.

The XML file will also the start for bigger automations and in first step let you scale the list of to be added modules,

insted of just one, all from [SubSystems] or [SubSystems]and [Modules]



=head1 Author

L<bohumil.kus@stericsson.com>.


