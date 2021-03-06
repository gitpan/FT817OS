# This is Yaesu FT817OS Command Library Front End
# Written by Jordan Rubin 
# For use with the FT817COMM and FT-817 Serial Interface
#
# $Id: FT817COMM.pm 2014-22-4 12:00:00Z JRUBIN $
#
# Copyright (C) 2014, Jordan Rubin
# jrubin@cpan.org 

#!/usr/bin/perl

use strict;
use Ham::Device::FT817COMM;
use vars qw($VERSION $configfile $version $port $baud $lockfile $prompt $softcalfile $output
$serialport $baudrate $cfg_line $cfg_value $savedconfig $saveddigest $testconfig $FT817 $digest);

#use Data::Dumper;
#use diagnostics;

our $finish; our $input; our $data; our $memoryfile; our $configfile; our $radioconfigfile; our $softcalfile; our $serialport; our $baudrate; our $FT817; our $radioname; our $default; our $activeradio;
our $version; our $VERSION = '0.9.3'; our @configdata; our @filteredarray; our $savedconfig; our $saveddigest; our @history; our $MAX_HISTORY;  
our $output; our @outputs; our $configflag; our $directory; our @values; our $write; our $currentdir; our $currentband; our $name; our $memtype; our 
$rootflag; our $exitflag; our @mconfigdata; our %radiohash; our @radiodata; our $totalradios; our $localtime = localtime(); our $digest; our $config; $MAX_HISTORY = 50;

############################################ HELP

