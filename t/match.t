#!./perl
#
# match.t - Net::Dict testsuite for match() method
#

use Net::Dict;
use lib qw(. ./blib/lib ../blib/lib ./t);
require 'test_host.cfg';
use Env qw($VERBOSE);

$^W = 1;

my $WARNING;
my %TESTDATA;
my $defref;
my $section;
my $string;
my $dbinfo;
my %strathash;

if (defined $VERBOSE && $VERBOSE==1)
{
    print STDERR "\nVERBOSE ON\n";
}

print "1..15\n";

$SIG{__WARN__} = sub { $WARNING = join('', @_); };

#-----------------------------------------------------------------------
# Build the hash of test data from after the __DATA__ symbol
# at the end of this file
#-----------------------------------------------------------------------
while (<DATA>)
{
    if (/^==== END ====$/)
    {
	$section = undef;
	next;
    }

    if (/^==== (\S+) ====$/)
    {
        $section = $1;
        $TESTDATA{$section} = '';
        next;
    }

    next unless defined $section;

    $TESTDATA{$section} .= $_;
}

#-----------------------------------------------------------------------
# Make sure we have HOST and PORT specified
#-----------------------------------------------------------------------
if (defined($HOST) && defined($PORT))
{
    print "ok 1\n";
}
else
{
    print "not ok 1\n";
}

#-----------------------------------------------------------------------
# connect to server
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($HOST, Port => $PORT); };
if (!$@ && defined $dict)
{
    print "ok 2\n";
}
else
{
    print "not ok 2\n";
}

#-----------------------------------------------------------------------
# call match() with no arguments - should die
#-----------------------------------------------------------------------
eval { $defref = $dict->match(); };
if ($@ && $@ =~ /takes at least two arguments/)
{
    print "ok 3\n";
}
else
{
    print "not ok 3\n";
}

#-----------------------------------------------------------------------
# call match() with one arguments - should die
#-----------------------------------------------------------------------
eval { $defref = $dict->match('banana'); };
if ($@ && $@ =~ /takes at least two arguments/)
{
    print "ok 4\n";
}
else
{
    print "not ok 4\n";
}

#-----------------------------------------------------------------------
# call match() with two arguments, but word is undef
#-----------------------------------------------------------------------
$WARNING = '';
eval { $defref = $dict->match(undef, '*'); };
if (!$@
    && !defined($defref)
    && $WARNING =~ /empty pattern passed to match/)
{
    print "ok 5\n";
}
else
{
    print "not ok 5\n";
}

#-----------------------------------------------------------------------
# call match() with two arguments, but word is undef
#-----------------------------------------------------------------------
$WARNING = '';
eval { $defref = $dict->match('', '*'); };
if (!$@
    && !defined($defref)
    && $WARNING =~ /empty pattern passed to match/)
{
    print "ok 6\n";
}
else
{
    print "not ok 6\n";
}

#-----------------------------------------------------------------------
# get a list of supported strategies, render as string and compare
#-----------------------------------------------------------------------
$string = '';
eval { %strathash = $dict->strategies(); };
if (!$@
    && %strathash
    && do {
        foreach my $s (sort keys %strathash)
        {
            $string .= $s.':'.$strathash{$s}."\n";
        }
        1;
    }
    && $string eq $TESTDATA{'strats'})
{
    print "ok 7\n";
}
else
{
    print STDERR "\nTEST 7\nexpected \"", $TESTDATA{'strats'},
                 "\", got \n\"$string\"\n";
    print "not ok 7\n";
}

#-----------------------------------------------------------------------
# same as previous test, but using obsolete method name
#-----------------------------------------------------------------------
$string = '';
eval { %strathash = $dict->strats(); };
if (!$@
    && %strathash
    && do {
        foreach my $s (sort keys %strathash)
        {
            $string .= $s.':'.$strathash{$s}."\n";
        }
        1;
    }
    && $string eq $TESTDATA{'strats'})
{
    print "ok 8\n";
}
else
{
    print STDERR "\nTEST 8\nexpected \"", $TESTDATA{'strats'},
                 "\", got \n\"$string\"\n";
    print "not ok 8\n";
}

