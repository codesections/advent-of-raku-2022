#!/usr/bin/env raku


subset DayNumber of Int where 1 .. 25;

sub today-as-task-day(--> DayNumber) {
  given Date.today {
    when .month != 12 { Nil }
    when .day > 25 { Nil }
    default { .day }
  }
}

sub git-user {
  qx[git config user.name].lines[0]
}

subset Part of Str where '1' | '2' | 'both';

subset YesNo of Str where *.lc eq 'y' | 'n';

sub create-default-file(IO $path) {
  $path.spurt: "#!/usr/bin/raku\n\n"
}
my %*SUB-MAIN-OPTS = :named-anywhere;
sub MAIN(
  'run',
  Int :$d, #= number of the day to solve (1-25)
  Str :$a, #= name of the author of the solution
  Str :$p, #= which part of the task is being solved (1/2/both)
  Bool :f( :$force ) #= if the file doesn't exist, create it without prompt
) {
# Validation because CLI is underpowered...
  my DayNumber $day;
  my Part $part;
  my Str $author;
  try {
    $day = $_ with $d;
    $part = $_ with $p;
    $author = $_ with $a;
    CATCH {
      say "$*USAGE";
      return 1;
    }
  }
# Retrieving values using $*IN
  without $day {
    repeat {
      my $today = today-as-task-day;
      try {
        $_ = (prompt("Please enter the number of the day: " ~ ("[$_] " with $today)).Str || $today).Int;
      }
    } until .defined;
  }
  without $author {
    my $git-user = git-user;
    repeat {
      $_ = prompt("Please enter the name of the author: [$git-user] ").Str || $git-user;
    } until .so;
  }
  without $part {
    repeat {
      try {
        $_ = prompt("Please enter the part the solution solves (1/2/both): [both]  ").Str || 'both';
      }
    } until .defined;
  }
# Choosing the file, creating it if necessary
  my $chosen-path = sprintf('solutions/day-%02d/%s-%s.raku', $day, $author, $part).IO; 
  unless $chosen-path.f {
    my YesNo $proceed;
    $proceed = 'y' if $force;
    until $proceed.defined {
      try {
        $proceed = prompt("File $chosen-path was selected but it does not exist.\nWould you like to create it? (Y/N) ").lc;
      }
    }
    die 'The selected file does not exist.' unless $proceed;
    create-default-file $chosen-path;
    say 'The solution file is created.';
  }
  say "The solution exists at $chosen-path.";
}