sub help {
        my $helptype = shift;
	$helptype = uc($helptype);

        if ($helptype  eq 'SYSTEM' || !$helptype) {
print "\nSYSTEM Commmands:\n
add radio                      Adds a new radio to the system 
bitwatch [ON/OFF]              Alerts for changed bits in unknown memory areas
clear                          Clears the screen
config                         Go to config sub directory
default radio [radioname]      Sets given radio as the default startup radio
list                           A list of active memory areas
load config [filename]         Rewrites the radio config from a file. If no filename is given, uses default
load memory [filename]         Rewrites the radio memory from a file. If no filename is given, uses default
memory                         Go to memory sub directory
debug [ON/OFF]                 Toggles debugger
help [SYSTEM/CAT/GET/SET]      Shows this help page, returns all commands when no argument given
history                        Returns the last 50 commands entered
outputlog                      Shows running log of inputs and cooresponding outputs
quit / exit                    Exit program
rebuild softcal [filename]     Rebuilds the software calibration from backup, if no filename given uses default
remove radio [radioname]       Removes a radio from the system
restore [####]                 Restores corrupted area of eeprom to default
save config [filename]         Saves radio config to a file, if no filename is given, uses default
save memory [filename]         Saves regular memory areas to a file, if no filename is given, uses default
show flags                     Shows the values of all flags
show radios                    Lists radio currently configured for FT817OS
show status                    Provides formatted information about the status of the radio
switch radio [radioname]       Switches active radio in FT817OS
test calibration               Tests the current digest of the software calibration against the backup
test config                    Tests the current radio config against the backed up version
write [enable/disable]         Turns on EEprom writing capability

";
                                                   }

       if ($helptype eq 'CAT' || !$helptype) {
print "\nCAT Commands:\n
cat clarifier [ON/OFF]                                 Enables or disables the clarifier
cat clarifierfreq [pos/neg] [####]                     Sets the polarity and offset of the clarifier
cat ctcsstone [####]                                   Sets the tone for CTCSS
cat dcscode [####]                                     Sets the code for DCS
cat encoder [CTCSS/DCS/ON/OFF]                         Sets the encoder
cat getfrequency                                       Retrieves the current frequency of radio
cat setfrequency [########]                            Changes frequency of active VFO
cat lock [ON/OFF]                                      Enables or disables radio lock
cat getmode                                            Retrieves the current mode of radio
cat setmode [MODE]                                     Sets the mode, USB LSB FM etc...
cat offset [NEG/POS/SIMPLEX]                           Sets the repeater offset
cat offsetfreq [########]                              Sets the Offset frequency
cat power [ON/OFF]                                     Turns the radio ON or OFF (use only with DC power source)
cat ptt [ON/OFF]                                       Enables or disables Push to Talk
cat rxstatus                                           Retrieves status of SQUELCH, SMETER, MATCH, and DESCRIMINATOR
cat splitfreq [ON/OFF]                                 Enables or disables split frequencies
cat togglevfo                                          Switches between VFO A and B
cat txstatus                                           Retrieves status of PTT, POWER METER, HIGH SWR, SPLIT

";
			       }

       if ($helptype eq 'GET') {
print "\nGET Commands:\n
get agc                                       Returns the setting of the AGC
get antenna [ALL/HF/6M/FMBCB/AIR/VHF/UHF]     Displays the setting of the antenna port on a given band
get arts                                      Returns the status or ARTS
get breakin				      Returns the status of Break (BK)
get charger                                   Returns status of the battery charger
get checksum                                  Returns the EEPROM CHECKSUM Values
get jumper                                    These are the HEX values derived from the hardware jumpers J4001-J4009
get currentmem                                Returns the currently set memory channel
get dsp                                       Returns status of the Digital Signal Processor
get dw                                        Returns the status of DW, Dual Watch
get eeprom                                    Returns values of an EEPROM memory address
get fasttune                                  Returns the status of Fast Tuning
get home                                      Returns if you are on the HOME frequency or not
get keyer                                     Returns the status of the Keyer (KYR)
get lock                                      Returns status of radio lock
get memlist                                   Returns if the memory is active or inactive
get mtqmb                                     Returns status of MTQMB ON/OFF
get mtune                                     Returns the status of MTUNE MEMORY/MTUNE
get nb                                        Returns status of the Noise Blocker
get pbt                                       Returns status of Pass Band Tuning
get pri                                       Returns status or PRI, Priority Scan
get pwrmtr                                    Returns the function of the power meter PWR / ALC / SWR / MOD
get qmb                                       Returns status of QMB ON/OFF
get scn                                       Returns the Status of SCN, Scanning NO SCAN / SCAN UP / SCAN DOWN
get softcal [console/digest/file filename]    Retrieves software calibration data, if file, use full path
get spl                                       Returns the status of SPL, Split Fewquency
get tuner                                     Returns tuner selection of VFO or MEMORY
get txpower                                   Returns the transmit power level
get vfo                                       Returns which VFO, A or B
get vfoband [A/B]                             Returns what band the VFO is set for
get voltage                                   Returns if the Voltage display is ON or OFF
get vox                                       Returns status of vox

";
                                                }

      if ($helptype eq 'SET') {
print "\nSET Commands:\n
set agc [AUTO/SLOW/FAST/OFF]                           Sets the AGC
set antenna [HF/6M/FMBCB/AIR/VHF/UHF] [FRONT/BACK]     Sets the antenna to front or back for the given bands
set arts [ON/OFF]                                      Turns ARTS ON or OFF
set breakin [ON/OFF]                                   Sets Break-in (BK) ON or OFF
set charger [ON/OFF]                                   Turns the radio charger ON or OFF
set currentmem [(0-200) or M-PL/M-PU]                  Sets the current memory area
set dsp [ON/OFF]                                       Turns DSP on or off if module installed
set dw [ON/OFF]                                        Enables or Disables Dual Watch
set fasttune [ON/OFF]                                  Enables or disables Fast Tuning
set home [ON/OFF]                                      Sets the HOME frequency ON or OFF
set keyer [ON/OFF]                                     Enables or disables the Keyer (KYR) 
set lock [ON/OFF]                                      Enables or disables radio lock
set memarea [1-200/M-PL/M-PU] [ACTIVE/INACTIVE]        Enables or disables given memory area
set mtqmb [ON/OFF]                                     Enables or disables MTQMB
set mtune [MEMORY/MTUNE]                               Sets MTUNE as MEMORY or MTUNE
set nb [ON/OFF]                                        Enables or disables the Noise Blocker
set pbt [ON/OFF]                                       Enables or disables Pass Band Tuning
set pri [ON/OFF]                                       Enables or Disables Priority Scaning
set pwrmtr [PWR/ALC/SWR/MOD]                           Sets the meter to the selected value
set qmb [ON/OFF]                                       Enables or disables QMB
set scn [OFF/UP/DOWN]                                  Sets the Scan Feature OFF / UP / DOWN
set spl [ON/OFF]                                       Enables or disables SPL, Split Frequency
set tuner [VFO/MEMORY]                                 Sets the tuner to VFO or MEMORY
set txpower [HIGH/LOW1/LOW2/LOW3]                      Sets the Transmitter Power
set vfo [A/B]                                          Sets the VFO to A or B
set vfoband [A/B] [BAND]                               Sets the band of the selected VFO
set voltage [ON/OFF]                                   Enables or disables the voltage display
set vox [ON/OFF]                                       Enables or disables VOX

";
                                                }

      if ($helptype eq '_CONFIG') {
print "\nRADIO OPTIONS\n
back                           Back to main directory
history 		       Returns the last 50 commands entered
outputlog                      Shows running log of inputs and cooresponding outputs
restore [####]                 Restores corrupted area of eeprom to default
show                           Show current config options 
exit                           Exit program 

NOTE : Options 6,7,23,35 are configured in the MEMORY Area, Not in CONFIG

[1]  144ars [ON/OFF]                        		Sets 144 ARS ON or OFF
[2]  430ars [ON/OFF]                        		Sets 430 ARS ON or OFF
[3]  9600mic [0-100]                                    Sets the 9600 MIC
[4]  amfmdial [ENABLE/DISABLE]              		Enables or Disables the dial for AM/FM Modes
[5]  ammic [0-100]                                      Sets the AM MIC
[8]  apotime [OFF/1-6]                      		Sets Auto Power Off to OFF or 1-6 hours
[9]  artsmode [OFF/RANGE/ALL]               		Sets the function of ARTS
[10] backlight [OFF/ON/AUTO]                		Sets the function of the Display Backlight
[11] chargetime [6/8/10]                    		Sets the time for the battery charger
[12] beepfreq [440/880]                     		Sets the Beep frequency of the radio
[13] beepvol [1-100]                        		Sets the Beep Volume of the radio
[14] catrate [4800/9600/38400]              		Sets the CAT rate for the Radio
[15] color [BLUE/AMBER]                     		Sets the color of the screen
[16] contrast [1-12]                        		Sets the contrast of the LCD display
[17] cwdelay [10-2500]                      		Sets the CW Delay
[18] cwid [ON/OFF]                          		Sets the CW ID on or off
[19] cwpaddle [NORMAL/REVERSE]              		Sets the CW paddle to Normal or Reverse
[20] cwpitch [300-1000]                     		Sets the pitch of CW in Hz
[21] cwspeed [4-60]                         		Sets the CW speed
[22] cwweight [2.5-4.5]                     		Sets the CW Weight to 1:[value]
[24] digdisp [0] or [-3000 to +3000]                    Sets the DIG DISP
[25] digmic [0-100]                                     Sets the DIG MIC
[26] digmode [RTTY/PSK31-L/PSK31-U/USER-L/USER-U]	Sets the Digital Mode type
[27] digshift [0] or [-3000 to +3000]                   Sets the Digital Shift
[28] emergency [ON/OFF]                     		Sets the Emergency function ON or OFF
[29] fmmic [0-100]                                      Sets the FM MIC
[31] id [CCCCCC]                                        Sets the characters for the CW ID
[32] lockmode [DIAL/FREQ/PANEL]             		Sets the Lock Mode
[33] mainstep [COURSE/FINE]                 		Sets the Main Step
[34] memgroups [ON/OFF]                     		Sets Memory Groups ON or OFF
[36] mickey [ON/OFF]                                    Sets MIC KEY ON or OFF
[37] micscan [ON/OFF]                                   Sets MIC SCAN ON or OFF
[38] opfilter [OFF/SSB/CW]                  		Sets the Optional Filter
[39] pktmic [0-100]                                     Sets the PKT MIC
[40] pktrate [1200/9600]                    		Sets the Packet Rate
[41] resume [OFF/3/5/10]                    		Sets the Resume (scan) function
[43] scope [CONT/CHK]                       		Sets the scope feature
[44] sidetonevol [0-100]                    		Sets the Sidetone Volume
[45] rfknob [RFGAIN/SQUELCH]                		Sets the function of the RF Knob
[46] ssbmic [0-100]                                     Sets SSB MIC
[49] tottime [OFF/1-20]                                 Sets the Time out Timer OFF or 1-20 minutes
[50] voxdelay [100-2500]                    		Sets the Vox Delay in ms
[51] voxgain [1-100]                        		Sets the Vox Gain
[52] extmenu [ON/OFF]                                   Enables or Disables the Extended menu options
[53] dcsinv [TN-RN/TN-RIV/TIV-RN/TIV-RIV]               Sets the DCS Inversion 
[54] rlsbcar [0] or [-300 to +300]                      Sets the R LSB CAR, RX carrier point for LSB
[55] rusbcar [0] or [-300 to +300]                      Sets the R USB CAR, RX carrier point for USB
[56] tlsbcar [0] or [-300 to +300]                      Sets the T LSB CAR, TX carrier point for LSB
[57] tusbcar [0] or [-300 to +300]                      Sets the T USB CAR, TX carrier point for USB

";				 }

      if ($helptype eq '_MEMORY') {
print "\nMEMORY OPTIONS\n
back                           Back to main directory
vfo [A/B/MTQMB/MTUNE]          Go to VFO A, B, QMB or MTQMB area
home                           Go to the Home Memory area
qmb                            Go to the QMB Memory area
mem                            Go to the Saved Memory area  
exit                           Exit programn

";                                }

      if ($helptype eq '_MEMVFO') {
print "\nCHOOSE A BAND FOR $memtype\n
160m  75m  40m  30m  20m  17m  15m  12m  10m  6m  FM BCB  AIR  2m  UHF  PHANTOM         

exit           Go Back one directory

";
                                  }

      if ($helptype eq '_MEMMEMORY') {
print "\nCHOOSE A MEMORY AREA FOR $memtype\n
currentmem [(0-200) or M-PL/M-PU]                  Sets the current memory area
list                                               Lists the Active memory areas
memarea [1-200/M-PL/M-PU] [ACTIVE/INACTIVE]        Enables or disables given memory area

[1 - 200] [M-PL] [M-PU]                            Select a memory area sub directory

exit           Go Back one directory

";
                                     }

      if ($helptype eq '_MEMHOME') {
print "\nCHOOSE A BAND FOR $memtype\n
HF  6m  2m  UHF  

exit           Go Back one directory

";                                 
                                   }


      if ($helptype eq '_VFOMEMOPTS') {
print "\nMEMORY OPTIONS FOR $memtype \[$currentband\]\n

back                   Back to main directory
list                   Shows a list of enabled memory areas
show                   Shows the current stored options
exit                   Exit program

amstep [#]                                      Sets the AM STEP 2.5/5/9/10/12.5/25
att [ON/OFF]                                    Turns att on or off
clarifier [ON/OFF]                              Enables or disables the clarifier
claroffset  [-9.99 to +9.99]                    Sets the offset and polarity of the clarifier
ctcsstone [###]                                 Sets the CTCSS Tone
dcscode [###]                                   Sets the DCS Code
encoder [OFF/TONE/TONETSQ/DCS]                  Sets The Encoder Type
fmstep [#]                                      Sets the FM STEP 5/6.25/10/12.5/15/20/25/50
ipo [ON/OFF]                                    Turns IPO on or off
mode [MODE]                                     Sets the Mode                                     
narcwdig [ON/OFF]                               Sets the Narrow filter for CW and DIG
narfm [ON/OFF]                                  Sets the Narrow filter for FM
rptoffset [SIMPLEX/MINUS/PLUS/NON-STANDARD]     Sets the Repeater offset
shift [0-99.99]                                 Sets the repeater offset frequency
rxfreq [12.346.67]                              Sets the Receive frequency
ssbstep [1.0/2.5/5.0]                           Sets the SSB STEP in Khz

";                                    }


      if ($helptype eq '_MEMORYOPTS') {
print "\nMEMORY OPTIONS FOR $memtype \[$currentband\]\n

back                                               Back to main directory
currentmem [(0-200) or M-PL/M-PU]                  Sets the current memory area
list 		                                   Shows a list of enabled memory areas	
memarea [1-200/M-PL/M-PU] [ACTIVE/INACTIVE]        Enables or disables given memory area
show                                               Shows the current stored options
exit                                               Exit program

amstep [#]                                      Sets the AM STEP 2.5/5/9/10/12.5/25
att [ON/OFF]                                    Turns att on or off
clarifier [ON/OFF]                              Enables or disables the clarifier
claroffset [-9.99 to +9.99]                     Sets the offset and polarity of the clarifier
ctcsstone [###]                                 Sets the CTCSS Tone
dcscode [###]                                   Sets the DCS Code
display [LABEL/FREQUENCY]                       Sets the radio display to show the label or frequency
encoder [OFF/TONE/TONETSQ/DCS]                  Sets The Encoder Type
fmstep [#]                                      Sets the FM STEP 5/6.25/10/12.5/15/20/25/50
ipo [ON/OFF]                                    Turns IPO on or off
label [LLLLLLLL]                                Sets the Label of the memory location 8 char. max
skip [YES/NO]                                   Sets if memory area is skipped during scanning or not
mode [MODE]                                     Sets the Mode
narcwdig [ON/OFF]                               Sets the Narrow filter for CW and DIG
narfm [ON/OFF]                                  Sets the Narrow filter for FM
rptoffset [SIMPLEX/MINUS/PLUS/NON-STANDARD]     Sets the Repeater offset
shift [0-99.99]                                 Sets the repeater offset frequency
rxfreq [12.346.67]                              Sets the Receive frequency
ssbstep [1.0/2.5/5.0]                           Sets the SSB STEP in Khz

";                                    }


        if (($helptype) && ($helptype ne '_MEMORY') && ($helptype ne '_VFOMEMOPTS')  && ($helptype ne '_MEMVFO')  && ($helptype ne '_CONFIG') && 
	($helptype ne 'CAT') && ($helptype ne 'GET') && ($helptype ne 'SET') && ($helptype ne 'SYSTEM') && ($helptype ne '_MEMORYOPTS') &&
	($helptype ne '_MEMHOME') && ($helptype ne '_MEMMEMORY')){print "SYNTAX ERROR\n";}
	      }

############################################ STARTUPCHECK

sub startUpcheck{
	if (-e 'config/radiolist.cfg') {
	        my ($cfg_line) =@_;
		@radiodata = undef;
		$totalradios = 0;
        	open(MCONFIGFILE, 'config/radiolist.cfg') or die("Unable to open file");
        	@mconfigdata = <MCONFIGFILE>;
        	foreach $cfg_line (@mconfigdata)
                	{
                	if (index($cfg_line,"#")==0) { next; }
                my @ln=split(" ",$cfg_line);
		my $cfgfile = join('','config/',"$ln[1]",'.cfg');
		my $cnffile = join('','config/',"$ln[1]",'.cnf');
		my $calfile = join('','config/',"$ln[1]",'.cal');
                my $memfile = join('','config/',"$ln[1]",'.mem');
		our $configfile = $cfgfile;
                $radiodata["$ln[0]"]{'number'} = "$ln[0]";
		$radiodata["$ln[0]"]{'name'} = "$ln[1]";
                $radiodata["$ln[0]"]{'default'} = "$ln[2]";
                $radiodata["$ln[0]"]{'radioconfigfile'} = "$cnffile";
		$radiodata["$ln[0]"]{'config'} = "$cfgfile";
                $radiodata["$ln[0]"]{'calibration'} = "$calfile";
                $radiodata["$ln[0]"]{'memory'} = "$memfile";
		$radiodata["$ln[0]"]{'baudrate'} = readConfigfile('BAUDRATE');
                $radiodata["$ln[0]"]{'serialport'} = readConfigfile('SERIALPORT');
                $radiodata["$ln[0]"]{'lockfile'} = readConfigfile('LOCKFILE');
                $radiodata["$ln[0]"]{'digest'} = readConfigfile('DIGEST');
                $radiodata["$ln[0]"]{'config'} = readConfigfile('CONFIG');
                $totalradios++;
                        }
        close MCONFIGFILE;
	loadRadio();
			        }
	else {
                createConfig();
	     }
                }

############################################ READCONFIGFILE

sub readConfigfile {
	my ($cfg_line) =@_;
	open(CFGFILE, "$configfile") or die("Unable to open file");
	@configdata = <CFGFILE>;
	our $cfg_value = "$cfg_line";
	foreach $cfg_line (@configdata)
		{
		if (index($cfg_line,"#")==0) { next; } 
		my @ln=split("=",$cfg_line);
		if ($ln[0] =~ /$cfg_value/i) {
			chomp $ln[1];
return $ln[1];
					     }
		}
	close CFGFILE;
		   }

############################################ CREATECONFIG

sub createConfig {
        system("clear");
        print "***FT817-OS version $VERSION***\n";
        print "Copyright Jordan Rubin [KJ4TLB] 2014\n\n";
	print "Enter the name of your serial device. i.e. /dev/ttyUSB0\n\n";
do {
		print "Serial Port:> ";
                $serialport = <>;
                chomp($serialport);
   } while (!$serialport);

        print "Would you like to name the radio connected to [$serialport]? Press enter for default [FT817]\n\n";
do {
                print "Radio Name:> ";
                $radioname = <>;
                chomp($radioname);
                if (!$radioname){$radioname = 'FT817';}
   } while (!$radioname);

        print "$radioname\@[$serialport] Will be the default rig on startup\n\n";
	$default = 'Y'; 	

                print "\nEnter the Baud Rate for your FT817 CAT RATE on Menu item 14 [4800/9600/38400]\n\n";
do {
	        print "Baud:> ";
                $baudrate = <>;
		chomp($baudrate);
		if ($baudrate != '38400' && ($baudrate != '4800') && ($baudrate != '9600')){$baudrate = undef;}
   } while (!$baudrate); 

        print "\nDo you wish to use a lock file for your serial port using /var/lock/$radioname (RECOMMENDED) Y/N\n\n";
do {
        print "Lock File:> ";
                $lockfile = <>;
		chomp($lockfile);
		$lockfile = lc($lockfile);
		if ($lockfile ne 'y' && ($lockfile ne 'n')) {$lockfile = undef;}
   } while (!$lockfile);
	if ($lockfile eq 'y'){
		$lockfile = "\/var\/lock/$radioname";
			     }
	print "Here are your settings:\n";
	printf "%-11s %-15s\n", "NAME:", "$radioname";
	printf "%-11s %-15s\n", "SERIALPORT:", "$serialport";
        printf "%-11s %-15s\n", "DEFAULT:", "$default";
	printf "%-11s %-15s\n", "BAUDRATE:", "$baudrate";
	printf "%-11s %-15s\n", "LOCKFILE:", "$lockfile";
do {
	print "\nAre they correct? [y/n] :> ";
		$prompt = <>;
                chomp($prompt);	
		if ($prompt ne 'y' && ($prompt ne 'n')) {$prompt = undef;}
   } while (!$prompt);

		if ($prompt eq 'n'){createConfig();}
	print "\nAn attempt will now be made to connect to $radioname\@$serialport with this configuration\nSerial should be connected with power on.....\n\n";
		if ($default eq 'Y'){$activeradio = $radioname;}

		our $activeradio = new Ham::Device::FT817COMM  (
        	serialport => "$serialport",
        	baud => "$baudrate",
        	lockfile => "$lockfile"
  		                                               );

	my $directory = "config";
	if (-d "$directory") {
		#blank
			     }
	else {
	unless(mkdir $directory) {
		die "Unable to create $directory";
				 }
	chmod(0644, $directory) or die "Couldn't chmod $directory: $!";
	     }
		my $test = $activeradio->catgetMode();
		my $times;
		my @digest;
                $softcalfile = join('',"$radioname",'.cal');
                $activeradio->setVerbose(0);
		if ($test){print "\nConnection with $serialport\@$radioname sucessfull!!!!!\n\n";
		print "Backing up calibration settings: ";
                if (-e "config/$softcalfile") {
			print "----> SKIPPING : Calibration file /config/$softcalfile exists already!!!!\n";
				     }
		else {
			$activeradio->getSoftcal('FILE', "config/$softcalfile");
			print "       ----> OK\n";
		     }
		print "Generating 5 Pass Calibration Hash: ";

  for( $times = 0; $times != 5; $times = $times + 1 ){
                $output = $activeradio->getSoftcal('DIGEST');
		push (@digest, "$output");
						     }
		if ($digest['0'] eq $digest['1'] && $digest['0'] eq $digest['2'] && $digest['0'] eq $digest['3'] && $digest['0'] eq $digest['4']) {
			our $digest = $digest['0'];
			print "    ----> OK\n";
						      												  }
		else {
			print "   ----> ERROR!!! Check your cabling and restart this program\n";
			$activeradio->closePort();
		die;
		     }

		print "Retrieving Software Jumper settings: ";
		our $jumpconfig = $activeradio->getConfig();
		print "   ----> OK\n";
		print "Config files being created:  ";

        open  MCONFIGFILE , ">>", 'config/radiolist.cfg' or print"Can't open config/radiolist.cfg error\n";
        print MCONFIGFILE "\############ FT817 Radio List File\n";
        print MCONFIGFILE "\############ Generated by createConfig on $localtime\n#\n#\n#\n";
        print MCONFIGFILE "0 $radioname Y\n";
        close MCONFIGFILE;

        $configfile = join('',"$radioname",'.cfg');
        open  RCONFIGFILE , ">>", "config/$configfile" or print"Can't open config/$configfile. error\n";
        print RCONFIGFILE "\############ FT817 os configuration file\n";
        print RCONFIGFILE "\############ Generated by createConfig on $localtime\n#\n#\n#\n";
        print RCONFIGFILE "NAME=$radioname\n";
        print RCONFIGFILE "DEFAULT=$default\n";
        print RCONFIGFILE "SERIALPORT=$serialport\n";
	print RCONFIGFILE "BAUDRATE=$baudrate\n";
        print RCONFIGFILE "LOCKFILE=$lockfile\n";
	print RCONFIGFILE "CONFIG=$jumpconfig\n";
	print RCONFIGFILE "DIGEST=$digest['1']\n";
		close RCONFIGFILE;
		print "           ----> OK\n";	
        $memoryfile = join('',"$radioname",'.mem');
 	print "\nBacking up $radioname memory: ";
                if (-e "config/$memoryfile") {
                        print "----> SKIPPING : Memory file config/$memoryfile exists already!!!!\n";
                                     }
                else {
                        $activeradio->saveMemory("config/$memoryfile");
                     }
        $radioconfigfile = join('',"$radioname",'.cnf');
        print "Backing up $radioname config: ";
                if (-e "config/$radioconfigfile") {
                        print "----> SKIPPING : Config file config/$radioconfigfile exists already!!!!\n";
                                     }
                else {
                        $activeradio->saveConfig("config/$radioconfigfile");
                     }

        $activeradio->setVerbose(0);
	print"\n\nRe-starting OS.........\n\n";
	$activeradio->closePort();
	sleep 1;
	print "LOAD \"\*\"\,8\,1\n";
	sleep 1;
	print "SEARCHING FOR \*\n";
	sleep 1;
	print "LOADING\n";
	sleep 1;
	print "READY\n";
	sleep 1;
	print "RUN\n";
startUpcheck();
return 0;
			  }
		else {print "\nConnection failed";}
	die;
		 }

############################################ BANNER  

sub banner {
	system("clear");
	print "***FT817-OS version $VERSION***\nRelease FT817COMM($version)\n";
	print "Copyright Jordan Rubin [KJ4TLB] 2014, Perl Artistic license II\n";
	print "Connected on $serialport at $baudrate bps\n";
	if($lockfile){print"Locked port at $lockfile\n";}
	print "\nType 'help' for commands\n\n";
           }

############################################ PROMPT

sub prompt {
        my ($size) = @_;
	if ($write){our $prompt = "\[$radioname\]\@$serialport\/$currentdir:\# ";}
	else {our $prompt = "\[$radioname\]\@$serialport\/$currentdir:\$ ";}
	print "$prompt";
	$input = <>;
	chomp $input;
	if ($input ne 'history' && $input ne 'help' && $input ne 'outputlog'){
		push (@history, $input);
						                             }
	$size = @history;
	if ($size -1 == "$MAX_HISTORY"){shift @history;}
	return $input;
            }

############################################ HISTORY

sub history {
       my ($size, $commandline, $number) = @_;
        $size = @history;
	$number = 1;
	print "\nLast $MAX_HISTORY commands from oldest to newest\n";
        foreach $commandline (@history) {
	print "$number: $commandline\n";$number++;
				 	}
	print "\n";
return 0;
	    }

############################################ OUTPUTLOG

sub outputlog {
        my ($size, $number, $role, $label) = @_;
	$size = @outputs;
	$number = 1;
	$label = 1;
	print "\nOUTPUT LOG\n\n";
	printf "%-5s %-40s %-11s\n", '#', 'COMMAND', 'OUTPUT';
	print "_____________________________________________________\n";
        foreach $number (@outputs)    {

        	for $role ( keys %$number ) {
			printf "%-5s %-40s %-11s\n", "$label", "$role", "$number->{$role}";
					    }
	$label++;
                                      }
              }

############################################ TESTCONFIG

sub testConfig {
		print "CHECKING RADIO CONFIG: ";
                my $jumpconfig = $FT817->getConfig();
		if ($jumpconfig eq $savedconfig){print "CONFIG [OK]\n";
return 0;
						}
		else {
		print "ERROR\nThe radio hardware config of $jumpconfig does not match $savedconfig\n"; 
return 1;	     }
               }

########################################### TESTCAL

sub testCal {
                print "CHECKING SOFTWARE CALIBRATION: ";
                my $mydigest = $FT817->getSoftcal('DIGEST');
                if ($mydigest eq $saveddigest){print "CALIBRATION [OK]\n";
return 0;
                                                }
                else {
                print "ERROR\nThe radio calibration ---->$digest<---- does not match the backup ---->$saveddigest<---- !!!!!\nCheck your saved copy against the one on the rig.\n";
return 1;            }
	    }

########################################### MEMORYLIST

sub memoryList {
	my $test = $FT817->getActivelist;
return 0;
	       }



########################################### REBUILDSOFTCAL

sub rebuildSoftcal {
                my $value2 = shift;
        	if (!$value2){$value2 = $softcalfile;}
		if($value2 eq $softcalfile){print "You used the default filename [$value2]. This will overwrite your software calibration.\n";}
                print "This is going to re-write your entire software calibration from backup!!! Are you absolutely sure [Y/N]?\nANSWER: ";
                my $question = <>;
                chomp $question;
                $question = lc($question);
                if ($question eq 'y'){$output = $FT817->rebuildSoftcal("$value2");}
return 0;
                   }

########################################### SAVEMEMORY

sub saveMemory {
        my $value2 = shift;
        if (!$value2){$value2 = $memoryfile;}
        if($value2 eq $memoryfile){print "You used the default filename [$value2]. This will overwrite your backup memory file.\n";}
                print "Backing up memory to $value2. Are you sure [Y/N]? ";
                my $question = <>;
                chomp $question;
                $question = lc($question);
                if ($question eq 'y'){$output = $FT817->saveMemory("$value2");}
return 0;
               }

########################################### LOADCONFIG

sub loadConfig {
        my $value2 = shift;
       if (!$value2){$value2 = $radioconfigfile;}
                print "This will load the radio with the configuration from $value2. Are you sure [Y/N]? ";
                my $question = <>;
                chomp $question;
                $question = lc($question);
                if ($question eq 'y'){$output = $FT817->loadConfig("$value2");}
return 0;
               }

########################################### LOADMEMORY

sub loadMemory {
        my $value2 = shift;
       if (!$value2){$value2 = $memoryfile;}
                print "This will load the radio with the memory from $value2. Are you sure [Y/N]? ";
                my $question = <>;
                chomp $question;
                $question = lc($question);
                if ($question eq 'y'){$output = $FT817->loadMemory("$value2");}
return 0;
               }

########################################### SAVECONFIG

sub saveConfig {
        my $value2 = shift;
	if (!$value2){$value2 = $radioconfigfile;}
        if($value2 eq $radioconfigfile){print "You used the default filename [$value2]. This will overwrite your backup configuration.\n";}
                print "Backing up configuration to $value2. Are you sure [Y/N]? ";
                my $question = <>;
                chomp $question;
                $question = lc($question);
                if ($question eq 'y'){$output = $FT817->saveConfig("$value2");}
return 0;
               }

############################################ CONFIGLIST

sub configList {
                $FT817->setVerbose(0);
                my $b9600mic = $FT817->get9600mic();
                my $amfmdial = $FT817->getAmfmdial();
                my $ammic = $FT817->getAmmic();
                my $apotime = $FT817->getApotime();
                my $ars144 = $FT817->getArs144();
		my $ars430 = $FT817->getArs430();
		my $artsbeep = $FT817->getArtsmode();
                my $backlight = $FT817->getBacklight();
                my $chargetime = $FT817->getChargetime();
		my $beepfreq = $FT817->getBeepfreq();
                my $beepvol = $FT817->getBeepvol();
		my $catrate = $FT817->getCatrate();
		my $color = $FT817->getColor();
                my $contrast = $FT817->getContrast();
		my $cwdelay = $FT817->getCwdelay();
                my $cwid = $FT817->getCwid();
		my $cwpaddle = $FT817->getCwpaddle();
		my $cwpitch = $FT817->getCwpitch();
                my $cwspeed = $FT817->getCwspeed();
		my $cwweight = $FT817->getCwweight();
		my $dcsinv = $FT817->getDcsinv();
                my $digdisp = $FT817->getDigdisp();
                my $digmic = $FT817->getDigmic();
                my $digmode = $FT817->getDigmode();
                my $digshift = $FT817->getDigshift();
		my $emergency = $FT817->getEmergency();
                my $extmenu = $FT817->getExtmenu();
                my $fmmic = $FT817->getFmmic();
                my $id = $FT817->getId();
                my $micscan = $FT817->getMicscan();
                my $tottime = $FT817->getTottime();
                my $lockmode = $FT817->getLockmode();
		my $mainstep = $FT817->getMainstep();
                my $memgroup = $FT817->getMemgroup();
                my $mickey = $FT817->getMickey();
		my $opfilter = $FT817->getOpfilter();
                my $pktmic = $FT817->getPktmic();
                my $pktrate = $FT817->getPktrate();
                my $rlsbcar = $FT817->getRlsbcar();
                my $rusbcar = $FT817->getRusbcar();
                my $resumescan = $FT817->getResumescan();
                my $scope = $FT817->getScope();
                my $sidetonevol = $FT817->getSidetonevol();
                my $rfknob = $FT817->getRfknob();
                my $ssbmic = $FT817->getSsbmic();
                my $tlsbcar = $FT817->getTlsbcar();
                my $tusbcar = $FT817->getTusbcar();
                my $voxdelay = $FT817->getVoxdelay();
                my $voxgain = $FT817->getVoxgain();

                print "\nCURRENT CONFIGURATION\n";
		print "---------------------\n\n";
                printf "%-05s%-15s%-11s%-11s\n", '#1:','144 ARS','------->',"$ars144";
                printf "%-05s%-15s%-11s%-11s\n", '#2:','430 ARS','------->',"$ars430"; 
                printf "%-05s%-15s%-11s%-11s\n", '#3:','9600 MIC','------->',"$b9600mic"; 
                printf "%-05s%-15s%-11s%-11s\n", '#4:','AM/FM DIAL','------->',"$amfmdial"; 
                printf "%-05s%-15s%-11s%-11s\n", '#5:','AM MIC','------->',"$ammic"; 
		printf "%-05s%-15s%-11s%-11s\n", '#8:','APO TIME','------->',"$apotime";
		printf "%-05s%-15s%-11s%-11s\n", '#9:','ARTS BEEP','------->',"$artsbeep";
                printf "%-05s%-15s%-11s%-11s\n", '#10:','BACKLIGHT','------->',"$backlight";
                printf "%-05s%-15s%-11s%-11s\n", '#11:','BATT-CHG','------->',"$chargetime";
                printf "%-05s%-15s%-11s%-11s\n", '#12:','BEEP FREQ','------->',"$beepfreq";
                printf "%-05s%-15s%-11s%-11s\n", '#13:','BEEP VOL','------->',"$beepvol";
                printf "%-05s%-15s%-11s%-11s\n", '#14:','CAT RATE','------->',"$catrate";
                printf "%-05s%-15s%-11s%-11s\n", '#15:','COLOR','------->',"$color";
                printf "%-05s%-15s%-11s%-11s\n", '#16:','CONTRAST','------->',"$contrast";
                printf "%-05s%-15s%-11s%-11s\n", '#17:','CW DELAY','------->',"$cwdelay";
		printf "%-05s%-15s%-11s%-11s\n", '#18:','CW ID','------->',"$cwid";
                printf "%-05s%-15s%-11s%-11s\n", '#19:','CW PADDDLE','------->',"$cwpaddle";
                printf "%-05s%-15s%-11s%-11s\n", '#20:','CW PITCH','------->',"$cwpitch";
		printf "%-05s%-15s%-11s%-11s\n", '#21:','CW SPEED','------->',"$cwspeed";
                printf "%-05s%-15s%-11s%-11s\n", '#22:','CW WEIGHT','------->',"$cwweight";
                printf "%-05s%-15s%-11s%-11s\n", '#24:','DIG DISP','------->',"$digdisp";
                printf "%-05s%-15s%-11s%-11s\n", '#25:','DIG MIC','------->',"$digmic";
                printf "%-05s%-15s%-11s%-11s\n", '#26:','DIG MODE','------->',"$digmode";
                printf "%-05s%-15s%-11s%-11s\n", '#27:','DIG SHIFT','------->',"$digshift";
                printf "%-05s%-15s%-11s%-11s\n", '#28:','EMERGENCY','------->',"$emergency";
                printf "%-05s%-15s%-11s%-11s\n", '#29:','FM MIC','------->',"$fmmic";
                printf "%-05s%-15s%-11s%-11s\n", '#31:','ID','------->',"$id";
                printf "%-05s%-15s%-11s%-11s\n", '#32:','LOCK MODE','------->',"$lockmode";
		printf "%-05s%-15s%-11s%-11s\n", '#33:','MAIN STEP','------->',"$mainstep";
                printf "%-05s%-15s%-11s%-11s\n", '#34:','MEM GROUPS','------->',"$memgroup";
                printf "%-05s%-15s%-11s%-11s\n", '#36:','MIC KEY','------->',"$mickey";
                printf "%-05s%-15s%-11s%-11s\n", '#37:','MIC SCAN','------->',"$micscan";
                printf "%-05s%-15s%-11s%-11s\n", '#38:','OP FILTER','------->',"$opfilter";
                printf "%-05s%-15s%-11s%-11s\n", '#39:','PKT MIC','------->',"$pktmic";
		printf "%-05s%-15s%-11s%-11s\n", '#40:','PKT RATE','------->',"$pktrate";
                printf "%-05s%-15s%-11s%-11s\n", '#41:','RESUME','------->',"$resumescan";
                printf "%-05s%-15s%-11s%-11s\n", '#43:','SCOPE','------->',"$scope";
                printf "%-05s%-15s%-11s%-11s\n", '#44:','SIDETONE VOL','------->',"$sidetonevol";
		printf "%-05s%-15s%-11s%-11s\n", '#45:','SQL/RF-G','------->',"$rfknob";
                printf "%-05s%-15s%-11s%-11s\n", '#46:','SSB MIC','------->',"$ssbmic";
		printf "%-05s%-15s%-11s%-11s\n", '#49:','TOT TIME','------->',"$tottime";
                printf "%-05s%-15s%-11s%-11s\n", '#50:','VOX DELAY','------->',"$voxdelay";
                printf "%-05s%-15s%-11s%-11s\n", '#51:','VOX GAIN','------->',"$voxgain";
                printf "%-05s%-15s%-11s%-11s\n", '#52:','EXT MENU','------->',"$extmenu";
                printf "%-05s%-15s%-11s%-11s\n", '#53:','DCS INV','------->',"$dcsinv";
                printf "%-05s%-15s%-11s%-11s\n", '#54:','R LSB CAR','------->',"$rlsbcar";
                printf "%-05s%-15s%-11s%-11s\n", '#55:','R USB CAR','------->',"$rusbcar";
                printf "%-05s%-15s%-11s%-11s\n", '#56:','T LSB CAR','------->',"$tlsbcar";
                printf "%-05s%-15s%-11s%-11s\n", '#57:','T USB CAR','------->',"$tusbcar";
                print "\n";
                $FT817->setVerbose(1);
return 0;
	       }


############################################ SHOWMEMORY

sub showMemory {
        my $type = shift;
	my $subtype = shift;
        $type = uc($type);
        $subtype = uc($subtype);
                $FT817->setVerbose(0);
	if ($type eq'QMB'){print "\nMEMORY\:$type CONFIG\n";}
        else {print "\nMEMORY\:$type\($subtype\) CONFIG\n";}
                print "________________\n\n";
                my $ready = $FT817->readMemory("$type","$subtype",'READY');
                my $memmode = $FT817->readMemory("$type","$subtype",'MODE');
		my $hfvhf = $FT817->readMemory("$type","$subtype",'HFVHF');
                my $tag = $FT817->readMemory("$type","$subtype",'TAG');
                my $freqrange = $FT817->readMemory("$type","$subtype",'FREQRANGE');
                my $narfm = $FT817->readMemory("$type","$subtype",'NARFM');
                my $narcwdig = $FT817->readMemory("$type","$subtype",'NARCWDIG');
                my $uhf = $FT817->readMemory("$type","$subtype",'UHF');
                my $rptoffset = $FT817->readMemory("$type","$subtype",'RPTOFFSET');
                my $tonedcs = $FT817->readMemory("$type","$subtype",'TONEDCS');
                my $att = $FT817->readMemory("$type","$subtype",'ATT');
                my $ipo = $FT817->readMemory("$type","$subtype",'IPO');
                my $memskip = $FT817->readMemory("$type","$subtype",'MEMSKIP');
                my $fmstep = $FT817->readMemory("$type","$subtype",'FMSTEP');
                my $amstep = $FT817->readMemory("$type","$subtype",'AMSTEP');
                my $ssbstep = $FT817->readMemory("$type","$subtype",'SSBSTEP');
                my $ctcsstone = $FT817->readMemory("$type","$subtype",'CTCSSTONE');
                my $dcscode = $FT817->readMemory("$type","$subtype",'DCSCODE');
                my $claronoff = $FT817->readMemory("$type","$subtype",'CLARIFIER');
                my $claroffset = $FT817->readMemory("$type","$subtype",'CLAROFFSET');
                my $rxfreq = $FT817->readMemory("$type","$subtype",'RXFREQ');
                my $rptoffsetfreq = $FT817->readMemory("$type","$subtype",'RPTOFFSETFREQ');
                my $label = $FT817->readMemory("$type","$subtype",'LABEL');

                $FT817->setVerbose(1);
                printf "%-11s%-11s%-11s\n", 'READY','----->',"$ready";
                printf "%-11s%-11s%-11s\n", 'MODE','----->',"$memmode";
                printf "%-11s%-11s%-11s\n", 'HF/VHF','----->',"$hfvhf";
                printf "%-11s%-11s%-11s\n", 'DISPLAY','----->',"$tag";
                printf "%-11s%-11s%-11s\n", 'FREQ RANGE','----->',"$freqrange";
                printf "%-11s%-11s%-11s\n", 'NAR FM','----->',"$narfm";
                printf "%-11s%-11s%-11s\n", 'NAR CW/DIG','----->',"$narcwdig";
                printf "%-11s%-11s%-11s\n", 'UHF','----->',"$uhf";
                printf "%-11s%-11s%-11s\n", 'RPT OFFSET','----->',"$rptoffset";
                printf "%-11s%-11s%-11s\n", 'ENCODER','----->',"$tonedcs";
                printf "%-11s%-11s%-11s\n", 'ATT','----->',"$att";
                printf "%-11s%-11s%-11s\n", 'IPO','----->',"$ipo";
                printf "%-11s%-11s%-11s\n", 'SKIP','----->',"$memskip";
                printf "%-11s%-11s%-11s\n", 'FM-STEP','----->',"$fmstep";
                printf "%-11s%-11s%-11s\n", 'AM-STEP','----->',"$amstep";
                printf "%-11s%-11s%-11s\n", 'SSB-STEP','----->',"$ssbstep";
                printf "%-11s%-11s%-11s\n", 'CTCSS TONE','----->',"$ctcsstone";
                printf "%-11s%-11s%-11s\n", 'DCS CODE','----->',"$dcscode";
                printf "%-11s%-11s%-11s\n", 'CLARIFIER','----->',"$claronoff";
                printf "%-11s%-11s%-11s\n", 'CLAR OFFSET','----->',"$claroffset Khz";
                printf "%-11s%-11s%-11s\n", 'RX FREQ','----->',"$rxfreq Mhz";
                printf "%-11s%-11s%-11s\n", 'SHIFT','----->',"$rptoffsetfreq Mhz";
                printf "%-11s%-11s%-11s\n", 'LABEL','----->',"$label";
                print "\n";
return 0;
               }

############################################ SHOWMEMVFO

sub showMemvfo {
        my $vfo = shift;
	my $vfoband = shift;
        $vfo = uc($vfo);
	$vfoband = uc($vfoband);
                $FT817->quietToggle();
                $FT817->quietToggle();
                $FT817->setVerbose(0);
                print "\nVFO\:$vfo\($vfoband\) CONFIG\n";
                print "________________\n\n";
                my $memmode = $FT817->readMemvfo("$vfo", "$vfoband", 'MODE');
                my $narfm = $FT817->readMemvfo("$vfo", "$vfoband", 'NARFM');
                my $narcwdig = $FT817->readMemvfo("$vfo", "$vfoband", 'NARCWDIG');
                my $rptoffset = $FT817->readMemvfo("$vfo", "$vfoband", 'RPTOFFSET');
                my $tonedcs = $FT817->readMemvfo("$vfo", "$vfoband", 'TONEDCS');
                my $att = $FT817->readMemvfo("$vfo", "$vfoband", 'ATT');
                my $ipo = $FT817->readMemvfo("$vfo", "$vfoband", 'IPO');
                my $fmstep = $FT817->readMemvfo("$vfo", "$vfoband", 'FMSTEP');
                my $amstep = $FT817->readMemvfo("$vfo", "$vfoband", 'AMSTEP');
                my $ssbstep = $FT817->readMemvfo("$vfo", "$vfoband", 'SSBSTEP');
                my $ctcsstone = $FT817->readMemvfo("$vfo", "$vfoband", 'CTCSSTONE');
                my $dcscode = $FT817->readMemvfo("$vfo", "$vfoband", 'DCSCODE');
                my $claronoff = $FT817->readMemvfo("$vfo", "$vfoband", 'CLARIFIER');
		my $claroffset = $FT817->readMemvfo("$vfo", "$vfoband", 'CLAROFFSET');
                my $rxfreq = $FT817->readMemvfo("$vfo", "$vfoband", 'RXFREQ');
                my $rptoffsetfreq = $FT817->readMemvfo("$vfo", "$vfoband", 'RPTOFFSETFREQ');
                $FT817->setVerbose(1);
                printf "%-11s%-11s%-11s\n", 'MODE','----->',"$memmode";
                printf "%-11s%-11s%-11s\n", 'NAR FM','----->',"$narfm";
                printf "%-11s%-11s%-11s\n", 'NAR CW/DIG','----->',"$narcwdig";
                printf "%-11s%-11s%-11s\n", 'RPT OFFSET','----->',"$rptoffset";
                printf "%-11s%-11s%-11s\n", 'ENCODER','----->',"$tonedcs";
                printf "%-11s%-11s%-11s\n", 'ATT','----->',"$att";
                printf "%-11s%-11s%-11s\n", 'IPO','----->',"$ipo";
                printf "%-11s%-11s%-11s\n", 'FM-STEP','----->',"$fmstep Khz";
                printf "%-11s%-11s%-11s\n", 'AM-STEP','----->',"$amstep Khz";
                printf "%-11s%-11s%-11s\n", 'SSB-STEP','----->',"$ssbstep Khz";
                printf "%-11s%-11s%-11s\n", 'CTCSS TONE','----->',"$ctcsstone Hz";
                printf "%-11s%-11s%-11s\n", 'DCS CODE','----->',"$dcscode";
                printf "%-11s%-11s%-11s\n", 'CLARIFIER','----->',"$claronoff";
                printf "%-11s%-11s%-11s\n", 'CLAR OFFSET','----->',"$claroffset Khz";
                printf "%-11s%-11s%-11s\n", 'RX FREQ','----->',"$rxfreq Mhz";
                printf "%-11s%-11s%-11s\n", 'SHIFT','----->',"$rptoffsetfreq Mhz";
                print "\n";
return 0;
               }

############################################ SHOWSTATUS

sub showStatus {
       my ($frequency,$vfo,$vfoband,$mode,$tuner,$home,$agc,$dsp,$nb,$txpower,$vox,$memmode,$narfm,$narcwdig,$rptoffset,$tonedcs,$att,$ipo,$fmstep,$amstep,$ssbstep,
	    $ctcsstone,$dcscode,$claronoff,$currenttuner) = @_;
		$FT817->setVerbose(0);
		$currenttuner = $FT817->getTuner(); 
		print "\nFT817 STATUS\n";
		print "____________\n";
	if ($currenttuner eq 'VFO') {
		$FT817->quietToggle();
                $FT817->quietToggle();
		$FT817->setVerbose(0);
		$frequency = $FT817->catgetFrequency("1");
		$vfo = $FT817->getVfo();
                $vfoband = $FT817->getVfoband("$vfo");
		$mode = $FT817->catgetMode();
		$tuner = $FT817->getTuner();
		$home = $FT817->getHome();
		$agc = $FT817->getAgc();
		$dsp = $FT817->getDsp();
		$nb = $FT817->getNb();
		$txpower = $FT817->getTxpower();
                $vox = $FT817->getVox();
                $memmode = $FT817->readMemvfo("$vfo", "$vfoband", 'MODE');
		$narfm = $FT817->readMemvfo("$vfo", "$vfoband", 'NARFM');
                $narcwdig = $FT817->readMemvfo("$vfo", "$vfoband", 'NARCWDIG');
		$rptoffset = $FT817->readMemvfo("$vfo", "$vfoband", 'RPTOFFSET');
		$tonedcs = $FT817->readMemvfo("$vfo", "$vfoband", 'TONEDCS');
		$att = $FT817->readMemvfo("$vfo", "$vfoband", 'ATT');
                $ipo = $FT817->readMemvfo("$vfo", "$vfoband", 'IPO');
                $fmstep = $FT817->readMemvfo("$vfo", "$vfoband", 'FMSTEP');
                $amstep = $FT817->readMemvfo("$vfo", "$vfoband", 'AMSTEP');
                $ssbstep = $FT817->readMemvfo("$vfo", "$vfoband", 'SSBSTEP');
                $ctcsstone = $FT817->readMemvfo("$vfo", "$vfoband", 'CTCSSTONE');
		$dcscode = $FT817->readMemvfo("$vfo", "$vfoband", 'DCSCODE');
                $claronoff = $FT817->readMemvfo("$vfo", "$vfoband", 'CLARIFIER');
                print "VFO[$vfo] - $frequency($mode) BAND [$vfoband]\n\n";
                                      }

        if ($currenttuner eq 'MEMORY') {
		my $num = $FT817->getCurrentmem();
                $FT817->quietTunetoggle();
                $FT817->quietTunetoggle();
                $FT817->setVerbose(0);
                $mode = $FT817->catgetMode();
                $tuner = $FT817->getTuner();
                $home = $FT817->getHome();
                $agc = $FT817->getAgc();
                $dsp = $FT817->getDsp();
                $nb = $FT817->getNb();
                $txpower = $FT817->getTxpower();
                $vox = $FT817->getVox();
                $frequency = $FT817->readMemory('MEM', "$num", 'RXFREQ');
                $memmode = $FT817->readMemory('MEM', "$num", 'MODE');
                $narfm = $FT817->readMemory('MEM', "$num", 'NARFM');
                $narcwdig = $FT817->readMemory('MEM', "$num", 'NARCWDIG');
                $rptoffset = $FT817->readMemory('MEM', "$num", 'RPTOFFSET');
                $tonedcs = $FT817->readMemory('MEM', "$num", 'TONEDCS');
                $att = $FT817->readMemory('MEM', "$num", 'ATT');
                $ipo = $FT817->readMemory('MEM', "$num", 'IPO');
                $fmstep = $FT817->readMemory('MEM', "$num", 'FMSTEP');
                $amstep = $FT817->readMemory('MEM', "$num", 'AMSTEP');
                $ssbstep = $FT817->readMemory('MEM', "$num", 'SSBSTEP');
                $ctcsstone = $FT817->readMemory('MEM', "$num", 'CTCSSTONE');
                $dcscode = $FT817->readMemory('MEM', "$num", 'DCSCODE');
                $claronoff = $FT817->readMemory('MEM', "$num", 'CLARIFIER');
                print "MEMORY[$num] - $frequency($mode)\n\n";
                                      }


                $FT817->setVerbose(1);
                printf "%-11s%-11s%-11s\n%-11s%-11s%-11s\n", 'TUNER','----->',"$tuner",'HOME','----->',"$home";
                printf "%-11s%-11s%-11s\n%-11s%-11s%-11s\n", 'AGC','----->',"$agc",'DSP','----->',"$dsp";
                printf "%-11s%-11s%-11s\n%-11s%-11s%-11s\n", 'NB','----->',"$nb",'TXPOWER','----->',"$txpower";
		printf "%-11s%-11s%-11s\n%-11s%-11s%-11s\n", 'VOX','----->',"$vox",'NAR-FM','----->',"$narfm";
		printf "%-11s%-11s%-11s\n%-11s%-11s%-11s\n", 'NAR-CWDIG','----->',"$narcwdig",'RPT-OFFSET','----->',"$rptoffset";
                printf "%-11s%-11s%-11s\n%-11s%-11s%-11s\n", 'TONE-DCS','----->',"$tonedcs",'ATT','----->',"$att";
                printf "%-11s%-11s%-11s\n%-11s%-11s%-11s\n", 'IPO','----->',"$ipo",'FM-STEP','----->',"$fmstep";
                printf "%-11s%-11s%-11s\n%-11s%-11s%-11s\n", 'AM-STEP','----->',"$amstep",'SSB-STEP','----->',"$ssbstep";
                printf "%-11s%-11s%-11s\n%-11s%-11s%-11s\n", 'CTCSS-TONE','----->',"$ctcsstone",'DCS-CODE','----->',"$dcscode";
                printf "%-11s%-11s%-11s\n%-11s%-11s%-11s\n", 'MODE','----->',"$memmode",'CLARIFIER','----->',"$claronoff";
		print "\n";
return 0;
	       }


############################################ SHOWRADIOS

sub showRadios {

print "Installed Radios\n\n";
        my $radionumber = 0;
foreach (@radiodata) {
        my $rnumber = $radiodata["$radionumber"]->{'number'};
        my $name = $radiodata["$radionumber"]->{'name'};
        my $serialport = $radiodata["$radionumber"]->{'serialport'};
        my $baudrate = $radiodata["$radionumber"]->{'baudrate'};
        my $lockfile = $radiodata["$radionumber"]->{'lockfile'};
        my $savedconfig = $radiodata["$radionumber"]->{'config'};
        my $saveddigest = $radiodata["$radionumber"]->{'digest'};
        my $configfile = $radiodata["$radionumber"]->{'configfile'};
        my $memoryfile = $radiodata["$radionumber"]->{'memory'};
        my $radioconfigfile = $radiodata["$radionumber"]->{'radioconfigfile'};
        my $softcalfile = $radiodata["$radionumber"]->{'calibration'};
        my $default = $radiodata["$radionumber"]->{'default'};
        print "RADIO [$radionumber]\n";
        printf "%-11s %-15s\n", "NAME:", "$name";
        printf "%-11s %-15s\n", "PORT:", "$serialport";
        printf "%-11s %-15s\n", "BAUDRATE:", "$baudrate";
        printf "%-11s %-15s\n", "LOCKFILE:", "$lockfile";
        printf "%-11s %-15s\n", "CONFIG:", "$savedconfig";
        printf "%-11s %-15s\n", "DEFAULT:", "$default";
	print "\n";
        $radionumber++;
                     }
return 0;
	       }

############################################ SWITCHRADIO

sub switchRadio {
        my $newradio = shift;
	my $found;
	my $newnumber;
        if (!$newradio){
                print "You must choose a radio name or number. Type [show radios] for a listing\n";
return 1;
                       }
       my $radionumber = 0;
	foreach (@radiodata) {
        	my $name = $radiodata["$radionumber"]->{'name'};
		if ($name eq $newradio){$found = 1; $newnumber = $radionumber;}
		$radionumber++;
			     }
if ($found != ''){
print "Found $newradio number $newnumber\n";
        our $rnumber = $radiodata["$newnumber"]->{'number'};
        our $name = $radiodata["$newnumber"]->{'name'};
        our $serialport = $radiodata["$newnumber"]->{'serialport'};
        our $baudrate = $radiodata["$newnumber"]->{'baudrate'};
        our $lockfile = $radiodata["$newnumber"]->{'lockfile'};
        our $savedconfig = $radiodata["newnumber"]->{'config'};
        our $saveddigest = $radiodata["$newnumber"]->{'digest'};
        our $configfile = $radiodata["$newnumber"]->{'configfile'};
        our $memoryfile = $radiodata["$newnumber"]->{'memory'};
        our $radioconfigfile = $radiodata["$newnumber"]->{'radioconfigfile'};
        our $softcalfile = $radiodata["$newnumber"]->{'calibration'};
        my $default = $radiodata["$newnumber"]->{'default'};
	$FT817->closePort();
	our $radioname = $name;
        print "Activating $name\n";
        our $FT817 = new Ham::Device::FT817COMM  (
        serialport => "$serialport",
        baud => "$baudrate",
        lockfile => "$lockfile",
        name => "$name"
                                                 );
        our $prompt = "\[$radioname\]\@$serialport\$ ";
return 0;
	   }
	else {
                print "Radio [$newradio] not found. Type [show radios] for a listing\n";
return 1;
	     }
	        }

############################################ ADDRADIO

sub addRadio {

	my $newserialport;
	my $newname;
	my $newbaudrate;
	my $newlockfile;
	my $newdigest;
	our $newradionumber;
        print "Enter the name of your serial device. i.e. /dev/ttyUSB0\n\n";
do {
                print "Serial Port:> ";
                $newserialport = <>;
                chomp($newserialport);
		my $found;
		my $thename;
        my $radionumber = 0;
        foreach (@radiodata) {
                my $serials = $radiodata["$radionumber"]->{'serialport'};
		my $testname = $radiodata["$radionumber"]->{'name'};
                if ($newserialport eq $serials){$found = 1; $thename = $testname;}
                $radionumber++;
                             }
		$newradionumber = $radionumber++;
	if ($found){print"Another device [$thename] is using that port, are you sure you want to add a radio to the same port? [Y/N] ";
do {
                $prompt = <>;
                chomp($prompt);
                if ($prompt ne 'y' && ($prompt ne 'n')) {$prompt = undef;}	
   } while (!$prompt);

		if ($prompt eq 'n'){$newserialport = undef;}
		   }
   } while (!$newserialport);
		   

        print "Would you like to name the radio connected to [$newserialport]? Press enter for default [FT817]\n\n";
do {
                print "Radio Name:> ";
                $newname = <>;
                chomp($newname);
		my $found;
                if (!$newname){$newname = 'FT817';}

 my $radionumber = 0;
        foreach (@radiodata) {
                my $testname = $radiodata["$radionumber"]->{'name'};
                if ($newname eq $testname){$found = 1;}
                $radionumber++;
                             }
    if ($found){print"Another device is using that name, try another\n"; $newname = undef;}

   } while (!$newname);


               print "\nEnter the Baud Rate for your FT817 CAT RATE on Menu item 14 [4800/9600/38400]\n\n";
do {
                print "Baud:> ";
                $newbaudrate = <>;
                chomp($newbaudrate);
                if ($newbaudrate != '38400' && ($newbaudrate != '4800') && ($newbaudrate != '9600')){$newbaudrate = undef;}
   } while (!$newbaudrate);


        print "\nDo you wish to use a lock file for your serial port using /var/lock/$newname (RECOMMENDED) Y/N\n\n";
do {
        print "Lock File:> ";
                $newlockfile = <>;
                chomp($newlockfile);
                $newlockfile = lc($newlockfile);
                if ($newlockfile ne 'y' && ($newlockfile ne 'n')) {$lockfile = undef;}
   } while (!$newlockfile);
        if ($newlockfile eq 'y'){
                $newlockfile = "\/var\/lock/$newname";
                             }

        print "Here are your settings:\n";
        printf "%-11s %-15s\n", "NAME:", "$newname";
        printf "%-11s %-15s\n", "SERIALPORT:", "$newserialport";
        printf "%-11s %-15s\n", "BAUDRATE:", "$newbaudrate";
        printf "%-11s %-15s\n", "LOCKFILE:", "$newlockfile";
do {
        print "\nAre they correct? [y/n] :> ";
                $prompt = <>;
                chomp($prompt);
                if ($prompt ne 'y' && ($prompt ne 'n')) {$prompt = undef;}
   } while (!$prompt);

                if ($prompt eq 'n'){
return 0;
				   }
        print "\nAn attempt will now be made to connect to $newname\@$newserialport with this configuration\nSerial should be connected with power on.....\n\n";
	$FT817->closePort();

                our $FT817 = new Ham::Device::FT817COMM  (
                serialport => "$newserialport",
                baud => "$newbaudrate",
                lockfile => "$newlockfile"
                                                               );
        	$FT817->setVerbose(0);
                my $test = $FT817->catgetMode();
                $FT817->setVerbose(1);
		my $times;
                my @digest;
                my $newsoftcalfile = join('',"$newname",'.cal');
                $FT817->setVerbose(0);
                if ($test){print "\nConnection with $newserialport\@$newname sucessfull!!!!!\n\n";}
		else {print "Connection failed......"; die;}

                print "Backing up calibration settings: ";
                if (-e "config/$newsoftcalfile") {
                        print "----> SKIPPING : Calibration file /config/$newsoftcalfile exists already!!!!\n";
                                     }
                else {
                        $FT817->getSoftcal('FILE', "config/$newsoftcalfile");
                        print "       ----> OK\n";
                     }
                print "Generating 5 Pass Calibration Hash: ";

  for( $times = 0; $times != 5; $times = $times + 1 ){
                $output = $FT817->getSoftcal('DIGEST');
                push (@digest, "$output");
                                                     }


                if ($digest['0'] eq $digest['1'] && $digest['0'] eq $digest['2'] && $digest['0'] eq $digest['3'] && $digest['0'] eq $digest['4']) {
                        $newdigest = $digest['0'];
                        print "    ----> OK\n";
                                                                                                                                                  }
                else {
                        print "   ----> ERROR!!! Check your cabling and restart this program\n";
                        $FT817->closePort();
                die;
                     }

                print "Retrieving Software Jumper settings: ";
                my $newjumpconfig = $FT817->getConfig();
                print "   ----> OK\n";
	        print "Config files being created:  ";
        open  MCONFIGFILE , ">>", 'config/radiolist.cfg' or print"Can't open config/radiolist.cfg error\n";
        print MCONFIGFILE "$newradionumber $newname N\n";
        close MCONFIGFILE;
        $configfile = join('',"$newname",'.cfg');
        open  RCONFIGFILE , ">>", "config/$configfile" or print"Can't open config/$configfile. error\n";
        print RCONFIGFILE "\############ FT817 os configuration file\n";
        print RCONFIGFILE "\############ Generated by createConfig on $localtime\n#\n#\n#\n";
        print RCONFIGFILE "NAME=$newname\n";
        print RCONFIGFILE "DEFAULT=N\n";
        print RCONFIGFILE "SERIALPORT=$newserialport\n";
        print RCONFIGFILE "BAUDRATE=$newbaudrate\n";
        print RCONFIGFILE "LOCKFILE=$newlockfile\n";
        print RCONFIGFILE "CONFIG=$newjumpconfig\n";
        print RCONFIGFILE "DIGEST=$newdigest\n";
                close RCONFIGFILE;
               print "           ----> OK\n";
        $memoryfile = join('',"$newname",'.mem');
        print "\nBacking up $newname memory: ";
                if (-e "config/$memoryfile") {
                        print "----> SKIPPING : Memory file config/$memoryfile exists already!!!!\n";
                                     }
                else {
                        $FT817->saveMemory("config/$memoryfile");
                     }

        $radioconfigfile = join('',"$newname",'.cnf');
        print "Backing up $newname config: ";
                if (-e "config/$radioconfigfile") {
                        print "----> SKIPPING : Config file config/$radioconfigfile exists already!!!!\n";
                                     }
                else {
                        $FT817->saveConfig("config/$radioconfigfile");
                     }

        $FT817->setVerbose(0);
        print"\n\nRe-starting OS.........\n\n";
        $FT817->closePort();
        sleep 1;
        print "LOAD \"\*\"\,8\,1\n";
        sleep 1;
        print "SEARCHING FOR \*\n";
        sleep 1;
        print "LOADING\n";
        sleep 1;
        print "READY\n";
        sleep 1;
        print "RUN\n";
startUpcheck();
return 0;
                          }

############################################ REMOVERADIO

sub removeRadio {
        my $killradio = shift;
	my $found;
	my $answer;
	my $thenumber;
	my $nodefault = 'false';
        if (!$killradio) {
                print "You must choose a radio name or number. Type [show radios] for a listing\n";
return 1;
                         }

        if ($killradio eq $radioname) {
                print "You cannot remove the active radio [$radioname]\n";
return 1;
                                      }



        my $radionumber = 0;
        foreach (@radiodata) {
                my $name = $radiodata["$radionumber"]->{'name'};
                if ($name eq $killradio){$found = 1; $thenumber = $radionumber;}
                $radionumber++;
                             }
	if (!$found) {
                print "Radio [$killradio] Doesn't exist. Type [show radios] for a listing\n";
return 1;
		     }

	else {
		print "This will completely remove [$killradio] from the system, are you sure?[Y/N] ";
do {
                $answer = <>;
                chomp($answer);
                $answer = lc($answer);
                if ($answer ne 'y' && ($answer ne 'n')) {$answer = undef;}
   } while (!$answer);
	if ($answer eq 'n'){return 0;}
	if ($answer eq 'y'){
		print "\nRemoving [$killradio] configs ";
		my $cal = join ('','config/',"$killradio",'.cal');
		my $mem = join ('','config/',"$killradio",'.mem');
                my $cfg = join ('','config/',"$killradio",'.cfg');
                my $cnf = join ('','config/',"$killradio",'.cnf');
		unlink($cal,$mem,$cfg,$cnf);
		print "      -----> [OK]\n";
		print "Removing [$killradio] from listing \n";
                my @ln;
                my @radiodata;
		my $cfg_line;
                open(MCONFIGFILE, 'config/radiolist.cfg') or die("Unable to open file");
                my @mconfigdata = <MCONFIGFILE>;
		my $currentradio = 0;
                foreach $cfg_line (@mconfigdata)
                        {
                        if (index($cfg_line,"#")==0) { next; }
			if (index($cfg_line,"$thenumber")==0) { next; }
                        @ln=split(" ",$cfg_line);
                        $radiodata["$currentradio"]{'number'} = "$currentradio";
                        $radiodata["$currentradio"]{'name'} = "$ln[1]";
                        $radiodata["$currentradio"]{'default'} = "$ln[2]";
			if ($ln[2] eq 'Y'){$nodefault = 'true';}
			$currentradio++;
			}
        open  MCONFIGFILE , ">", 'config/radiolist.cfg' or print"Can't open config/radiolist.cfg error\n";
        print MCONFIGFILE "\############ FT817 Radio List File\n";
        print MCONFIGFILE "\############ Generated by createConfig on $localtime\n#\n#\n#\n";
        my $radionumber = 0;
	my $thedefault;
	my $defname;
        foreach (@radiodata) {
                my $thename = $radiodata["$radionumber"]{'name'};

		if ($nodefault eq 'false'){
			if ($radionumber == 0){print "Changing $thename to the default radio... ";
			$defname = "$thename"; 
  				          }
					  }

		if ($nodefault eq 'true') {
                $thedefault = $radiodata["$radionumber"]{'default'};
		                          }

                print MCONFIGFILE "$radionumber $thename $thedefault\n";
                $radionumber++;
                             }
        close MCONFIGFILE;
	print " -----> [OK]\n";
	
		print "[$killradio] removed\n";
if ($defname) {defaultRadio("$defname");}
                        $FT817->closePort();
startUpcheck();
return 0;
			   }
	     }
return 0;
	     }

############################################ DEFAULTRADIO

sub defaultRadio {
        my $newdefault = shift;
        my $found;
        my $newnumber;
        if (!$newdefault){
                print "You must choose a radio name or number. Type [show radios] for a listing\n";
return 1;
                         }

	my $radionumber = 0;
        foreach (@radiodata) {
                my $name = $radiodata["$radionumber"]->{'name'};
                if ($name eq $newdefault){$found = 1; $newnumber = $radionumber;}
                $radionumber++;
                             }

	if ($found != ''){
		my @ln;
		my @radiodata;
                open(MCONFIGFILE, 'config/radiolist.cfg') or die("Unable to open file");
                my @mconfigdata = <MCONFIGFILE>;
                foreach $cfg_line (@mconfigdata)
                        {
                        if (index($cfg_line,"#")==0) { next; }
                	@ln=split(" ",$cfg_line);
                	$radiodata["$ln[0]"]{'number'} = "$ln[0]";
                	$radiodata["$ln[0]"]{'name'} = "$ln[1]";
			if ($radiodata["$ln[0]"]{'name'} eq "$newdefault"){
				print "Setting $newdefault as the startup radio\n";
		                $radiodata["$ln[0]"]{'default'} = "Y";
									  }
			else {
               			$radiodata["$ln[0]"]{'default'} = "N";
	     		     }
			}

        open  MCONFIGFILE , ">", 'config/radiolist.cfg' or print"Can't open config/radiolist.cfg error\n";
        print MCONFIGFILE "\############ FT817 Radio List File\n";
        print MCONFIGFILE "\############ Generated by createConfig on $localtime\n#\n#\n#\n";
        my $radionumber = 0;
        foreach (@radiodata) {
		my $thename = $radiodata["$radionumber"]{'name'};
        	my $thedefault = $radiodata["$radionumber"]{'default'};
        	print MCONFIGFILE "$radionumber $thename $thedefault\n";
                $radionumber++;
                             }
        close MCONFIGFILE;
return 0;
			 }

        else {
                print "Radio [$newdefault] not found. Type [show radios] for a listing\n";
return 1;
             }
		 }

############################################ MEMQMB
sub memqmb {
        $FT817->setVerbose(0);
        $write = $FT817->getFlags('WRITEALLOW');
        $FT817->setVerbose(1);
	if (!$write){
		print "You must have write enable to enter memory mode..... [write enable]\n";
return 0;
                    }
        $memtype = "QMB";
        our $currentdir = "MEMORY\[QMB\]";
        my $exit;
	my $back;
do {
        $data = prompt();
        @values = split(' ', $data);
        my $name = lc($values[0]);
        my $value = uc($values[1]);
        my $value2 = uc($values[2]);
        my $value3 = uc($values[3]);
        my $value4 = uc($values[4]);

        if ($name eq 'help'){help('_memoryopts');}                             
 	elsif (($name eq 'back') || ($name eq 'cd' && $value eq '..')){$back = '1';}
        elsif ($name eq 'cd' && $value eq '/'){$memtype = undef; $currentdir = undef; $currentband = undef; return 'root';}
        elsif ($name eq 'exit'){$memtype = undef; $currentdir = undef; $currentband = undef; return 'exit';}

        elsif ($name eq 'show') {showMemory('QMB');}
        elsif ($name ne 'history' && $name ne 'help' && $name ne 'outputlog' && $name ne 'clear'){
        push @outputs, { "$name $value" => "$output" };
                                                                                                 }
      $output = undef;
   } while ($back ne '1');
        $memtype = undef;
        $currentdir = 'MEMORY';
return 0;
           } 

############################################ MEMHOME
sub memhome {
        my $selectedhome = shift;
        $selectedhome = uc($selectedhome);
	$FT817->setVerbose(0);
	$write = $FT817->getFlags('WRITEALLOW');
	$FT817->setVerbose(1);
	if (!$write){
		print "You must have write enable to enter memory mode..... [write enable]\n";
return 0;
            	    }
        $memtype = "HOME$\($selectedhome\)";
        our $currentdir = "MEMORY\[HOME$selectedhome\]";
        my $exit;
	my $back;
	my $value;
	my $value2;
	my $value3;
	my $value4;
do {
        $data = prompt();
        @values = split(' ', $data);
        my $name = lc($values[0]);
	if ($name ne 'label') {
        	$value = uc($values[1]);
        	$value2 = uc($values[2]);
        	$value3 = uc($values[3]);
        	$value4 = uc($values[4]);
			      }
	else {
	        $value = join(' ',$values[1],$values[2],$values[3],$values[4]);
     	     }	

        if ($name eq 'help'){
                if (!$currentband){help('_memhome');}
                else {help('_memoryopts');}
                               }
        elsif (($name eq 'back') || ($name eq 'cd' && $value eq '..')){

                if ($currentband){
                                $currentband = undef;
                                $currentdir = "MEMORY\[HOME$selectedhome\]";
                                 }
                else {$back = '1';}
                               }

        elsif ($name eq 'cd' && $value eq '/'){$memtype = undef; $currentdir = undef; $currentband = undef; return 'root';}
        elsif ($name eq 'exit'){$memtype = undef; $currentdir = undef; $currentband = undef; return 'exit';}
        elsif ($name eq 'hf' || $name eq '6m' || $name eq '2m' || $name eq 'uhf'){
                $currentdir = "MEMORY\[HOME$selectedhome\]\[$name\]";
                $currentband = $name;
                                                                                 }
elsif ($currentband){
        if ($name eq 'show') {showMemory('HOME',"$currentband");}
        if ($name eq 'mode') {$output = $FT817->writeMemory('home',"$currentband",'mode',"$value");}
        if ($name eq 'narfm') {$output = $FT817->writeMemory('home',"$currentband",'narfm',"$value");}
        if ($name eq 'narcwdig') {$output = $FT817->writeMemory('home',"$currentband",'narcwdig',"$value");}
        if ($name eq 'display') {$output = $FT817->writeMemory('home',"$currentband",'tag',"$value");}
        if ($name eq 'att') {$output = $FT817->writeMemory('home',"$currentband",'att',"$value");}
        if ($name eq 'ipo') {$output = $FT817->writeMemory('home',"$currentband",'ipo',"$value");}
        if ($name eq 'skip') {$output = $FT817->writeMemory('home',"$currentband",'memskip',"$value");}
        if ($name eq 'fmstep') {$output = $FT817->writeMemory('home',"$currentband",'fmstep',"$value");}
        if ($name eq 'amstep') {$output = $FT817->writeMemory('home',"$currentband",'amstep',"$value");}
        if ($name eq 'ssbstep') {$output = $FT817->writeMemory('home',"$currentband",'ssbstep',"$value");}
        if ($name eq 'encoder') {$output = $FT817->writeMemory('home',"$currentband",'tonedcs',"$value");}
        if ($name eq 'rptoffset') {$output = $FT817->writeMemory('home',"$currentband",'rptoffset',"$value");}
        if ($name eq 'ctcsstone') {$output = $FT817->writeMemory('home',"$currentband",'ctcsstone',"$value");}
        if ($name eq 'dcscode') {$output = $FT817->writeMemory('home',"$currentband",'dcscode',"$value");}
        if ($name eq 'clarifier') {$output = $FT817->writeMemory('home',"$currentband",'clarifier',"$value");}
        if ($name eq 'claroffset') {$output = $FT817->writeMemory('home',"$currentband",'claroffset',"$value");}
        if ($name eq 'rxfreq') {$output = $FT817->writeMemory('home',"$currentband",'rxfreq',"$value");}
        if ($name eq 'shift') {$output = $FT817->writeMemory('home',"$currentband",'rptoffsetfreq',"$value");}
        if ($name eq 'label') {$output = $FT817->writeMemory('home',"$currentband",'label',"$value");}
		    }

        elsif ($name eq 'list') {memoryList();}
        elsif ($name eq 'currentmem') {$FT817->setCurrentmem("$value");}
        else {print "SYNTAX ERROR\n";}
        if ($name ne 'history' && $name ne 'help' && $name ne 'outputlog' && $name ne 'clear'){
        push @outputs, { "$name $value" => "$output" };
                                                                                              }
       $output = undef;
   } while ($back ne '1');
        $memtype = undef;
        $currentdir = 'MEMORY';
return 0;
           }
	    
############################################ MEMVFO
sub memmemory {
        my $selected = shift;
        $selected = uc($selected);
        $FT817->setVerbose(0);
        $write = $FT817->getFlags('WRITEALLOW');
        $FT817->setVerbose(1);

	if (!$write){
		print "You must have write enable to enter memory mode..... [write enable]\n";
return 0;
            	    }
        $memtype = "MEM";
        our $currentdir = "MEMORY\[MEM\]";
        my $exit;
	my $back;
        my $value;
        my $value2;
        my $value3;
        my $value4;
do {
        $data = prompt();
        @values = split(' ', $data);
        my $name = lc($values[0]);
        if ($name ne 'label') {
                $value = uc($values[1]);
                $value2 = uc($values[2]);
                $value3 = uc($values[3]);
                $value4 = uc($values[4]);
                              }
        else {
                $value = join(' ',$values[1],$values[2],$values[3],$values[4]);
             }

        if ($name eq 'help'){
                if (!$currentband){help('_memmemory');}
                else {help('_memoryopts');}
                            }
        elsif (($name eq 'back') || ($name eq 'cd' && $value eq '..')){

                if ($currentband){
                                $currentband = undef;
                                $currentdir = "MEMORY\[MEM\]";
                                 }
                else {$back = '1';}
                               }
        elsif ($name eq 'cd' && $value eq '/'){$memtype = undef; $currentdir = undef; $currentband = undef; return 'root';}
        elsif ($name eq 'exit'){$memtype = undef; $currentdir = undef; $currentband = undef; return 'exit';}
        elsif (($name > '0' && $name < 201) || ($name eq 'm-pl' || $name eq 'm-pu')){
		$name = uc($name);
                $currentdir = "MEMORY\[MEM:$name\]";
                $currentband = $name;
                                                                                    }

	elsif ($currentband){
        	if ($name eq 'show') {showMemory('MEM',"$currentband");}
                if ($name eq 'list') {memoryList();}
                if ($name eq 'memarea') {$FT817->setMemarea("$value","$value2");}
                if ($name eq 'currentmem') {$FT817->setCurrentmem("$value");}
        	if ($name eq 'mode') {$output = $FT817->writeMemory('mem',"$currentband",'mode',"$value");}
        	if ($name eq 'narfm') {$output = $FT817->writeMemory('mem',"$currentband",'narfm',"$value");}
        	if ($name eq 'narcwdig') {$output = $FT817->writeMemory('mem',"$currentband",'narcwdig',"$value");}
        	if ($name eq 'display') {$output = $FT817->writeMemory('mem',"$currentband",'tag',"$value");}
        	if ($name eq 'att') {$output = $FT817->writeMemory('mem',"$currentband",'att',"$value");}
        	if ($name eq 'ipo') {$output = $FT817->writeMemory('mem',"$currentband",'ipo',"$value");}
        	if ($name eq 'skip') {$output = $FT817->writeMemory('mem',"$currentband",'memskip',"$value");}
        	if ($name eq 'fmstep') {$output = $FT817->writeMemory('mem',"$currentband",'fmstep',"$value");}
        	if ($name eq 'amstep') {$output = $FT817->writeMemory('mem',"$currentband",'amstep',"$value");}
        	if ($name eq 'ssbstep') {$output = $FT817->writeMemory('mem',"$currentband",'ssbstep',"$value");}
        	if ($name eq 'encoder') {$output = $FT817->writeMemory('mem',"$currentband",'tonedcs',"$value");}
        	if ($name eq 'rptoffset') {$output = $FT817->writeMemory('mem',"$currentband",'rptoffset',"$value");}
        	if ($name eq 'ctcsstone') {$output = $FT817->writeMemory('mem',"$currentband",'ctcsstone',"$value");}
        	if ($name eq 'dcscode') {$output = $FT817->writeMemory('mem',"$currentband",'dcscode',"$value");}
        	if ($name eq 'clarifier') {$output = $FT817->writeMemory('mem',"$currentband",'clarifier',"$value");}
        	if ($name eq 'claroffset') {$output = $FT817->writeMemory('mem',"$currentband",'claroffset',"$value");}
        	if ($name eq 'rxfreq') {$output = $FT817->writeMemory('mem',"$currentband",'rxfreq',"$value");}
        	if ($name eq 'shift') {$output = $FT817->writeMemory('mem',"$currentband",'rptoffsetfreq',"$value");}
        	if ($name eq 'label') {$output = $FT817->writeMemory('mem',"$currentband",'label',"$value");}
                	    }
	elsif ($name eq 'list') {memoryList();}
        elsif ($name eq 'currentmem') {$FT817->setCurrentmem("$value");}
        elsif ($name eq 'memarea') {$FT817->setMemarea("$value","$value2");}
        else {print "SYNTAX ERROR\n";}
        $output = undef;
   } while ($back ne '1');
        $memtype = undef;
        $currentdir = 'MEMORY';
return 0;
           }

############################################ MEMVFO
sub memvfo {
        my $selectedvfo = shift;
        $selectedvfo = uc($selectedvfo);
	$FT817->setVerbose(0);
	$write = $FT817->getFlags('WRITEALLOW');
	$FT817->setVerbose(1);

	if ($selectedvfo ne 'A' && $selectedvfo ne 'B' && $selectedvfo ne 'MTQMB' && $selectedvfo ne 'MTUNE'){
		print "You must Choose a VFO A / B / MTUNE / MTQMB\n";
return 0;
     													     }
	if (!$write){
		print "You must have write enable to enter memory mode..... [write enable]\n";
return 0;
	            }

	$memtype = "VFO$\($selectedvfo\)";
	our $currentdir = "MEMORY\[VFO\:$selectedvfo\]";
	if ($selectedvfo eq 'MTUNE'){$currentband = 'MTUNE'};
	if ($selectedvfo eq 'MTQMB'){$currentband = 'MTQMB'};
        my $exit;
	my $back;
do {
        $data = prompt();
        @values = split(' ', $data);
        my $name = lc($values[0]);
        my $value = uc($values[1]);
        my $value2 = uc($values[2]);
        my $value3 = uc($values[3]);
        my $value4 = uc($values[4]);
### is this needed below?
        if ($name eq 'vfo') {memvfo("$value");}
        elsif ($name eq 'help'){
		if (!$currentband){help('_memvfo');}
		else {help('_vfomemopts');}
			       }
        elsif (($name eq 'back') || ($name eq 'cd' && $value eq '..')){
                if ($currentband eq 'MTQMB' || $currentband eq 'MTUNE') {
			$currentband = undef;
                        $currentdir = "MEMORY";
			$back = '1';
					                                                         }
	if ($currentband){
			$currentband = undef;
			$currentdir = "MEMORY\[VFO\:$selectedvfo\]";
			 }
	else {$back = '1';}
			       }

        elsif ($name eq 'cd' && $value eq '/'){$memtype = undef; $currentdir = undef; $currentband = undef; return 'root';}
        elsif ($name eq 'exit'){$memtype = undef; $currentdir = undef; $currentband = undef; return 'exit';}

	elsif ($name eq '160m' || $name eq '75m' || $name eq '40m' || $name eq '30m' || $name eq '20m' || $name eq '17m' ||
	       $name eq '15m' || $name eq '12m' || $name eq '10m' || $name eq '6m' || $name eq 'FM BCB' || $name eq 'AIR' ||
	       $name eq '2m' || $name eq 'UHF' || $name eq 'PHANTOM') {

	       	$currentdir = "MEMORY\[VFO\:$selectedvfo\]\[$name\]";
		$currentband = $name;
								      }	               
	elsif ($currentband){
        	if ($name eq 'show') {showMemvfo("$selectedvfo","$currentband");}
        	if ($name eq 'mode') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'mode',"$value");}
        	if ($name eq 'narfm') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'narfm',"$value");}
        	if ($name eq 'narcwdig') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'narcwdig',"$value");}
        	if ($name eq 'rptoffset') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'rptoffset',"$value");}
        	if ($name eq 'encoder') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'tonedcs',"$value");}
        	if ($name eq 'clarifier') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'clarifier',"$value");}
        	if ($name eq 'att') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'att',"$value");}
        	if ($name eq 'ipo') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'ipo',"$value");}
        	if ($name eq 'fmstep') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'fmstep',"$value");}
        	if ($name eq 'amstep') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'amstep',"$value");}
        	if ($name eq 'ssbstep') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'ssbstep',"$value");}
        	if ($name eq 'ctcsstone') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'ctcsstone',"$value");}
        	if ($name eq 'dcscode') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'dcscode',"$value");}
        	if ($name eq 'claroffset') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'claroffset',"$value");}
        	if ($name eq 'rxfreq') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'rxfreq',"$value");}
        	if ($name eq 'shift') {$output = $FT817->writeMemvfo("$selectedvfo","$currentband",'rptoffsetfreq',"$value");}
  			    }
        else {print "SYNTAX ERROR\n";}
        if ($name ne 'history' && $name ne 'help' && $name ne 'outputlog' && $name ne 'clear'){
        	push @outputs, { "$name $value" => "$output" };
                                                                                              }
        $output = undef;
   } while ($back ne '1');
	$memtype = undef;
        $currentdir = 'MEMORY';
