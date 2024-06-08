#!/usr/bin/wish

# -------------------------------------------------------------------------
# COMMENTS FROM THE AUTHORS: 
# Although the Tcl/Tk has been kicked out of the GNU projects for a long 
# time, I still keep the following stuffs here in order to make this file
# a part of the entire pseaac-builder project. One man's endorsement wont
# make the whole world. Tcl/Tk is still the 'Best-kept secret in the soft-
# ware industry'.
# 
# IMPORTANT: 
# To execute this script, you will need the Cygwin ports of WISH and TCLSH
# If you have no idea about how to run Cygwin or Linux, please learn. 
# Otherwise, please use the version 1 of pseaac-builder
# -------------------------------------------------------------------------

###########################################################################
#                         Please bear in mind                             #
###########################################################################
# This is just a GUI shell program for the PseAAC-Builder v2.0            #
# No extra check for validating the input                                 #
# All validations of the parameters relie on the executable               #
# All actuall data processing would be done by the command line program   #
#                     !!!DO NOT RELY ON THE GUI!!!                        #
###########################################################################

###########################################################################
# pseb-gui.tcl - Copyright 2013 Pufeng Du, Ph.D.                          # 
#                                                                         #
# This file is a part of PseAAC-Builder v2.0.                             #
# Pseaac-Builder is free software: you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License as published by    #
# the Free Software Foundation, either version 3 of the License, or       #
# (at your option) any later version.                                     #
#                                                                         #
# PseAAC-Builder is distributed in the hope that it will be useful,       #
# but WITHOUT ANY WARRANTY; without even the implied warranty of          #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           #
# GNU General Public License for more details.                            #
#                                                                         #
# You should have received a copy of the GNU General Public License       #
# along with PseAAC-Builder.  If not, see <http://www.gnu.org/licenses/>. #
###########################################################################

package require platform
# Startup check for executables

# The name of executable
global plat pseb
set plat [string tolower [platform::generic]]

if {[string first "cygwin" $plat 0] >= 0} then {
	# For Cygwin+MS Windows
	set pseb "../bin/pseb.exe"
} elseif {[string first "win32" $plat 0] >=0} then {
	# Windows native TCL/TK ? Forgive us, no!
	set pseb "..\\bin\\pseb.exe"
	tk_messageBox -message "PSEB-GUI ABORT: Please use cygwin on MS Windows"
	exit
} elseif {[string first "linux" $plat 0] >=0} then {
	# For Linux
	set pseb "../bin/pseb"
} else {
	set pseb ""
	tk_messageBox -message "PSEB-GUI ABORT: Unidentified platform. Abort."
	exit
}

# Making the executable name
global psebExec
set psebExec [file join [file dirname $argv0] $pseb]

# Without executables, just abort
if {! [file exists $psebExec]  || ! [file isfile $psebExec]} {
	tk_messageBox -message "PSEB-GUI ABORT: pseaac-builder executable was not found as : $psebExec"
	exit
}

# Begin with the status variables
global useaac usedip usepse useselfile
global psetype outfmt segcnt
global infilename outfilename pcselfilename
global lambda weight
global cmdline
global errflag 

# Default values of all status variables
set useaac 1
set usedip 0
set usepse 0
set useselfile 0
set psetype 0
set lambda 10
set weight 0.05
set errflag 0

# Draw the GUI
# Basic strings for windows and messages
global appWindowsTitle
set appWindowTitle "PseAAC-Builder v2.0 GUI"

# Bottom buttons area
frame .button_field -borderwidth 1 -relief raised 
button .button_field.ok -text "OK"  -command MakeAll
button .button_field.cancel -text "Exit" -command exit 
button .button_field.execute -text "Execute" -state disabled -command executeCommand
button .button_field.help -text "Help" -command help
grid .button_field.ok -row 0 -column 0 -sticky nesw 
grid .button_field.execute -row 0 -column 1 -sticky nesw
grid .button_field.help -row 0 -column 2 -sticky nesw
grid .button_field.cancel -row 0 -column 3 -sticky nesw
grid columnconfigure .button_field 0 -weight 1
grid columnconfigure .button_field 1 -weight 1
grid columnconfigure .button_field 2 -weight 1
grid columnconfigure .button_field 3 -weight 1
pack .button_field -side bottom -fill x

# Text based info area for STDERR and CMDLINE
frame .cmdline -borderwidth 1 -relief raised
label .cmdline.title -background #0000ff -foreground #ffffff -text "Command Line:" -anchor w
entry .cmdline.cmd -borderwidth 2 -relief sunken -textvariable cmdline
pack .cmdline.cmd -side bottom -fill x
pack .cmdline.title -side bottom -fill x
pack .cmdline -side bottom -fill x
frame .ioinfo -borderwidth 1 -relief raised
text .ioinfo.stderr -borderwidth 2 -relief sunken -width 100 -height 10 -yscrollcommand {.ioinfo.errbar set}
scrollbar .ioinfo.errbar -command {.ioinfo.stderr yview}
label .ioinfo.errlab -background #0000ff -foreground #ffffff -text "Error messages: " -anchor w
pack .ioinfo.errlab -side top -fill x
pack .ioinfo.stderr -side left -expand yes -fill both
pack .ioinfo.errbar -side right -fill y
pack .ioinfo -side bottom -expand yes -fill both

