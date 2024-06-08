#!/usr/bin/perl

############################### Header Information ##############################
require 'cgi.perl';
use CGI;;
$query = new CGI;
&ReadParse;
print &PrintHeader;

################################ Reads Inoput Data ##############################
$atom = $query->param('atom');
$file = $query->param('file');
$svm_th = $query->param('svm_th');

#################Validation Of Input Sequence Data (file upload) ###################################
if($file ne '' && $atom eq '')
{
    $file=~m/^.*(\\|\/)(.*)/; 
    while(<$file>) 
    {
	$seqfi .= $_;
    }
}
elsif($atom ne '' && $file eq ''){

    $seqfi="$atom";
}

##############ACTUAL PROCESS BEGINS FROM HERE#######################
$infut_file = "/webservers/cgi-bin/predlactamase";
$ran= int(rand 10000);
$dir = "/webservers/cgidocs/mkumar/temp/Ravindra/PredLactamase/predlac$ran";
system "mkdir $dir";
system "chmod 777 $dir";
$nam = 'input.'.'fasta';
open(FP1,">$dir/input_meta.fasta");
print FP1 "$seqfi\n";
#print "$seqfi\n";
close FP1;

system "/usr/bin/tr -d '\r' <$dir/input_meta.fasta >$dir/input_fi.fasta"; #Remove meta-character
system "/usr/bin/perl $infut_file/fasta.pl $dir/input_fi.fasta |/usr/bin/head -50 >$dir/input.fasta"; #Convert two line fasta file
system "/bin/grep '>' $dir/input.fasta |/usr/bin/cut -d '|' -f3 |/usr/bin/cut -d ' ' -f1 >$dir/protein_id"; #Grep protein id
system "$infut_file/pseb2-linux/src/pseb -a -i $dir/input.fasta -l 1 -o $dir/pseaacom -w 0.05 -t 0 >/dev/null"; #Convert sequence into Chou's type-1 pseudo amino acid composition.
system "/bin/sed -e 's/^0/+1/g' $dir/pseaacom |/usr/bin/cut -d '#' -f1 >$dir/pseaacom_out";
system "/usr/local/bin/svm_classify $dir/pseaacom_out $infut_file/Models/model_level1 $dir/svm_score_level1 >/dev/null";
system "/usr/local/bin/svm_classify $dir/pseaacom_out $infut_file/Models/model_classA $dir/svm_score_classA >/dev/null";
system "/usr/local/bin/svm_classify $dir/pseaacom_out $infut_file/Models/model_classB $dir/svm_score_classB >/dev/null";
system "/usr/local/bin/svm_classify $dir/pseaacom_out $infut_file/Models/model_classC $dir/svm_score_classC >/dev/null";
system "/usr/local/bin/svm_classify $dir/pseaacom_out $infut_file/Models/model_classD $dir/svm_score_classD >/dev/null";
system "/usr/bin/paste $dir/protein_id $dir/pseaacom_out $dir/svm_score_level1 $dir/svm_score_classA $dir/svm_score_classB $dir/svm_score_classC $dir/svm_score_classD |/usr/bin/tr '\t' '#' >$dir/final";
#system "chmod 777 $dir/Prediction";
#open(PREDICTION,">>$dir/Prediction") or die "$!";
#system "chmod 777 $dir/Prediction";
#print PREDICTION "Protein ID\tPrediction\n";
#close PREDICTION;
open(FINAL,"$dir/final") or die "$!";
while($line=<FINAL>)
{
    chomp($line);
    @svm=split(/\#/,$line);

    if($svm[2] < $svm_th)#Level1 prediction
    {
	#print "Non-Betalactamase\n";
	open(PREDICTION,">>$dir/Prediction") or die "$!";
	print PREDICTION "$svm[0]\tNon-Betalactamase\n";
	close PREDICTION;
    }
    else
    {
	#print "Betalactamase\n"
	if(($svm[3] >= $svm[4])&&($svm[3] >= $svm[5])&&($svm[3] >= $svm[6]))
	{
	    #print "Class A Betalactamase\n";
	    open(PREDICTION,">>$dir/Prediction") or die "$!";
	    print PREDICTION "$svm[0]\tClass A Betalactamase\n";
	    close PREDICTION;
	}
	if(($svm[4] >= $svm[3])&&($svm[4] >= $svm[5])&&($svm[4] >= $svm[6]))
	{
	    #print "Class B Betalactamase\n";
	    open(PREDICTION,">>$dir/Prediction") or die "$!";
	    print PREDICTION "$svm[0]\tClass B Betalactamase\n";
	    close PREDICTION;
	}
	if(($svm[5] >= $svm[3])&&($svm[5] >= $svm[4])&&($svm[5] >= $svm[6]))
	{
	    #print "Class C Betalactamase\n";
	    open(PREDICTION,">>$dir/Prediction") or die "$!";
	    print PREDICTION "$svm[0]\tClass C Betalactamase\n";
	    close PREDICTION;
	}
	if(($svm[6] >= $svm[3])&&($svm[6] >= $svm[4])&&($svm[6] >= $svm[5]))
	{
	    #print "Class D Betalactamase\n";
	    open(PREDICTION,">>$dir/Prediction") or die "$!";
	    print PREDICTION "$svm[0]\tClass D Betalactamase\n";
	    close PREDICTION;
	}
    }
}
close FINAL;

print  "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n";
print  "<html><HEAD>\n";
print  "<TITLE>PredLactamase::Prediction Result</TITLE>\n";
print  "<META NAME=\"description\" CONTENT=\"PredLactamase, University of Delhi South Campus, INDIA\">\n";
print  "</HEAD><body bgcolor=\"\#FFFFE0\">\n";
print  "<h2 ALIGN = \"CENTER\"> PredLactamase Prediction Result</h2>\n";
print  "<HR ALIGN =\"CENTER\"> </HR>\n";
print  "<p align=\"center\"><font size=4 color=black><b>The submitted protein/proteins belongs to <font color='red'></p>";
print "<table border='1' width='400' align='center'><tr><th>Protein ID</th><th>Prediction</th></tr>";
open(PRED,"$dir/Prediction") or die "$!";
while($pre=<PRED>)
{
    chomp($pre);
    @pred=split(/\t/,$pre);
    print "<tr align='center'><td>$pred[0]</td><td>$pred[1]</td></tr>";
}
print "</table>";
print "</font></b></font></p>\n";
print  "<p align=\"center\"><font size=3 color=black><b>Thanks for using PredLactamase Prediction Server</b></font></p>\n";
print  "<p align=\"center\"><font size=3 color=black><b>If you have any problem or suggestions please contact <a href='mailto:manish@south.du.ac.in'>Dr. Manish Kumar</a></b></font>. Please mention your job number in any communication.</p></br>\n";
print  "<p ALIGN=\"CENTER\"><b>Your job number is <font color=\"red\">$ran</b></font></p>\n";
print  "</body>\n";
print  "</html>\n";
system "chmod 000 $dir";