return 0;
           }

############################################ MEMORYMODE

sub memorymode {
	$FT817->setVerbose(0);
	$write = $FT817->getFlags('WRITEALLOW');
	$FT817->setVerbose(1);
	if (!$write){
		print "You must have write enable to enter memory mode..... [write enable]\n";
return 0;
        	    }
        our $currentdir = 'MEMORY';
        my $exit;
	my $back;
do {
        $data = prompt();
        @values = split(' ', $data);
        my $name = lc($values[0]);
        my $value = uc($values[1]);
        my $value2 = uc($values[2]);
        if ($name eq 'vfo') {$rootflag = memvfo("$value");}
        elsif ($name eq 'currentmem') {$FT817->setCurrentmem("$value");}
        elsif ($name eq 'memarea') {$FT817->setMemarea("$value","$value2");}
	elsif ($name eq 'home') {$rootflag = memhome("$value");}
        elsif ($name eq 'qmb') {$rootflag = memqmb();}
        elsif ($name eq 'mem') {$rootflag = memmemory();}
        elsif ($name eq 'help'){help('_memory');}
        elsif (($name eq 'back') || ($name eq 'cd' && $value eq '..')){$back = '1';}
        elsif ($name eq 'cd' && $value eq '/'){$memtype = undef; $currentdir = undef; $currentband = undef; return 'root';}
        elsif ($name eq 'exit'){$memtype = undef; $currentdir = undef; $currentband = undef; return 'exit';}
        elsif ($name eq 'list') {memoryList();}
        else {print "SYNTAX ERROR\n";}
        if ($name ne 'history' && $name ne 'help' && $name ne 'outputlog' && $name ne 'clear'){
	        push @outputs, { "$name $value" => "$output" };

	                                                                                             }
	if ($rootflag eq 'root'){$rootflag = undef; return 'root';}
	if ($rootflag eq 'exit'){return 'exit';}
        $output = undef;
   } while ($back ne '1');
        $currentdir = undef;
return 0;
               }