# Parameter selection area
frame .paras -borderwidth 1 -relief raised
label .paras.lblComps -text "Choose the components"
checkbutton .paras.aac -text "Amino acid composition" -variable useaac -onvalue 1 -offvalue 0
checkbutton .paras.dip -text "Di-peptide composition" -variable usedip -onvalue 1 -offvalue 0 -command dipswitch
checkbutton .paras.pse -text "Pseudo-factors" -variable usepse -command pseswitch
frame .paras.wal
label .paras.wal.lblPsePara -text "Pseudo-factor paramenters"
radiobutton .paras.wal.classic -text "Classic" -variable psetype -value 0 
radiobutton .paras.wal.amphiphilic -text "Amphiphilic" -variable psetype -value 1 
label .paras.wal.lblWeight -text "Weight = "
entry .paras.wal.valWeight -relief sunken -width 8 -state disabled -textvariable weight
label .paras.wal.lblLambda -text "Lambda = "
entry .paras.wal.valLambda -relief sunken -width 8 -state disabled -textvariable lambda
checkbutton .paras.wal.defpc -text "Use default properties" -state disabled -variable useselfile -onvalue 0 -offvalue 1
label .paras.outfmt -text "Output Format: "
spinbox .paras.outfmtsel -values "SVM TAB CSV" -wrap yes -state readonly -textvariable outfmt
label .paras.seg -text "Segments: "
spinbox .paras.segs -from 1 -to 4 -wrap yes -state readonly -textvariable segcnt
grid .paras.lblComps -row 0 -column 0 -sticky w
grid .paras.aac -row 1 -column 0 -sticky w
grid .paras.dip -row 2 -column 0 -sticky w
grid .paras.pse -row 3 -column 0 -sticky w
grid .paras.wal -row 0 -column 1 -sticky nesw -rowspan 4
grid .paras.wal.lblPsePara -row 0 -column 0 -sticky w -columnspan 4
grid .paras.wal.classic -row 1 -column 0 -sticky w -columnspan 2
grid .paras.wal.amphiphilic -row 1 -column 2 -sticky w -columnspan 2
grid .paras.wal.lblWeight -row 2 -column 0 -sticky e
grid .paras.wal.valWeight -row 2 -column 1 -sticky w
grid .paras.wal.valLambda -row 2 -column 3 -sticky w
grid .paras.wal.lblLambda -row 2 -column 2 -sticky e
grid .paras.wal.defpc -row 3 -column 0 -sticky w -columnspan 4
grid .paras.outfmt -row 0 -column 2 -sticky w
grid .paras.outfmtsel -row 1 -column 2 -sticky ew
grid .paras.seg -row 2 -column 2 -sticky w
grid .paras.segs -row 3 -column 2 -sticky ew
grid columnconfigure .paras 0 -weight 1
grid columnconfigure .paras 1 -weight 1
grid columnconfigure .paras 2 -weight 1
pack .paras -side bottom -fill x

# File selection area
frame .files -borderwidth 1 -relief raised
label .files.fasta 	-text "FASTA File: " -anchor w
label .files.pseaac -text "Output File: " -anchor w
label .files.pcsel 	-text "Properties Selection File: " -anchor w
entry .files.fnfas -borderwidth 2 -relief sunken -textvariable infilename
entry .files.fnpse -borderwidth 2 -relief sunken -textvariable outfilename
entry .files.fnsel -borderwidth 2 -relief sunken -textvariable pcselfilename -state disabled
button .files.bfnfas -text "Browse..." -command browseFastaFile
button .files.bfnpse -text "Browse..." -command browseOutputFile
button .files.bfnsel -text "Browse..." -command browsePcFile -state disabled
grid .files.fasta	-row 0 -column 0 -sticky e
grid .files.fnfas	-row 0 -column 1 -sticky ew
grid .files.bfnfas	-row 0 -column 2 -sticky nsew
grid .files.pseaac	-row 1 -column 0 -sticky e
grid .files.fnpse	-row 1 -column 1 -sticky ew
grid .files.bfnpse	-row 1 -column 2 -sticky nsew
grid .files.pcsel	-row 2 -column 0 -sticky e
grid .files.fnsel	-row 2 -column 1 -sticky ew
grid .files.bfnsel	-row 2 -column 2 -sticky nsew
grid columnconfigure .files 1 -weight 1
pack .files -side bottom -fill x 

# Decorating the window
wm title . $appWindowTitle
wm resizable . no no

