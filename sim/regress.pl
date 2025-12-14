#! /usr/bin/perl

use Getopt::Long;
my $cov;
my @tc_list;
my $pass_key_word;
my $fail_key_word;
my $start_time;
my $end_time;

GetOptions(
  'f|file=s'  => \$opt_file,
  'r|report!' => \$opt_report,
  'h|help!'   => \$opt_help,
);

main();

sub main {
  if($opt_help) {print_usage();}
  elsif($opt_report) { 
    parse_cfg();
    report();
  }
  else {
    print "Run regression...\n";
    parse_cfg();
    run_regress();
    report();
  }
}
sub run_regress {
  my $tc;
  my $seed;
  my $plusarg;
  $start_time = time();
  system "make build";
  my $size = scalar(@tc_list);
  for(my $i = 0; $i < $size; $i=$i+3) {
    $tc      = shift(@tc_list);
    $tc      =~ s/\s+//g;
    $seed    = shift(@tc_list);
    $plusarg = shift(@tc_list);
    $plusarg  =~ s/^\s+//;
    system("make run TESTNAME=$tc SEED=$seed RUNARG=$plusarg");
  $end_time = time();
  }
};
sub parse_cfg {
  my $cfg_file;
  my $tc_start;
  my $run_time;
  my $run_opts;
  my @run_string;

  if(defined $opt_file) {
    $cfg_file = $opt_file;
  }
  else {
    $cfg_file = "regress.cfg";
  }
  open(my $fh, '<',$cfg_file) or die "Can't open regress cfg file $cfg_file!\n";
  while (my $line = <$fh>) {
    chomp $line; # Remove newline 
    next if $line =~ /^#/;
    if($line =~ /^\s*cov\s*=\s*(\w+)/) {
      $cov = $1;
    }
    elsif($line =~ /pass_key_word/) {
      $pass_key_word = $line;
      $pass_key_word =~ s/pass_key_word//g;
      $pass_key_word =~ s/=//g;
    }
    elsif($line =~ /fail_key_word/) {
      $fail_key_word = $1;
      $fail_key_word = $line;
      $fail_key_word =~ s/fail_key_word//g;
      $fail_key_word =~ s/=//g;
    }
    elsif($line =~ /tc_list/) {
      $tc_start = 1;
    }
    elsif($tc_start) {
      if($line =~ /\}/) {$tc_start = 0;}
      else {
        $line =~ s/;$//; # Remove ; in last string
        @run_string = split(/,/,$line);
        $run_time = $run_string[1];
        $run_time =~ s/run_times=//g;
        $run_opts = $run_string[2];
        $run_opts =~ s/run_opts=//g;
        $run_opts =~ s/([+])/ $1/g;
        for(my $i = 0; $i < $run_time; $i++) {
          # 1 TC, 2 SEED, 3 PLUSARG
          push @tc_list, $run_string[0];
          push @tc_list, int(rand(999999 - 100000 +1)) + 100000;
          push @tc_list, $run_opts;
        }
      } 
    }
  }
}
sub report {
  my $tc_run;
  my $tc_pass;
  my $tc_fail;
  my $tc_unknown;
  my $used_time;
  
  print "Generate report...\n";
  system ("rm -rf tmp_report");
  system("grep -L -e $pass_key_word -e $fail_key_word log/*.log >> tmp_report");
  system("grep $fail_key_word log/*.log >> tmp_report");
  system("grep $pass_key_word log/*.log >> tmp_report");
  $tc_pass    = `grep $pass_key_word log/*.log | wc -l`;
  $tc_fail    = `grep $fail_key_word log/*.log | wc -l`;
  $tc_unknown = `grep -L -e $pass_key_word -e $fail_key_word log/*.log | wc -l`;
  $used_time  = $end_time - $start_time;
  $used_time  = format_time($used_time);
  $pass_key_word =~ s/"//g;
  $pass_key_word =~ s/^\s+//;

  $fail_key_word =~ s/"//g;
  $fail_key_word =~ s/^\s+//;
  # Reading file
  open(my $read_fh, '<',"tmp_report") or die "Can't open regress cfg file tmp_report!\n";
  # Writing file
  open(my $write_fh, '>', "regress.rpt") or die "Can't open regress cfg file regress.rpt!\n";
  print $write_fh "###########################################################\n";
  print $write_fh "####               ICTC Regression Report              ####\n";
  print $write_fh "###########################################################\n";
  printf $write_fh "Total testcase run: %d\n",$tc_pass + $tc_fail + $tc_unknown;
  print $write_fh "Passed            : $tc_pass";
  print $write_fh "Failed            : $tc_fail";
  print $write_fh "Unknown           : $tc_unknown";
  printf $write_fh "Used time         : $used_time\n";
  print $write_fh "-----------------------------------------------------------\n";
  print $write_fh "Run log detail:\n";

  while (my $line = <$read_fh>) {
    chomp($line);
    $line =~ s/\r//g;
    if($line =~ /\Q$pass_key_word\E/) {
      $line =~ s/#.*//;
      print $write_fh "$line => Passed\n";
    }
    elsif($line =~ /\Q$fail_key_word\E/) {
      $line =~ s/#.*//;
      print $write_fh "$line => Failed\n";
    }
    else {
      print $write_fh "$line => Unknown\n";
    }
  }
  print $write_fh "-----------------------------------------------------------\n";
  system ("rm -rf tmp_report");
}
sub print_usage {
  print <<EOF;
  This script support regression feature
  regress.pl -{options}"
    -f|file=s       : Run regression with regress.cfg file
    -r|report!      : Report regression result

  Example to run regression:
    ./regress.pl    : Start run regression with regress.cfg file
    ./regress.pl -r : Re-generate report
EOF

}

sub format_time {
    my ($seconds) = @_;
    
    if ($seconds < 60) {
        return "$seconds\s";
    } elsif ($seconds < 3600) {
        my $minutes = int($seconds / 60);
        my $remaining_seconds = $seconds % 60;
        return "$minutes\m" . ($remaining_seconds > 0 ? " $remaining_seconds\s" : "");
    } else {
        my $hours = int($seconds / 3600);
        my $remaining_minutes = int(($seconds % 3600) / 60);
        my $remaining_seconds = $seconds % 60;
        return "$hours\h" . ($remaining_minutes > 0 ? " $remaining_minutes\m" : "") . ($remaining_seconds > 0 ? " $remaining_seconds\s" : "");
    }
}