############################################ CONFIGMODE

sub configmode {
	$FT817->setVerbose(0);
	$write = $FT817->getFlags('WRITEALLOW');
	$FT817->setVerbose(1);
	if (!$write){
		print "You must have write enable to enter config mode..... [write enable]\n";
return 0;	    
         	    }
        our $currentdir = 'CONFIG';
        my $exit;
	my $back;
do {
        $data = prompt();
        @values = split(' ', $data);
	my $name = lc($values[0]);
	my $value;
	my $value2;
	my $value3;
	my $value4;
        if ($name ne 'id') {
                $value = uc($values[1]);
                $value2 = uc($values[2]);
                $value3 = uc($values[3]);
                $value4 = uc($values[4]);
                           }
        else {
                $value = join(' ',$values[1],$values[2],$values[3],$values[4]);
             }
	if ($name eq '144ars') {$output = $FT817->setArs144("$value");}
	elsif ($name eq '430ars') {$output = $FT817->setArs430("$value");}
        elsif ($name eq '9600mic') {$output = $FT817->set9600mic("$value");}
        elsif ($name eq 'amfmdial') {$output = $FT817->setAmfmdial("$value");}
        elsif ($name eq 'ammic') {$output = $FT817->setAmmic("$value");}
        elsif ($name eq 'apotime') {$output = $FT817->setApotime("$value");}
        elsif ($name eq 'artsmode') {$output = $FT817->setArtsmode("$value");}
        elsif ($name eq 'backlight') {$output = $FT817->setBacklight("$value");}
        elsif ($name eq 'beepfreq') {$output = $FT817->setBeepfreq("$value");}
        elsif ($name eq 'beepvol') {$output = $FT817->setBeepvol("$value");}
        elsif ($name eq 'catrate') {
		print "This setting takes effect on next radio restart.\n";
		print "Changing this setting will drop the connection to the radio after restart..... Are you sure [Y/N]?\nANSWER: ";
		my $question = <>;
        	chomp $question;
        	$question = lc($question);
		if ($question eq 'y'){$output = $FT817->setCatrate("$value");}
			           }
	elsif ($name eq 'chargetime') {$output = $FT817->setChargetime("$value");}
        elsif ($name eq 'color') {$output = $FT817->setColor("$value");}
        elsif ($name eq 'contrast') {$output = $FT817->setContrast("$value");}
        elsif ($name eq 'cwdelay') {$output = $FT817->setCwdelay("$value");}
	elsif ($name eq 'cwid') {$output = $FT817->setCwid("$value");}
        elsif ($name eq 'cwpaddle') {$output = $FT817->setCwpaddle("$value");}
        elsif ($name eq 'cwpitch') {$output = $FT817->setCwpitch("$value");}
        elsif ($name eq 'cwspeed') {$output = $FT817->setCwspeed("$value");}
        elsif ($name eq 'cwweight') {$output = $FT817->setCwweight("$value");}
        elsif ($name eq 'dcsinv') {$output = $FT817->setDcsinv("$value");}
        elsif ($name eq 'digdisp') {$output = $FT817->setDigdisp("$value");}
        elsif ($name eq 'digmic') {$output = $FT817->setDigmic("$value");}
        elsif ($name eq 'digmode') {$output = $FT817->setDigmode("$value");}
        elsif ($name eq 'digshift') {$output = $FT817->setDigshift("$value");}
        elsif ($name eq 'emergency') {$output = $FT817->setEmergency("$value");}
        elsif ($name eq 'extmenu') {$output = $FT817->setExtmenu("$value");}
        elsif ($name eq 'fmmic') {$output = $FT817->setFmmic("$value");}
        elsif ($name eq 'id') {$output = $FT817->setId("$value");}
	elsif ($name eq 'lockmode') {$output = $FT817->setLockmode("$value");}
        elsif ($name eq 'mainstep') {$output = $FT817->setMainstep("$value");}
        elsif ($name eq 'memgroups') {$output = $FT817->setMemgroup("$value");}
        elsif ($name eq 'mickey') {$output = $FT817->setMickey("$value");}
        elsif ($name eq 'micscan') {$output = $FT817->setMicscan("$value");}
        elsif ($name eq 'opfilter') {$output = $FT817->setOpfilter("$value");}
        elsif ($name eq 'pktmic') {$output = $FT817->setPktmic("$value");}
        elsif ($name eq 'pktrate') {$output = $FT817->setPktrate("$value");}
        elsif ($name eq 'resume') {$output = $FT817->setResumescan("$value");}
        elsif ($name eq 'rlsbcar') {$output = $FT817->setRlsbcar("$value");}
        elsif ($name eq 'rusbcar') {$output = $FT817->setRusbcar("$value");}
        elsif ($name eq 'rfknob') {$output = $FT817->setRfknob("$value");}
        elsif ($name eq 'scope') {$output = $FT817->setScope("$value");}
	elsif ($name eq 'sidetonevol') {$output = $FT817->setSidetonevol("$value");}
        elsif ($name eq 'ssbmic') {$output = $FT817->setSsbmic("$value");}
        elsif ($name eq 'tlsbcar') {$output = $FT817->setTlsbcar("$value");}
        elsif ($name eq 'tusbcar') {$output = $FT817->setTusbcar("$value");}
        elsif ($name eq 'tottime') {$output = $FT817->setTottime("$value");}
        elsif ($name eq 'voxdelay') {$output = $FT817->setVoxdelay("$value");}
        elsif ($name eq 'voxgain') {$output = $FT817->setVoxgain("$value");}
        elsif ($name eq 'restore') {$output = $FT817->restoreEeprom("$value");}
        elsif ($name eq 'show') {configList("$value");}
	elsif ($name eq 'help'){help('_config');}	
	elsif ($name eq 'history'){history();}
	elsif ($name eq 'outputlog'){outputlog();}
        elsif (($name eq 'back') || ($name eq 'cd' && $value eq '..')){$back = '1';}
        elsif ($name eq 'cd' && $value eq '/'){$memtype = undef; $currentdir = undef; $currentband = undef; return 'root';}
        elsif ($name eq 'exit'){$memtype = undef; $currentdir = undef; $currentband = undef; return 'exit';}
 	else {print "SYNTAX ERROR\n";}
        if ($name ne 'history' && $name ne 'help' && $name ne 'outputlog' && $name ne 'clear'){
        	push @outputs, { "$name $value" => "$output" };
                                                                                              }
        $output = undef;
   } while ($back ne '1');
	$currentdir = undef;
return 0;
	       }


