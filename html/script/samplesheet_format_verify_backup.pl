#!/usr/bin/perl -w
use strict;
use List::MoreUtils qw(uniq);

my $error_code=0;
my $sequencer=$ARGV[2];

####open Samplesheet and modify the format
my $file1 = $ARGV[0];
open IN,$file1 or die $!;
while(<IN>){
	if($_=~//){
		system("dos2unix -c mac $file1");
		last;
	}else{
		next;
	}
}
close IN;


open IN,$file1 or die $!;
open OUTT,">/var/www/html/upload/tmp/SampleSheet_modified.csv" or die $!;
my @data1=<IN>;
my $count_tmp=0;
foreach my $line(@data1){
	chomp $line;
#	if($line =~ //){
#		$line =~ s//\n/g;
#		chomp $line;
#	}
	my @a = split(",",$line);
	if($sequencer eq "NovaSeq" || $sequencer eq "NextSeq_regular" || $sequencer eq "NextSeq_10x"){
		if($count_tmp == 1){
			$line=~s/ /_/g;
		}
		if($a[0] =~ /Sample_ID/){
		$count_tmp = 1;
		}
	}elsif($sequencer eq "MiSeq"){
		if($count_tmp == 1){
			$line=~s/_/-/g;
			$line=~s/ /_/g;
		}
		if($a[0] =~ /Sample_ID/){
		$count_tmp = 1;
		}
	}
	$line=~s/[\n\r\s]//g;
	print OUTT $line,"\n";
}
close IN;

#####open tmp to compare with modified Sample sheet to check whether the number of project is same as input

my $file2 = $ARGV[1];
open INN,$file2 or die $!;
my @data2=<INN>;

if($sequencer eq "NovaSeq"){
	system("sed \'1,\/Sample_ID\/d\' \/var\/www\/html\/upload\/tmp\/SampleSheet_modified\.csv|cut -d\",\" -f4|sort| uniq > \/var\/www\/html\/upload\/tmp\/samplesheet_tmp\.txt");
}elsif($sequencer eq "NextSeq_regular"){
	system("sed \'1,\/Sample_ID\/d\' \/var\/www\/html\/upload\/tmp\/SampleSheet_modified\.csv|cut -d\",\" -f3|sort| uniq > \/var\/www\/html\/upload\/tmp\/samplesheet_tmp\.txt");
}elsif($sequencer eq "NextSeq_10x"){
	system("sed \'1,\/Sample_ID\/d\' \/var\/www\/html\/upload\/tmp\/SampleSheet_modified\.csv|cut -d\",\" -f4|sort| uniq > \/var\/www\/html\/upload\/tmp\/samplesheet_tmp\.txt");
}elsif($sequencer eq "MiSeq"){
	system("sed \'1,\/Sample_ID\/d\' \/var\/www\/html\/upload\/tmp\/SampleSheet_modified\.csv|cut -d\",\" -f9|sort| uniq > \/var\/www\/html\/upload\/tmp\/samplesheet_tmp\.txt");
}	

system("sed \'1,\/Sample_ID\/d\' \/var\/www\/html\/upload\/tmp\/SampleSheet_modified\.csv > \/var\/www\/html\/upload\/tmp\/samples_tmp\.txt"); 
open INNN,"/var/www/html/upload/tmp/samplesheet_tmp.txt" or die $!;
my @data3=<INNN>;

my $count=0;
my $length1=scalar(@data3);
my $length2=scalar(@data2);
foreach my $line(@data2){
	chomp $line;
	my @a=split(" ",$line);
	$a[0]=~s/[\n\t\s]//g;
	foreach my $line2(@data3){
		chomp $line2;
		$line2=~s/[\n\t\s]//g;
		if ($a[0] eq $line2){
			$count++;
		}else{
			next;
		}
	}
}

#print "Number of projects in SampleSheet.csv: ",$length1,"\n";
#print "Number of projects input: ",$length2,"\n";
#print "Number of matched projects: ",$count,"\n";

if($count != $length1 || $count != $length2){
#	print "WARN: the number of projects input doesn't equal to the number of projects in Sample Sheet! Please double check!\n";
	$error_code=$error_code+1;
}else{
#	print "the number of projects match the Sample Sheet!\n";
#	print "Yes";
	open IN,"/var/www/html/upload/tmp/SampleSheet_modified.csv" or die $!;
	open OUT,">/var/www/html/upload/tmp/SampleSheet_for_fastq.csv" or die $!;
	my @data3=<IN>;
	my @b;
	foreach my $line1(@data3){
		chomp $line1;
		my @a=split(",",$line1);
#		if(defined($a[3])){}
		if($sequencer eq "NovaSeq" ){
			if(defined($a[3])){
				foreach my $line2(@data2){
					chomp $line2;
					@b=split(" ",$line2);
					$b[0]=~s/[\n\r\t]//g;
					if($a[3] =~ /$b[0]/){
						$a[3] = $b[1];	
					}
				}
			}
		}elsif($sequencer eq "MiSeq"){
			if(defined($a[8])){
				foreach my $line2(@data2){
					chomp $line2;
					@b=split(" ",$line2);
					$b[0]=~s/[\n\r\t]//g;
					if($a[8] =~ /$b[0]/){
						$a[8] = $b[1];	
					}
				}
			}
		}elsif($sequencer eq "NextSeq_regular" || $sequencer eq "NextSeq_10x"){
			if(defined($a[2])){
				foreach my $line2(@data2){
					chomp $line2;
					@b=split(" ",$line2);
					$b[0]=~s/[\n\r\t]//g;
					if($a[2] =~ /$b[0]/){
						$a[2] = $b[1];	
					}
				}
			}
		}	
		print OUT join(",",@a),"\n";
	}
}	

close IN;
close INN;
close INNN;
close OUT;
close OUTT;


open IN, "/var/www/html/upload/tmp/samples_tmp.txt" or die $!;
open OUT,">/var/www/html/upload/tmp/samples_tmp_report.txt" or die $!;
my @data = <IN>;
my %hash;
foreach my $line(@data){
	chomp $line;
	my @a = split(",",$line);
#	print $a[3],"\n";
#	my ($key,$value) = ($a[3],$a[1]);
	if($sequencer eq "MiSeq"){
		if($a[0]=~/[\+\\\/\.]/){
		$error_code=$error_code+2;
		last;
		}
		push (@{$hash{$a[8]}},$a[0]);
		@{$hash{$a[8]}} = uniq @{$hash{$a[8]}};
	}
	if($sequencer eq "NovaSeq"){
		if($a[1]=~/[\+\\\/\.]/){
		$error_code=$error_code+2;
		last;
		}
		push (@{$hash{$a[3]}},$a[1]);
		@{$hash{$a[3]}} = uniq @{$hash{$a[3]}};
	}
	if($sequencer eq "NextSeq_regular"){
		if($a[1]=~/[\+\\\/\.]/){
		$error_code=$error_code+2;
		last;
		}
		push (@{$hash{$a[2]}},$a[1]);
		@{$hash{$a[2]}} = uniq @{$hash{$a[2]}};
	}
	if($sequencer eq "NextSeq_10x"){
		if($a[1]=~/[\+\\\/\.]/){
		$error_code=$error_code+2;
		last;
		}
		push (@{$hash{$a[3]}},$a[1]);
		@{$hash{$a[3]}} = uniq @{$hash{$a[3]}};
	}

}

print OUT "Sample Information:\n";
foreach my $key(sort keys %hash){
	print OUT "--$key:\n";
	my $value_arr=$hash{$key};
	print OUT join(", ",@$value_arr),"\n\n";
}

close OUT;

print $error_code;