# Processing with the events
proc enableDip {} {
	.paras.aac configure -state disable
	.paras.pse configure -state disable
	.paras.aac deselect
	.paras.pse deselect
	disablePseArea
}

proc disableDip {} {
	.paras.aac configure -state normal
	.paras.pse configure -state normal
}

proc dipswitch {} {
	global usedip
	if {$usedip == 0} then	{
		disableDip
	} else {
		enableDip
	}
}

proc enablePseArea {} {
	.paras.wal.classic configure -state active
	.paras.wal.amphiphilic configure -state normal
	.paras.wal.valLambda configure -state normal
	.paras.wal.valWeight configure -state normal	
	.paras.wal.defpc configure -state normal
	.files.bfnsel configure -state normal
	.files.fnsel configure -state normal 
}

proc disablePseArea {} {
	.paras.wal.classic configure -state disable
	.paras.wal.amphiphilic configure -state disable
	.paras.wal.valLambda configure -state disable
	.paras.wal.valWeight configure -state disable
	.paras.wal.defpc configure -state disable
	.files.bfnsel configure -state disable
	.files.fnsel configure -state disable 
}

proc pseswitch {} {
	global usepse
	if {$usepse == 0} then	{
		disablePseArea
	} else {
		enablePseArea
	}
}

proc MakeAll {} {
	global errflag appWindowTitle
	makecmdline 
	if {$errflag == 0} then {
		tk_messageBox -message "Command line has been made ready, please review it and click Execute" -icon info -title $appWindowTitle
		.button_field.execute configure -state normal
	}
}

proc makecmdline {} {
	global appWindowTitle cmdline useaac usedip usepse useselfile psetype lambda weight outfmt segcnt psebExec pcselfilename infilename outfilename
	set cmdline $psebExec
	if {$useaac == 1} then {
		append cmdline " -a"
	}
	if {$usedip == 1} then {
		append cmdline " -d"
	}
	if {$usepse == 1} then {
		if {$psetype == 0} then {
			append cmdline " -t 0"
		} elseif {$psetype == 1} then {
			append cmdline " -t 1"
		}
		#check lambda and weight
		if {![string is integer $lambda]} then {
			emshow "Please enter valid digits for Lambda."
		} else {
			append cmdline " -l $lambda"
		}
		if {![string is double $weight]} then {
			emshow "Please enter valid digit for Weight." 
		} else {
			append cmdline " -w $weight"
		}
		if {$useselfile == 1} then {
			if {[file exists $pcselfilename]} then {
				append cmdline " -x $pcselfilename"
			} else {
				emshow "Please speify valid physicochemical properties selection file."
			}
		}
	}
	if {$outfmt == "SVM"} then {
		append cmdline " -m svm"
	} elseif {$outfmt == "TAB"} then {
		append cmdline " -m tab"
	} elseif {$outfmt == "CSV"} then {
		append cmdline " -m csv"
	}
	if {$segcnt != 1} then {
		append cmdline " -s $segcnt"
	}
	if {$infilename != ""} then {
		if {[file exists $infilename]} then {
			append cmdline " -i $infilename"
		} else {
			emshow "Please specify valid input file."
		}
	} else {
		emshow "Please specify input file, gui mode must have a file as input."
	}
	
	if {$outfilename != ""} then {
		if {[file writable [file dirname $outfilename]]} then {
			append cmdline " -o $outfilename"
		} else {
			emshow "Please specify writable output file."
		}
	} else {
		emshow "Please specify output file, gui mode must have a file as output."
	}
}

proc browseOutputFile {} {
	global outfilename
	set types {
		{{All Files} *}
	}
	set outfilename [tk_getSaveFile -filetypes $types]

}

proc browseFastaFile {} {
	global infilename
	set types {
		{{FASTA} {.fas}}
		{{All Files} *}
	}
	set infilename [tk_getOpenFile -filetypes $types ]
}

proc browsePcFile {} {
	global pcselfilename
	set types {
		{{All Files} *}
	}
	set pcselfilename [tk_getOpenFile -filetypes $types]
}

proc emshow {mesg} {
	global appWindowTitle errflag
	set errflag 1
	tk_messageBox -icon error -message $mesg -type ok -title $appWindowTitle	
}

proc help {} {
	global psebExec appWindowTitle
	set helptext [exec $psebExec --usage]
	tk_messageBox -message $helptext -icon info -title $appWindowTitle
}

proc executeCommand {} {
	global cmdline
	set eid [open "|$cmdline |& cat" "r"]
	fileevent $eid readable "feedError $eid"
}

proc feedError {fd} {
	global appWindowTitle
	if {[gets $fd line] >=0} then {
		.ioinfo.stderr insert end "$line\n"
	} else {
            close $fd
            # fileevent $fd readable {}
            tk_messageBox -message "Done" -icon info -title $appWindowTitle
            .button_field.execute configure -state disabled
	}
}