############################################ LOADRADIO

sub loadRadio {
        my $radionumber = 0;
foreach (@radiodata) {
        my $default = $radiodata["$radionumber"]->{'default'};
        if ($default eq 'Y'){
        our $rnumber = $radiodata["$radionumber"]->{'number'};
        our $name = $radiodata["$radionumber"]->{'name'};
        our $serialport = $radiodata["$radionumber"]->{'serialport'};
        our $baudrate = $radiodata["$radionumber"]->{'baudrate'};
        our $lockfile = $radiodata["$radionumber"]->{'lockfile'};
        our $savedconfig = $radiodata["$radionumber"]->{'config'};
        our $saveddigest = $radiodata["$radionumber"]->{'digest'};
        our $configfile = $radiodata["$radionumber"]->{'configfile'};
        our $memoryfile = $radiodata["$radionumber"]->{'memory'};
        our $radioconfigfile = $radiodata["$radionumber"]->{'radioconfigfile'};
        our $softcalfile = $radiodata["$radionumber"]->{'calibration'};
                our $radioname = $name;
                our $activenumber = $rnumber;
        print "Activating $name\n";
        our $FT817 = new Ham::Device::FT817COMM  (
        serialport => "$serialport",
        baud => "$baudrate",
        lockfile => "$lockfile",
        name => "$name"
                                                );
                            }
        $radionumber++;
                     }


	}