#-----------------------------------------------------------------------
# A list of words which start with "blue screen" - ie contains
# a space.
#-----------------------------------------------------------------------
eval { $defref = $dict->match('blue screen', 'prefix', '*'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{'*-prefix-blue_screen'})
{
    print "ok 9\n";
}
else
{
    print STDERR "\nTEST 9\nexpected \"", $TESTDATA{'*-prefix-blue_screen'},
                 "\", got \n\"$string\"\n";
    print "not ok 9\n";
}

#-----------------------------------------------------------------------
# A list of words which start with "blue " in the jargon dictionary.
# We've previously specified a default dictionary of foldoc,
# but we shouldn't get anything from that.
#-----------------------------------------------------------------------
$dict->setDicts('foldoc');
eval { $defref = $dict->match('blue ', 'prefix', 'jargon'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{'jargon-prefix-blue_'})
{
    print "ok 10\n";
}
else
{
    print STDERR "\nTEST 10\nexpected \"", $TESTDATA{'jargon-prefix-blue_'},
                 "\", got \n\"$string\"\n";
    print "not ok 10\n";
}

#-----------------------------------------------------------------------
# METHOD: match
# Now we do the same match, but without specifying a dictionary,
# so it should fall back on the previously specified foldoc
#-----------------------------------------------------------------------
$dict->setDicts('foldoc');
eval { $defref = $dict->match('blue ', 'prefix'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{'foldoc-prefix-blue_'})
{
    print "ok 11\n";
}
else
{
    print STDERR "\nTEST 11\nexpected \"", $TESTDATA{'foldoc-prefix-blue_'},
                 "\", got \n\"$string\"\n";
    print "not ok 11\n";
}

#-----------------------------------------------------------------------
# METHOD: match
# Look for words with apostrophe in them, in a specific dictionary
#-----------------------------------------------------------------------
eval { $defref = $dict->match("d'i", 're', 'world95'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{"world95-re-'"})
{
    print "ok 12\n";
}
else
{
    print "not ok 12\n";
}

#-----------------------------------------------------------------------
# METHOD: match
# look for all words in all dictionaries ending in "standard"
#-----------------------------------------------------------------------
eval { $defref = $dict->match("standard", 'suffix', '*'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{'*-suffix-standard'})
{
    print "ok 13\n";
}
else
{
    print STDERR "\nTEST 13\nexpected \"", $TESTDATA{'*-suffix-standard'},
                 "\", got \n\"$string\"\n";
    print "not ok 13\n";
}

#-----------------------------------------------------------------------
# METHOD: match
# Using regular expressions to find all entries in a dictionary
# of a given length
#-----------------------------------------------------------------------
eval { $defref = $dict->match('^a....................$',
                              're', 'wn'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{'web1913-re-dotmatch'})
{
    print "ok 14\n";
}
else
{
    print STDERR "\nTEST 14\nexpected \"", $TESTDATA{'web1913-re-dotmatch'},
                 "\", got \n\"$string\"\n";
    print "not ok 14\n";
}

#-----------------------------------------------------------------------
# METHOD: match
# Look for words which have a Levenshtein distance one
# from "know"
#-----------------------------------------------------------------------
eval { $defref = $dict->match('know', 'lev', '*'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); }
    && $string eq $TESTDATA{'*-lev-know'})
{
    print "ok 15\n";
}
else
{
    print STDERR "\nTEST 15\nexpected \"", $TESTDATA{'*-lev-know'},
                 "\", got \n\"$string\"\n";
    print "not ok 15\n";
}


exit 0;

#=======================================================================
#
# _format_matches()
#
# takes a reference to a list which is assumed to be the result
# from a match() - each entry in the list is a reference to
# a 2-element list: [DICTIONARY, WORD]
#
# We return a string which has one line per entry:
#        DICTIONARY:WORD
# sorted on the whole line (ie by dictionary, then by word)
#
#=======================================================================
sub _format_matches
{
    my $mref  = shift;

    my $string = '';


    foreach my $entry (sort { lc($a->[0].$a->[1]) cmp lc($b->[0].$b->[1]) } @$mref)
    {
        $string .= $entry->[0].':'.$entry->[1]."\n";
    }

    return $string;
}

__DATA__
==== strats ====
exact:Match headwords exactly
first:Match the first word within headwords
last:Match the last word within headwords
lev:Match headwords within Levenshtein distance one
nprefix:Match prefixes (skip, count)
prefix:Match prefixes
re:POSIX 1003.2 (modern) regular expressions
regexp:Old (basic) regular expressions
soundex:Match using SOUNDEX algorithm
substring:Match substring occurring anywhere in a headword
suffix:Match suffixes
word:Match separate words within headwords
==== *-exact-blue ====
easton:Blue
foldoc:Blue
gazetteer:Blue
web1913:Blue
web1913:blue
wn:blue
==== *-prefix-blue_screen ====
foldoc:blue screen of death
foldoc:blue screen of life
jargon:blue screen of death
==== jargon-prefix-blue_ ====
jargon:blue box
jargon:blue glue
jargon:blue goo
jargon:blue screen of death
jargon:blue wire
==== foldoc-prefix-blue_ ====
foldoc:blue book
foldoc:blue box
foldoc:blue dot syndrome
foldoc:blue glue
foldoc:blue screen of death
foldoc:blue screen of life
foldoc:blue sky software
foldoc:blue wire
==== world95-re-' ====
world95:Cote D'ivoire
==== *-suffix-standard ====
bouvier:STANDARD
foldoc:a tools integration standard
foldoc:advanced encryption standard
foldoc:american national standard
foldoc:binary compatibility standard
foldoc:data encryption standard
foldoc:de facto standard
foldoc:digital signature standard
foldoc:display standard
foldoc:filesystem hierarchy standard
foldoc:ieee floating point standard
foldoc:international standard
foldoc:object compatibility standard
foldoc:recommended standard
foldoc:robot exclusion standard
foldoc:standard
gaz2k-places:Standard
gcide:deficient inferior substandard
gcide:Double standard
gcide:double standard
gcide:non-standard
gcide:nonstandard
gcide:standard
gcide:Standard
jargon:ansi standard
moby-thes:standard
wn:accounting standard
wn:double standard
wn:gold standard
wn:monetary standard
wn:nonstandard
wn:procrustean standard
wn:silver standard
wn:standard
wn:substandard
==== web1913-re-dotmatch ====
wn:aaron montgomery ward
wn:abelmoschus moschatus
wn:aboriginal australian
wn:abruptly-pinnate leaf
wn:absence without leave
wn:acacia auriculiformis
wn:acid-base equilibrium
wn:acquisition agreement
wn:acute-angled triangle
wn:adams-stokes syndrome
wn:adenosine diphosphate
wn:adlai ewing stevenson
wn:advance death benefit
wn:aeronautical engineer
wn:affine transformation
wn:africanized honey bee
wn:ageratum houstonianum
wn:aglaomorpha meyeniana
wn:agnes george de mille
wn:agnes gonxha bojaxhiu
wn:agricultural labourer
wn:agriculture secretary
wn:agrippina the younger
wn:agropyron intermedium
wn:agropyron pauciflorum
wn:agropyron subsecundum
wn:air-to-ground missile
wn:airborne transmission
wn:aksa martyrs brigades
wn:albatrellus dispansus
wn:alben william barkley
wn:aldous leonard huxley
wn:aldrovanda vesiculosa
wn:alex boncayao brigade
wn:alexander archipelago
wn:alexander graham bell
wn:alexis de tocqueville
wn:alfred alistair cooke
wn:alfred bernhard nobel
wn:alfred charles kinsey
wn:alfred edward housman
wn:alfred lothar wegener
wn:alfred russel wallace
wn:alkylbenzenesulfonate
wn:allied command europe
wn:allium cepa viviparum
wn:amaranthus graecizans
wn:ambloplites rupestris
wn:ambrosia psilostachya
wn:ambystomid salamander
wn:amelanchier alnifolia
wn:american bog asphodel
wn:american mountain ash
wn:american parsley fern
wn:american pasqueflower
wn:american red squirrel
wn:american saddle horse
wn:amphitheatrum flavium
wn:amsinckia grandiflora
wn:andrew william mellon
wn:andropogon virginicus
wn:anemopsis californica
wn:angelica archangelica
wn:angolan monetary unit
wn:anogramma leptophylla
wn:anointing of the sick
wn:anterior crural nerve
wn:anterior jugular vein
wn:anterior labial veins
wn:anthriscus sylvestris
wn:anthyllis barba-jovis
wn:anti-racketeering law
wn:anti-submarine rocket
wn:anti-takeover defense
wn:antiballistic missile
wn:antigenic determinant
wn:antihemophilic factor
wn:antihypertensive drug
wn:antilocapra americana
wn:antiophthalmic factor
wn:antitrust legislation
wn:anton van leeuwenhoek
wn:antonio lucio vivaldi
wn:antonius stradivarius
wn:apalachicola rosemary
wn:apex of the sun's way
wn:aposematic coloration
wn:appalachian mountains
wn:appendicular skeleton
wn:arceuthobium pusillum
wn:archeological remains
wn:archimedes' principle
wn:arctostaphylos alpina
wn:ardisia escallonoides
wn:arenaria groenlandica
wn:ariocarpus fissuratus
wn:army of the righteous
wn:arna wendell bontemps
wn:arnold joseph toynbee
wn:arrhenatherum elatius
wn:artemisia californica
wn:artemisia dracunculus
wn:artemisia gnaphalodes
wn:artemisia ludoviciana
wn:artemisia stelleriana
wn:artemision at ephesus
wn:arteria intercostalis
wn:arterial blood vessel
wn:arthur edwin kennelly
wn:articles of agreement
wn:as luck would have it
wn:asarum shuttleworthii
wn:ascension of the lord
wn:asclepias curassavica
wn:asparagus officinales
wn:aspergillus fumigatus
wn:asplenium platyneuron
wn:asplenium trichomanes
wn:astreus hygrometricus
wn:astrophyton muricatum
wn:athyrium filix-femina
wn:atmospheric condition
wn:atrioventricular node
wn:august von wassermann
wn:augustin jean fresnel
wn:australian blacksnake
wn:australian bonytongue
wn:australian grass tree
wn:australian reed grass
wn:australian sword lily
wn:australian turtledove
wn:austronesian language
wn:automotive technology
wn:aversive conditioning
wn:avicennia officinalis
wn:avogadro's hypothesis
wn:azerbajdzhan republic
==== *-lev-know ====
easton:Knop
easton:Snow
gaz2k-counties:Knox
gaz2k-places:Knox
gcide:Aknow
gcide:Enow
gcide:Gnow
gcide:Knaw
gcide:Knew
gcide:Knob
gcide:Knop
gcide:Knor
gcide:knot
gcide:Known
gcide:Now
gcide:Snow
gcide:Ynow
moby-thes:knob
moby-thes:knot
moby-thes:now
moby-thes:snow
vera:now
wn:knob
wn:knot
wn:known
wn:knox
wn:now
wn:snow
==== END ====