################################################################################### BEGIN OS HERE

startUpcheck();
#        my $radionumber = 0;
#foreach (@radiodata) { 
#        my $default = $radiodata["$radionumber"]->{'default'};
#        if ($default eq 'Y'){
#	our $rnumber = $radiodata["$radionumber"]->{'number'};
#	our $name = $radiodata["$radionumber"]->{'name'};
#        our $serialport = $radiodata["$radionumber"]->{'serialport'};
#        our $baudrate = $radiodata["$radionumber"]->{'baudrate'};
#        our $lockfile = $radiodata["$radionumber"]->{'lockfile'};
#        our $savedconfig = $radiodata["$radionumber"]->{'config'};
#        our $saveddigest = $radiodata["$radionumber"]->{'digest'}; 
#        our $configfile = $radiodata["$radionumber"]->{'configfile'};
#        our $memoryfile = $radiodata["$radionumber"]->{'memory'};
#        our $radioconfigfile = $radiodata["$radionumber"]->{'radioconfigfile'};
#        our $softcalfile = $radiodata["$radionumber"]->{'calibration'};
#		our $radioname = $name; 
#		our $activenumber = $rnumber;
#	print "Activating $name\n";
#        our $FT817 = new Ham::Device::FT817COMM  (
#        serialport => "$serialport",
#        baud => "$baudrate",
#        lockfile => "$lockfile",
#	name => "$name"
#                                                );
#			    }
#	$radionumber++;
#		     } 

	$version = $FT817->moduleVersion();
	our $prompt = "\[$radioname\]\@$serialport\$ ";
	banner();
	my $test1 = testConfig();
	my $test2 = testCal();
print "TOTAL RADIOS IN CONFIG [$totalradios]\n";
	if ($test1 == 1){
		if ($test1 == $test2){print "\n\n***********BOTH TESTS FAILED... ARE YOU SURE THE CORRECT RADIO IS CONNECTED TO $serialport???***********\n\n";}
			}

#####STARTUP FLAGS SHOULD BE SET OR UNSET HERE
	$FT817->setVerbose(1);
#	$FT817->setBitwatch(1);
#	$FT817->setWriteallow(1);
#	$FT817->agreeWithwarning(1);
#	$FT817->setDebug(1);
	print "\n";
do {
	$data = prompt();
	@values = split(' ', $data);
                my $name = lc($values[0]);
                my $value = $values[1];
                my $value2 = $values[2];
                my $value3 = $values[3];
	if ($values[0] eq 'cat' || $values[0] eq 'set' || $values[0] eq 'get') {
		my $type = $values[0];
		my $name = lc($values[1]);
		my $value = uc($values[2]);
		my $value2 = uc($values[3]); 
		my $value3 = uc($values[4]);
                my $value4 = uc($values[5]); 
                my $value5 = uc($values[6]);
                if ($type eq 'cat'){
                        if ($name eq 'clarifier') {$output = $FT817->catClarifier("$value");}
                        elsif ($name eq 'clarifierfreq') {$output = $FT817->catClarifierfreq("$value","$value2");}
                        elsif ($name eq 'ctcsstone') {$output = $FT817->catCtcsstone("$value");}
                        elsif ($name eq 'dcscode') {$output = $FT817->catDcscode("$value");}
                        elsif ($name eq 'encoder') {$output = $FT817->catCtcssdcs("$value");}
                        elsif ($name eq 'getfrequency') {$output = $FT817->catgetFrequency("1");}
                        elsif ($name eq 'setfrequency') {$output = $FT817->catsetFrequency("$value");}
                        elsif ($name eq 'lock') {$output = $FT817->catLock("$value");}
                        elsif ($name eq 'getmode') {$output = $FT817->catgetMode();}
                        elsif ($name eq 'setmode') {$output = $FT817->catsetMode("$value");}
                        elsif ($name eq 'offset') {$output = $FT817->catOffsetmode("$value");}
                        elsif ($name eq 'offsetfreq') {$output = $FT817->catOffsetfreq("$value");}
                        elsif ($name eq 'power') {$output = $FT817->catPower("$value");}
                        elsif ($name eq 'ptt') {$output = $FT817->catPtt("$value");}
                        elsif ($name eq 'rxstatus') {my ($squelch, $smeter, $smeterlin, $match, $desc) = $FT817->catRxstatus("VARIABLES");}
                        elsif ($name eq 'splitfreq') {$output = $FT817->catSplitfreq("$value");}
                        elsif ($name eq 'togglevfo') {$output = $FT817->catvfoToggle();}
                        elsif ($name eq 'txstatus') {my ($ptt, $pometer, $highswr, $split) = $FT817->catTxstatus("VARIABLES");}
        else {print "SYNTAX ERROR\n";}
                                   }
		if ($type eq 'set'){
                        if ($name eq 'agc') {$output = $FT817->setAgc("$value");}
                        elsif ($name eq 'antenna') {$output = $FT817->setAntenna("$value","$value2");}
                        elsif ($name eq 'arts') {$output = $FT817->setArts("$value");}
                        elsif ($name eq 'breakin') {$output = $FT817->setBk("$value");}
                        elsif ($name eq 'charger') {$output = $FT817->setCharger("$value");}
                        elsif ($name eq 'currentmem') {$output = $FT817->setCurrentmem("$value");}
                        elsif ($name eq 'dsp') {$output = $FT817->setDsp("$value");}
                        elsif ($name eq 'dw') {$output = $FT817->setDw("$value");}
                        elsif ($name eq 'fasttune') {$output = $FT817->setFasttuning("$value");}
			elsif ($name eq 'home') {$output = $FT817->setHome("$value");}
                        elsif ($name eq 'keyer') {$output = $FT817->setKyr("$value");}
			elsif ($name eq 'lock') {$output = $FT817->setLock("$value");}
	                elsif ($name eq 'memarea') {$output = $FT817->setMemarea("$value","$value2");}
			elsif ($name eq 'mtqmb') {$output = $FT817->setMtqmb("$value");}
                        elsif ($name eq 'mtune') {$output = $FT817->setMtune("$value");}
                        elsif ($name eq 'nb') {$output = $FT817->setNb("$value");}
                        elsif ($name eq 'pbt') {$output = $FT817->setPbt("$value");}
                        elsif ($name eq 'pri') {$output = $FT817->setPri("$value");}
			elsif ($name eq 'pwrmtr') {$output = $FT817->setPwrmtr("$value");}
			elsif ($name eq 'qmb') {$output = $FT817->setQmb("$value");}
                        elsif ($name eq 'scn') {$output = $FT817->setScn("$value");}
                        elsif ($name eq 'spl') {$output = $FT817->setSpl("$value");}
			elsif ($name eq 'tuner') {$output = $FT817->setTuner("$value");}
                        elsif ($name eq 'txpower') {$output = $FT817->setTxpower("$value");}
                        elsif ($name eq 'vfo') {$output = $FT817->setVfo("$value");}
                        elsif ($name eq 'vfoband') {$output = $FT817->setVfoband("$value","$value2");}
                        elsif ($name eq 'voltage') {$output = $FT817->setVlt("$value");}
                        elsif ($name eq 'vox') {$output = $FT817->setVox("$value");}
	else {print "SYNTAX ERROR\n";}
    				   }
                if ($type eq 'get'){
                        if ($name eq 'agc') {$output = $FT817->getAgc();}
                        elsif ($name eq 'antenna') {$output = $FT817->getAntenna("$value");}
                        elsif ($name eq 'arts') {$output = $FT817->getArts(); $output = $FT817->getArtsmode();}
			elsif ($name eq 'breakin') {$output = $FT817->getBk();}
                        elsif ($name eq 'charger') {$output = $FT817->getCharger();}
                        elsif ($name eq 'checksum') {$output = $FT817->getChecksum();}
                        elsif ($name eq 'jumper') {$output = $FT817->getConfig();}
                        elsif ($name eq 'currentmem') {$output = $FT817->getCurrentmem();}
                        elsif ($name eq 'dsp') {$output = $FT817->getDsp();}
                        elsif ($name eq 'dw') {$output = $FT817->getDw();}
                        elsif ($name eq 'eeprom') {$output = $FT817->getEeprom("$value","$value2");}
                        elsif ($name eq 'fasttune') {$output = $FT817->getFasttuning();}
                        elsif ($name eq 'home') {$output = $FT817->getHome();}
			elsif ($name eq 'keyer') {$output = $FT817->getKyr();}
                        elsif ($name eq 'lock') {$output = $FT817->getLock();}
			elsif ($name eq 'memlist') {$output = memoryList();}
			elsif ($name eq 'mtqmb') {$output = $FT817->getMtqmb();}
                        elsif ($name eq 'mtune') {$output = $FT817->getMtune();}
                        elsif ($name eq 'nb') {$output = $FT817->getNb();}
                        elsif ($name eq 'pbt') {$output = $FT817->getPbt();}
                        elsif ($name eq 'pri') {$output = $FT817->getPri();}
			elsif ($name eq 'pwrmtr') {$output = $FT817->getPwrmtr();}
                        elsif ($name eq 'qmb') {$output = $FT817->getQmb();}
                        elsif ($name eq 'scn') {$output = $FT817->getScn();}
                        elsif ($name eq 'softcal') {$output = $FT817->getSoftcal("$value","$value2");}
                        elsif ($name eq 'spl') {$output = $FT817->getSpl();}
                        elsif ($name eq 'tuner') {$output = $FT817->getTuner();}
                        elsif ($name eq 'txpower') {$output = $FT817->getTxpower();}
                        elsif ($name eq 'vfo') {$output = $FT817->getVfo();}
                        elsif ($name eq 'vfoband') {$output = $FT817->getVfoband("$value");}
                        elsif ($name eq 'voltage') {$output = $FT817->getVlt("$value");}
			elsif ($name eq 'vox') {$output = $FT817->getVox();}
        else {print "SYNTAX ERROR\n";}
				   }
}


	if ($data eq 'quit' || $data eq 'exit'){$finish = '1';}
	elsif ($data eq 'clear'){banner();}
	elsif ($data eq 'history'){history();}
	elsif ($data eq 'outputlog'){outputlog();}
	elsif ($data eq 'debug on') {$output = $FT817->setDebug(1);}
	elsif ($data eq 'debug off') {$output = $FT817->setDebug(0);}
	elsif ($data eq 'verbose on') {$output = $FT817->setVerbose(1);}
	elsif ($data eq 'verbose off') {$output = $FT817->setVerbose(0);}
	elsif ($data eq 'bitwatch on') {$output = $FT817->setBitwatch(1);}
	elsif ($data eq 'bitwatch off') {$output = $FT817->setBitwatch(0);}
	elsif ($data eq 'bitcheck') {$output = $FT817->bitCheck();}
	elsif ($name eq 'boundry') {$output = $FT817->boundryCheck("$value","$value2");}
        elsif ($name eq 'rebuild' && $value eq 'softcal') {rebuildSoftcal("$value2");}
        elsif ($name eq 'load' && $value eq 'config') {loadConfig("$value2");}
        elsif ($name eq 'load' && $value eq 'memory') {loadMemory("$value2");}
        elsif ($name eq 'save' && $value eq 'memory') {saveMemory("$value2");}
        elsif ($name eq 'save' && $value eq 'config') {saveConfig("$value2");}
	elsif ($data eq 'test config') {
		$FT817->setVerbose(0);
		$output = testConfig();
		$FT817->setVerbose(1);
				       }
	elsif ($data eq 'test calibration') {
		$FT817->setVerbose(0);
		$output = testCal();
		$FT817->setVerbose(1);
					    }
	elsif ($data eq 'show status') {showStatus();}
	elsif ($data eq 'show radios') {showRadios();}
        elsif ($name eq 'switch' && $value eq 'radio') {switchRadio("$value2");}
        elsif ($name eq 'default' && $value eq 'radio') {defaultRadio("$value2");}
        elsif ($name eq 'add' && $value eq 'radio') {addRadio();}
        elsif ($name eq 'remove' && $value eq 'radio') {removeRadio("$value2");}
	elsif ($data eq 'show flags') {$output = $FT817->getFlags();}
	elsif ($data eq 'write enable') {
		$output = $FT817->setWriteallow(1);
                $output = $FT817->agreeWithwarning(1);
		$write =1;
				}
	elsif ($data eq 'write disable') {
		$output = $FT817->setWriteallow(0);
		$output = $FT817->agreeWithwarning(0);
		$write = undef;
				}
	elsif ($data eq 'config') {$exitflag = configmode();}
	elsif ($data eq 'memory') {$exitflag = memorymode();}
        elsif ($name eq 'list') {memoryList();}
	elsif ($name eq 'restore') {$output = $FT817->restoreEeprom("$value");}
	if ($values[0] eq 'help'){help("$values[1]");}
	print"\n";
	my $input = lc($input);
	if ($name ne 'history' && $name ne 'help' && $name ne 'outputlog' && $name ne 'clear'){
		push @outputs, { "$name $value $value2 $value3" => "$output" };
						  		    			      }
	if ($exitflag eq 'exit') {$exitflag = undef; $finish = 1;}
	$output = undef;
   } while ($finish ne '1'); 
$FT817->closePort();



=head1 NAME

FT817OS - Command line operating system for the FT817

=head1 VERSION 

Version 0.9.1

=head1 SUPPORT

You can find documentation for this module with the perldoc command.
    perldoc Ham::Device::FT817COMM

You can also look for information at:

=over 4

=item * Technologically Induced Coma
L<http://technocoma.blogspot.com>

=item * My channel on Youtuube
L<https://www.youtube.com/channel/UC_HRlflCd1ogZBmCu3_Mr0g>

=item * Search CPAN
L<http://search.cpan.org/dist/Ham-Device-FT817COMM/>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to Clint Turner KA7OEI for his research on the FT817 and discovering the mysteries of the EEprom.
FT817 and Yaesu are a registered trademark of Vertex standard Inc.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jordan Rubin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;  # End of FT817OS

