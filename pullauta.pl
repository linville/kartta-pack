#!/usr/bin/env perl
### Karttapullautin (c) Jarkko Ryyppo. All Rights Reserved.###

use GD;
use POSIX;
use Config::Tiny;
use File::Spec;
use File::Basename;
use File::Touch;
use File::Copy;
use IPC::System::Simple qw(run capture);

$ver = '20190203';

$| = 1;    # autoflush on for progress bar

if ( -e 'pullauta.ini' ) {

    # we already have conf file
}
else {

    # lets make one with default settings
    open( ULOS, ">pullauta.ini" );
    print ULOS "

#------------------------------------------------------#
# Parameters for the Karttapullautin pullautus process #
#----------------------------------------------------- #

################## PARAMETERS #############################
# vegetation mode. New mode =0, old original (pre 20130613) mode =1 
vegemode=0

### New vegetation mapping mode parameters (vegemode 0)##
# Experimental undergrowth parameters. Smaller figures will give more undergrowth stripes
# normal undergrowth 
undergrowth=0.35

# undergrowth walk
undergrowth2=0.56

# Note, you will need to iterate this if you use this mode. with commands 'pullauta makevegenew' and then 'pullauta' you can process only this part again. 
# Elevation for hits below green. For green mapping hits below this will be calculated as points gone trough vegetation ~ ground.
greenground=0.9
greenhigh=2
topweight=0.80
vegezoffset=0
greendetectsize=3

### Here we calculate points. We can use elevation zones and factors for green. Example:
# low|high|roof|factor
# zone1=1|5|99|1  # points 1 to 5 meters will be calculates as one hit if tallest trees there as lower than 99 moters high 
# zone2=5|9|11.0|0.75 # in additon, poitns 5 to 9 meters will be calculated as 0.75 point's worth if tallest trees are lower than 11 meters.
# There can be as many zones as you like

# low|high|roof|factor
zone1=1.0|2.65|99|1
zone2=2.65|3.4|99|0.1
zone3=3.4|5.5|8|0.2


## Here we fine how sensitively we get green for different (hight or low) forest types. 
# For example tf tall forest with big trees gets too green compared to low forest, we can here tune it right. 
# roof low|roof high| greenhits/ground ratio to trigger green factor 1
thresold1=0.20|3|0.1
thresold2=3|4|0.1  
thresold3=4|7|0.1
thresold4=7|20|0.1
thresold5=20|99|0.1

## areas where scanning lines overlap we have two or three times bigger point density. That may make those areas more or less green. Use these parameters to balance it. 
# formula is:    * (1-pointvolumefactor * mydensity/averagedensity) ^ pointvolumeexponent
# so pointvolumefactor = 0 gives no balancing/effect

pointvolumefactor=0.1
pointvolumeexponent=1 

# green weighting if point is the only return - these are usually boulders or such 
# so these are only partly counted
firstandlastreturnfactor=1

# green weighting for last return - these may be vegetation but less likely that earlier returns
lastreturnfactor =1

firstandlastreturnasground=3
# green values for triggering green shades. Use high number like 99 to avoid some of the shades.
#greenshades=0.0|0.1|0.2|0.3|0.4|0.5|0.6|0.7|0.8|0.9|1.0|1.1|1.2|1.3|1.4|1.5|1.6|1.7|1.8|1.9|2.0|2.1|2.2|2.3|2.4|2.5|2.6|2.7|2.8|2.9|3.0

greenshades=0.2|0.35|0.5|0.7|1.3|2.6|4|99|99|99|99

# tone for the lightest green. 255 is white.
lightgreentone=200

# dont change this now
greendotsize=0

# block size for calculating hits-below-green ratio. use 3 if  greendetectsize is smaller than 5, if 
# it is bigger then use 1
groundboxsize=1

# green raster image filtering with median filter. Two rounds
# use 1 to do no filtering.
medianboxsize=9
medianboxsize2=1

## yellow parameters
### hits below this will be calculated as yellow
yellowheight=0.9  

### how big part or the points must be below yellowheight to trigger yellow
yellowthresold=0.9
 


#############################################
## cliff maker min height values for each cliff type. vertical drop per 1 meter horisontal distance
##  cliff1 = these cliffs will be erased if steepness is bigger than steepness value below
##  cliff2 = impassable cliff

cliff1 = 1.15
cliff2 = 2.0
cliffthin=1

cliffsteepfactor=0.38
cliffflatplace=3.5
cliffnosmallciffs=5.5

cliffdebug=0
## north lines rotation angle (clockwise) and width. Width 0 means no northlines.
northlinesangle=0
northlineswidth=0

## Form line mode, options:
# 0 = 2.5m interval, no formlines
# 1 = 2.5m interval, every second contour thin/thick
# 2 = 5m interval, with some dashed form lines in between if needed 

formline=2

# steepness parameter for form lines. Greater value gives more and smaller value gives less form lines. 
formlinesteepness=0.37

## additional lengt of form lines in vertex points
formlineaddition=17

## shortest gap in between form line ends in vertex points
minimumgap = 30

# dash and gap parameters for form lines
dashlength = 60 
gaplength =12

# interval for index contours. Used only if form line mode is 0
indexcontours=12.5

# smoothing contrors. Bigger value smoothes contours more. Default =1. Try values about between 0.5 and 3.0
smoothing = 0.7

# curviness. How curvy contours show up. default=1. Bigger value makes more curvy/exaggerated curves (reentrants and spurs)
curviness=1.1

# knoll qualification. default =0.8. range 0.0 ... 1.0  Bigger values gives less but more distinct knolls.
knolls=0.6

# xyz factors, for feet to meter conversion etc
coordxfactor=1
coordyfactor=1
coordzfactor=1

# las/laz to xyz thinning factor. For example 0.25 leaves 25% of points
thinfactor = 1

# if water classified points, this class will be drawn with blue (uncomment to enable this)
# waterclass=9

# Water eleveation, elevation lower than this gets drawn with blue (uncomment to enable this)
# waterelevation=0.15

# if buildings classified, this class will be drawn with black (uncomment to enable this)
# buildingsclass=6

# building detection. 1=on, 0=off. These will be drawn as purple with black edges. Highly experimental.
detectbuildings=0

# batch process mode, process all laz ans las files of this directory
# off=0, on=1  
batch=0

# processes
processes=2

# batch process output folder
batchoutfolder=./out

# batch process input file folder
lazfolder=./in

# If you can't get relative paths work, try absolute paths like c:/yourfolder/lasfiles

# Karttapullautin can render vector shape files. Maastotietokanta by National land survey of Finland
# does not nee configuraiton file. For rendering those leave this parameter empty.
# For other datasets like Fastighetskartan from Lantmateriet (Sweden) configuration file is needed.

vectorconf=
# vectorconf=osm.txt
# vectorconf=fastighetskartan.txt

# shape files should be in zip files and placed in batch input folder or zip 
# should drag-dropped on pullauta.exe

# maastotietokanta, do not render these levels, comma delimined
mtkskiplayers=

# uncomment this for no settlements color (skip these layers Pullautin usually draws with olive green)
# mtkskiplayers=32000,40200,62100,32410,32411,32412,32413,32414,32415,32416,32417,32418

# Color for vector buildings (RGB value 0,0,0 is black and 255,255,255 is white)
buildingcolor=0,0,0

# in bach mode, will we crop and copy also some temp files to output folder
#  folder.  1=on 0 = off. use this if you want to use vector contors and such for each tile.
  
savetempfiles=0

# in batch mode will we save the whole temp directory as it is
savetempfolders=0
			
# the interval of additonal dxf contour layer (raw, for mapping). 0 = disabled. Value 1.125 gives such interval contours 
basemapinterval=0 

# Experimental parameters. Dont chance these unless you feel like experimenting
scalefactor=1
zoffset=0
#skipknolldetection=0
				
";
    close(ULOS);
}

$Config = Config::Tiny->new;
$Config = Config::Tiny->read('pullauta.ini');

$scalefactor = 1 * $Config->{_}->{scalefactor};
if ( $scalefactor == 0 ) {
    $scalefactor = 1;
}
$mapant           = 1 * $Config->{_}->{croptokm};
$formlineaddition = 1 * $Config->{_}->{formlineaddition};
if ( $formlineaddition == 0 ) { $formlineaddition = 13; }

$minimumgap = 1 * $Config->{_}->{minimumgap};
if ( $minimumgap == 0 ) { $minimumgap = 30; }

$basemapcontours = 1 * $Config->{_}->{basemapinterval};

$med             = $Config->{_}->{medianboxsize};
$med2            = $Config->{_}->{medianboxsize2};
$groundboxsize   = $Config->{_}->{groundboxsize};
$greendetectsize = $Config->{_}->{greendetectsize};

$water     = $Config->{_}->{waterclass};
$buildings = $Config->{_}->{buildingsclass};

$waterele = $Config->{_}->{waterelevation};
if ( $waterele eq '' ) { $waterele = -999999; }

$detectbuildings = $Config->{_}->{detectbuildings};
$detectbuildings = 1 * $detectbuildings;

$buildingcolor = $Config->{_}->{buildingcolor};

$savetempfiles   = $Config->{_}->{savetempfiles};
$savetempfolders = $Config->{_}->{savetempfolders};

$vectorconf = $Config->{_}->{vectorconf};

$pvege_yellow = $Config->{_}->{vege_yellow};

$pvege_green      = $Config->{_}->{vege_green};
$greensize        = $Config->{_}->{greensize};
$pcliff1          = $Config->{_}->{cliff1};
$pcliff2          = $Config->{_}->{cliff2};
$pcliff3          = $Config->{_}->{cliff3};
$psteepness       = $Config->{_}->{steepness};
$pnorthlinesangle = $Config->{_}->{northlinesangle};
$pnorthlineswidth = $Config->{_}->{northlineswidth};

$lightgreenlimit = $Config->{_}->{lightgreenlimit};
$darkgreenlimit  = $Config->{_}->{darkgreenlimit};
$dotsize         = $Config->{_}->{greendotsize};

$gfactor       = $Config->{_}->{gfactor};
$yfactor       = $Config->{_}->{yfactor};
$wfactor       = $Config->{_}->{wfactor};
$yellowlimit   = $Config->{_}->{yellowlimit};
$fivegreen     = $Config->{_}->{fivegreens};
$zoff          = $Config->{_}->{zoffset};
$indexcontours = $Config->{_}->{indexcontours};
$indexcontours = 1 * $indexcontours;
$mtkskip       = $Config->{_}->{mtkskiplayers};
$mtkskip       = ',' . $mtkskip . ',';
$mtkskip =~ s/ //g;

$vegethin = $Config->{_}->{vegethin};
$vegethin = 1 * $vegethin;

$step = $pcliff1 * 0.9;

$xfactor      = $Config->{_}->{coordxfactor};
$coordyfactor = $Config->{_}->{coordyfactor};
$zfactor      = $Config->{_}->{coordzfactor};

$xfactor      = $xfactor * 1;
$coordyfactor = $coordyfactor * 1;
$zfactor      = $zfactor * 1;

if ( $xfactor == 0 )      { $xfactor      = 1; }
if ( $coordyfactor == 0 ) { $coordyfactor = 1; }
if ( $zfactor == 0 )      { $zfactor      = 1; }

$thinfactor = $Config->{_}->{thinfactor};
$thinfactor = 1 * $thinfactor;
if ( $thinfactor == 0 ) { $thinfactor = 1; }

$smoothing = $Config->{_}->{smoothing};
$smoothing = 1 * $smoothing;
if ( $smoothing == 0 ) { $smoothing = 1; }
$curviness = $Config->{_}->{curviness};
$curviness = 1 * $curviness;
if ( $curviness == 0 ) { $curviness = 1; }
$inidotknolls = $Config->{_}->{knolls};
if ( $inidotknolls == 0 ) { $inidotknolls = 0.8; }
$formlinesteepness = $Config->{_}->{formlinesteepness};
$formlinesteepness = 1 * $formlinesteepness;
$formline          = $Config->{_}->{formline};
$formline          = 1 * $formline;

$dashlength = $Config->{_}->{dashlength};
$gaplength  = $Config->{_}->{gaplength};

if ( $dashlength == 0 ) { $dashlength = 60; }
if ( $gaplength == 0 )  { $gaplength  = 12; }

if ( $formline > 0 ) { $indexcontours = 25; }
$batch             = $Config->{_}->{batch};
$batchoutfolder    = $Config->{_}->{batchoutfolder};
$batchoutfolderwin = $batchoutfolder;

#$batchoutfolderwin =~ s/\//\\/g;
#$batchoutfolder    =~ s/\\/\//g;

$lazfolder = $Config->{_}->{lazfolder};

#$lazfolder =~ s/\//\\/g;

if ( $lazfolder ne '' ) {
    $lazfolder = $lazfolder . "/";
    $lazfolder =~ s/\\\\/\\/g;
}

$vegemode = 0;
$Config->{_}->{vegemode};

#$vegemode = 1 * $vegemode;
$proc = $Config->{_}->{processes};

$command = $ARGV[0];
if ( $command eq ( 1 * $command ) && $command ne '' ) {

    # first parameter is thread number

    $thread = $command;
    for ( $i = 0 ; $i < $#ARGV ; $i++ ) {
        $ARGV[$i] = $ARGV[ $i + 1 ];
    }
    $last    = pop(@ARGV);
    $command = $ARGV[0];
}
$tempfolder = "temp$thread";

if (   $command eq ''
    || $command =~ /.laz/i
    || $command =~ /.las/i
    || $command =~ /.xyz/i )
{
    print
      "Karttapullautin v. $ver (c) Jarkko Ryyppo 2012-19  All rights reserved.
This exe is free for non commercial use or if used for for navsport 
mapping (orienteering, rogaining, adventure racing mapping).
There is no warranty. Use it at your own risk!\n";
}

if ( $command eq '' && -e $tempfolder . '/vegetation.png' && $batch == 0 ) {
    print "\nRendering png map with depressions\n";
    system("pullauta render $pnorthlinesangle $pnorthlineswidth ");
    print "\nRendering png map without depressions\n";
    system(
        "pullauta render $pnorthlinesangle $pnorthlineswidth  nodepressions");

    print "\n\nAll done!\n";
    exit;
}

if ( $command eq '' && $batch == 0 ) {

    print "\nUSAGE:

pullauta [parameter 1] [parameter 2] [parameter 3] ... [parameter n]

See readme.txt for more details

";
    exit;
}

if ( $command eq 'groundfix' ) {
    use GD;
    use POSIX;

    $| = 1;

    $size = 1 * $ARGV[1];

    print ".. $size ";
    $xmax = '';
    $ymax = '';
    $xmin = '';
    $ymin = '';
    $hmin = 999999;
    $hmax = -999999;

    open( SISAAN, "<" . $tempfolder . "/xyztemp.xyz" );

    while ( $rec = <SISAAN> ) {

        @r = split( / /, $rec );
        if ( $r[3] == 2 ) {
            if ( $xmin ne '' ) {
                if ( $r[0] < $xmin ) { $xmin = $r[0]; }
            }
            else { $xmin = $r[0]; }
            if ( $xmax ne '' ) {
                if ( $r[0] > $xmax ) { $xmax = $r[0]; }
            }
            else { $xmax = $r[0]; }
            if ( $ymin ne '' ) {
                if ( $r[1] < $ymin ) { $ymin = $r[1]; }
            }
            else { $ymin = $r[1]; }
            if ( $ymax ne '' ) {
                if ( $r[1] > $ymax ) { $ymax = $r[1]; }
            }
            else { $ymax = $r[1]; }

            if ( $r[2] > $hmax ) { $hmax = $r[2]; }
            if ( $r[2] < $hmin ) { $hmin = $r[2]; }
        }
    }

    close SISAAN;

    print "..";

    $img = newFromPng GD::Image( 'ground.png', 1 );
    ( $w, $h ) = $img->getBounds();

    for ( $x = 1 ; $x < $w ; $x++ ) {

        for ( $y = 1 ; $y < $h ; $y++ ) {

            ( $r, $g, $b ) = $img->rgb( $img->getPixel( $x, $y ) );
            if ( $r != $g || $r != $b || $b != $g ) {
                print "$r, $g, $b ($x $y)\n";
                $m[ floor( $x / $size ) ][ floor( $y / $size ) ] = 1;
            }
        }
    }

    print "..";
    open( SISAAN, "<" . $tempfolder . "/xyztemp.xyz" );

    while ( $rec = <SISAAN> ) {

        @r = split( / /, $rec );

        if (   $r[3] == 2
            && $m[ floor( ( $r[0] - $xmin ) / $size ) ]
            [ floor( ( $ymax - $r[1] ) / $size ) ] == 1 )
        {
            $m[ floor( ( $r[0] - $xmin ) / $size ) ]
              [ floor( ( $ymax - $r[1] ) / $size ) ] = '';

        }

    }
    close SISAAN;
    print "..";
    open( SISAAN, "<" . $tempfolder . "/xyztemp.xyz" );

    while ( $rec = <SISAAN> ) {

        @r = split( / /, $rec );

        if ( $m[ floor( ( $r[0] - $xmin ) / $size ) ]
            [ floor( ( $ymax - $r[1] ) / $size ) ] ne '' )
        {
            @point = split(
                / /,
                $m[ floor( ( $r[0] - $xmin ) / $size ) ]
                  [ floor( ( $ymax - $r[1] ) / $size ) ]
            );
            if (   $point[2] > $r[2]
                || $m[ floor( ( $r[0] - $xmin ) / $size ) ]
                [ floor( ( $ymax - $r[1] ) / $size ) ] eq '1' )
            {
                $m[ floor( ( $r[0] - $xmin ) / $size ) ]
                  [ floor( ( $ymax - $r[1] ) / $size ) ] = $rec;
            }
        }

    }
    close SISAAN;

    ###
    print "..";
    open( SISAAN, "<" . $tempfolder . "/xyztemp.xyz" );
    open( ULOS,   ">xyztempfixed.xyz" );

    while ( $rec = <SISAAN> ) {

        print ULOS $rec;

    }
    close SISAAN;
    print "..";
    for ( $x = 1 ; $x < $w / $size ; $x++ ) {

        for ( $y = 1 ; $y < $h / $size ; $y++ ) {
            if ( $m[$x][$y] ne '' && $m[$x][$y] ne '1' ) {
                @point = split( / /, $m[$x][$y] );

                $point[3] = 2;
                $out = join( ' ', @point );
                $out =~ s/\n//g;
                $out =~ s/\r//g;
                $out .= "\n";
                print ULOS $out;

                #print $out;

            }
        }
    }
    close ULOS;
    print ".. done\n";
    exit;
}

if ( $command eq 'profile' ) {
    use POSIX;

    use GD;

    $xpix = 1 * $ARGV[1];
    $ypix = 1 * $ARGV[2];
    $tile = $ARGV[4];

    $img   = new GD::Image( 1000, 1000 );
    $wh    = $img->colorAllocate( 255, 255, 255 );
    $gr    = $img->colorAllocate( 0,   180, 0 );
    $br    = $img->colorAllocate( 150, 77,  7 );
    $last  = $img->colorAllocate( 150, 0,   150 );
    $flast = $img->colorAllocate( 250, 0,   0 );

    $img2  = new GD::Image( 1000, 1000 );
    $wh    = $img2->colorAllocate( 255, 255, 255 );
    $gr    = $img2->colorAllocate( 0,   180, 0 );
    $br    = $img2->colorAllocate( 150, 77,  7 );
    $last  = $img2->colorAllocate( 150, 0,   150 );
    $flast = $img2->colorAllocate( 250, 0,   0 );
    open( SISAAN, "<pullautus_depr" . $tile . ".pgw" );
    @d = <SISAAN>;
    close SISAAN;
    $res = $d[0] * 1;
    $x0  = $d[4] * 1;
    $y0  = $d[5] * 1;

    if ( $ARGV[3] ne 'm' ) {
        $x = $xpix * $res + $x0;
        $y = $y0 - $ypix * $res;
    }
    else {
        $x = $xpix;
        $y = $ypix;
    }

    $z          = '';
    $z2         = '';
    $tempfolder = 'temp' . $tile . '/';

    open( SISAAN, "<" . $tempfolder . "xyztemp.xyz" );

    while ( $rec = <SISAAN> ) {
        @r = split( / /, $rec );
###
        if (   $r[0] > $x - 50
            && $r[1] > $y - 2.5
            && $r[0] < $x + 50
            && $r[1] < $y + 2.5 )
        {
            if ( $z eq '' ) {
                $z = $r[2];
            }
            if ( $r[3] == 2 ) {
                $c = $br;
            }
            else {
                $c = $gr;
                if ( $r[4] == $r[5] ) {
                    $c = $last;
                    if ( $r[4] == 1 ) {
                        $c = $flast;
                    }
                }

            }
            $img->setPixel( ( $r[0] - $x + 50 ) * 10,
                600 - ( $r[2] - $z ) * 10, $c );
            $img->setPixel( ( $r[0] - $x + 50 ) * 10 + 1,
                600 - ( $r[2] - $z ) * 10, $c );
            $img->setPixel( ( $r[0] - $x + 50 ) * 10,
                600 - ( $r[2] - $z ) * 10 + 1, $c );
            $img->setPixel( ( $r[0] - $x + 50 ) * 10 + 1,
                600 - ( $r[2] - $z ) * 10 + 1, $c );

            #print ''.(($r[0] - $x)*10).' '.( 600-($r[2] - $z)*10)."\n";
        }
###
        if (   $r[0] > $x - 2.5
            && $r[1] > $y - 50
            && $r[0] < $x + 2.5
            && $r[1] < $y + 50 )
        {
            if ( $z2 eq '' ) {
                $z2 = $r[2];
            }
            if ( $r[3] == 2 ) {
                $c = $br;
            }
            else {
                $c = $gr;
                if ( $r[4] == $r[5] ) {
                    $c = $last;
                    if ( $r[4] == 1 ) {
                        $c = $flast;
                    }
                }

            }
            $img2->setPixel( ( $r[1] - $y + 50 ) * 10,
                600 - ( $r[2] - $z2 ) * 10, $c );
            $img2->setPixel( ( $r[1] - $y + 50 ) * 10 + 1,
                600 - ( $r[2] - $z2 ) * 10, $c );
            $img2->setPixel( ( $r[1] - $y + 50 ) * 10,
                600 - ( $r[2] - $z2 ) * 10 + 1, $c );
            $img2->setPixel( ( $r[1] - $y + 50 ) * 10 + 1,
                600 - ( $r[2] - $z2 ) * 10 + 1, $c );

            #print ''.(($r[0] - $x)*10).' '.( 600-($r[2] - $z)*10)."\n";
        }

    }
    close SISAAN;

    $myImage = newFromPng GD::Image( "pullautus_depr" . $tile . ".png" );

    $img->copyResized(
        $myImage, 0, 0,
        $xpix - 70 / $res,
        $ypix - 70 / $res,
        200, 200,
        70 / $res * 2,
        70 / $res * 2
    );

    $img->rectangle( 28, 92, 28 + 144, 92 + 17, $br );

    open( ULOS, ">profile_WE.png" );
    binmode ULOS;
    print ULOS $img->png;
    close ULOS;

    $tempimg = new GD::Image( 200, 200 );
    $tempimg->copyResized(
        $myImage, 0, 0,
        $xpix - 70 / $res,
        $ypix - 70 / $res,
        200, 200,
        70 / $res * 2,
        70 / $res * 2
    );
    $tempimg2 = new GD::Image( 200, 200 );
    $tempimg2 = $tempimg->copyRotate90();
    $img2->copy( $tempimg2, 0, 0, 0, 0, 200, 200 );
    $img2->rectangle( 28, 92, 28 + 144, 92 + 17, $br );

    open( ULOS, ">profile_SN.png" );
    binmode ULOS;
    print ULOS $img2->png;
    close ULOS;

}
if ( $command eq 'ground' ) {
    use GD;
    use POSIX;

    $xmax = '';
    $ymax = '';
    $xmin = '';
    $ymin = '';
    $hmin = 999999;
    $hmax = -999999;

    open( SISAAN, "<" . $tempfolder . "/xyztemp.xyz" );

    while ( $rec = <SISAAN> ) {

        @r = split( / /, $rec );
        if ( $r[3] == 2 ) {
            if ( $xmin ne '' ) {
                if ( $r[0] < $xmin ) { $xmin = $r[0]; }
            }
            else { $xmin = $r[0]; }
            if ( $xmax ne '' ) {
                if ( $r[0] > $xmax ) { $xmax = $r[0]; }
            }
            else { $xmax = $r[0]; }
            if ( $ymin ne '' ) {
                if ( $r[1] < $ymin ) { $ymin = $r[1]; }
            }
            else { $ymin = $r[1]; }
            if ( $ymax ne '' ) {
                if ( $r[1] > $ymax ) { $ymax = $r[1]; }
            }
            else { $ymax = $r[1]; }

            if ( $r[2] > $hmax ) { $hmax = $r[2]; }
            if ( $r[2] < $hmin ) { $hmin = $r[2]; }
        }
    }

    close SISAAN;

    print "..";

    $img   = new GD::Image( floor( $xmax - $xmin ), floor( $ymax - $ymin ) );
    $white = $img->colorAllocate( 255, 255, 255 );
    $black = $img->colorAllocate( 0,   0,   0 );

    open( SISAAN, "<" . $tempfolder . "/xyztemp.xyz" );

    while ( $rec = <SISAAN> ) {

        @r = split( / /, $rec );

        if ( $r[3] == 2 ) {
            $img->line(
                ( $r[0] - $xmin ),
                ( $ymax - $r[1] ),
                ( $r[0] - $xmin ),
                ( $ymax - $r[1] ),
                $black
            );
        }

    }
    close SISAAN;

    open( IMAGE, ">ground.png" );

    binmode IMAGE;
    print IMAGE $img->png;
    close IMAGE;
    exit;
}

if ( $command eq 'ground2' ) {
    use GD;
    use POSIX;

    $xmax = '';
    $ymax = '';
    $xmin = '';
    $ymin = '';
    $hmin = 999999;
    $hmax = -999999;

    open( SISAAN, "<" . $tempfolder . "/xyztemp.xyz" );

    while ( $rec = <SISAAN> ) {

        @r = split( / /, $rec );
        if ( $r[3] == 2 ) {
            if ( $xmin ne '' ) {
                if ( $r[0] < $xmin ) { $xmin = $r[0]; }
            }
            else { $xmin = $r[0]; }
            if ( $xmax ne '' ) {
                if ( $r[0] > $xmax ) { $xmax = $r[0]; }
            }
            else { $xmax = $r[0]; }
            if ( $ymin ne '' ) {
                if ( $r[1] < $ymin ) { $ymin = $r[1]; }
            }
            else { $ymin = $r[1]; }
            if ( $ymax ne '' ) {
                if ( $r[1] > $ymax ) { $ymax = $r[1]; }
            }
            else { $ymax = $r[1]; }

            if ( $r[2] > $hmax ) { $hmax = $r[2]; }
            if ( $r[2] < $hmin ) { $hmin = $r[2]; }
        }
    }

    close SISAAN;

    print "..";
    open( SISAAN, "<" . $tempfolder . "/xyz2.xyz" );
    @d = <SISAAN>;
    close SISAAN;

    @r1   = split( / /, $d[0] );
    @r2   = split( / /, $d[1] );
    $size = $r2[1] - $r1[1];
    print " $r2[1] - $r1[1] ";
    $xstart = $r1[0];
    $ystart = $r1[1];
    $sxmax  = -9999999999;
    $symax  = -9999999999;

    foreach $rec (@d) {
        @r = split( / /, $rec );

        $xyz[ floor( ( $r[0] - $xstart ) / $size ) ]
          [ floor( ( $r[1] - $ystart ) / $size ) ] = 1 * $r[2];
        if (   floor( ( $r[0] - $xstart ) / $size ) < 0
            || floor( ( $r[1] - $ystart ) / $size ) < 0 )
        {
            print "error";
            exit;
        }
        if ( $sxmax < floor( ( $r[0] - $xstart ) / $size ) ) {
            $sxmax = floor( ( $r[0] - $xstart ) / $size );
        }
        if ( $symax < floor( ( $r[1] - $ystart ) / $size ) ) {
            $symax = floor( ( $r[1] - $ystart ) / $size );
        }
        $c++;
    }
    print ".." . $tempfolder . ' ' . $size . '.';

    $img   = new GD::Image( floor( $xmax - $xmin ), floor( $ymax - $ymin ) );
    $white = $img->colorAllocate( 255, 255, 255 );
    $black = $img->colorAllocate( 0,   0,   0 );

    open( SISAAN, "<" . $tempfolder . "/xyztemp.xyz" );

    while ( $rec = <SISAAN> ) {

        @r = split( / /, $rec );

        if ( $r[0] > $xmin && $r[1] > $ymin ) {

            $a = $xyz[ floor( ( $r[0] - $xmin ) / $size ) ]
              [ floor( ( $r[1] - $ymin ) / $size ) ];
            $b = $xyz[ floor( ( $r[0] - $xmin ) / $size ) + 1 ]
              [ floor( ( $r[1] - $ymin ) / $size ) ];
            $c = $xyz[ floor( ( $r[0] - $xmin ) / $size ) ]
              [ floor( ( $r[1] - $ymin ) / $size ) + 1 ];
            $d = $xyz[ floor( ( $r[0] - $xmin ) / $size ) + 1 ]
              [ floor( ( $r[1] - $ymin ) / $size ) + 1 ];

            $distx =
              ( $r[0] - $xmin ) / $size - floor( ( $r[0] - $xmin ) / $size );
            $disty =
              ( $r[1] - $ymin ) / $size - floor( ( $r[1] - $ymin ) / $size );

            $ab = $a * ( 1 - $distx ) + $b * $distx;
            $cd = $c * ( 1 - $distx ) + $d * $distx;

            $thelele = $ab * ( 1 - $disty ) + $cd * $disty;

            if ( $thelele < $r[2] + 0.25 ) {
                $img->line(
                    ( $r[0] - $xmin ),
                    ( $ymax - $r[1] ),
                    ( $r[0] - $xmin ),
                    ( $ymax - $r[1] ),
                    $black
                );
            }
        }
    }
    close SISAAN;

    open( IMAGE, ">ground2.png" );

    binmode IMAGE;
    print IMAGE $img->png;
    close IMAGE;
    exit;
}

if ( $command eq 'blocks' ) {
    use GD;
    use POSIX;

    $xmax = '';
    $ymax = '';
    $xmin = '';
    $ymin = '';
    $hmin = 999999;
    $hmax = -999999;

    open( SISAAN, "<" . $tempfolder . "/xyz2.xyz" );

    $rec       = <SISAAN>;
    @r1        = split( / /, $rec );
    $rec       = <SISAAN>;
    @r2        = split( / /, $rec );
    $size      = $r2[1] - $r1[1];
    $xstartxyz = $r1[0];
    $ystartxyz = $r1[1];
    close SISAAN;
    $xmax = 0;
    $ymax = 0;

    open( SISAAN, "<" . $tempfolder . "/xyz2.xyz" );

    while ( $rec = <SISAAN> ) {
        @r = split( / /, $rec );

        $xyz[ floor( ( $r[0] - $xstartxyz ) / $size ) ]
          [ floor( ( $r[1] - $ystartxyz ) / $size ) ] = 1 * $r[2];
        if (   floor( ( $r[0] - $xstartxyz ) / $size ) < 0
            || floor( ( $r[1] - $ystartxyz ) / $size ) < 0 )
        {
            print "error";
            exit;
        }

        if ( $xmax < floor( ( $r[0] - $xstartxyz ) / $size ) ) {
            $xmax = floor( ( $r[0] - $xstartxyz ) / $size );
        }
        if ( $ymax < floor( ( $r[1] - $ystartxyz ) / $size ) ) {
            $ymax = floor( ( $r[1] - $ystartxyz ) / $size );
        }
        $c++;
    }
    print "..";
    undef @d;

    $img   = new GD::Image( $xmax * 2, $ymax * 2 );
    $white = $img->colorAllocate( 255, 255, 255 );
    $black = $img->colorAllocate( 0,   0,   0 );
    $img2  = new GD::Image( $xmax * 2, $ymax * 2 );
    $white = $img2->colorAllocate( 255, 255, 255 );
    $black = $img2->colorAllocate( 0,   0,   0 );
    $img2->filledRectangle( 0, 0, $xmax * 2 + 1, $ymax * 2 + 1, $black );

    open( SISAAN, "<" . $tempfolder . "/xyztemp.xyz" );

    while ( $rec = <SISAAN> ) {

        @r = split( / /, $rec );

        if (   $r[3] != 2
            && $r[3] != 9
            && $r[4] == 1
            && $r[5] == 1
            && $r[2] > 2.0 + $xyz[ floor( ( $r[0] - $xstartxyz ) / $size ) ]
            [ floor( ( $r[1] - $ystartxyz ) / $size ) ] )
        {

#$img->line(( $r[0]-$xmin ),( $ymax-$r[1]),( $r[0]-$xmin ),( $ymax-$r[1]), $black );
            $img->filledRectangle(
                $r[0] - $xstartxyz - 1,
                $ystartxyz + 2 * $ymax - $r[1] - 1,
                $r[0] - $xstartxyz + 1,
                $ystartxyz + 2 * $ymax - $r[1] + 1,
                $black
            );
        }
        else {

#$img->line(( $r[0]-$xmin ),( $ymax-$r[1]),( $r[0]-$xmin ),( $ymax-$r[1]), $black );
            $img2->filledRectangle(
                $r[0] - $xstartxyz - 1,
                $ystartxyz + 2 * $ymax - $r[1] - 1,
                $r[0] - $xstartxyz + 1,
                $ystartxyz + 2 * $ymax - $r[1] + 1,
                $white
            );
        }
    }
    close SISAAN;

    $img2->transparent($black);
    $img->copy( $img2, 0, 0, 0, 0, $xmax * 2 + 1, $ymax * 2 + 1 );

    # desparcle 1
    for ( $x = 0 ; $x < $xmax * 2 + 1 ; $x++ ) {
        for ( $y = 0 ; $y < $ymax * 2 + 1 ; $y++ ) {
            ( $r0, $g, $b ) = $img->rgb( $img->getPixel( $i, $j ) );
            $count = 0;
            for ( $i = $x - 1 ; $i < $x + 2 ; $i++ ) {
                for ( $j = $y - 1 ; $j < $y + 2 ; $j++ ) {
                    ( $r, $g, $b ) = $img->rgb( $img->getPixel( $i, $j ) );
                    if ( $r > 0 ) {
                        $count++;
                    }
                }
            }
            if ( $r0 == 0 && $count > 4 ) {
                $img->setPixel( $x, $y, $white );
            }

            if ( $r0 == 255 && $count < 5 ) {
                $img->setPixel( $x, $y, $black );
            }

        }
    }

    # desparcle 2
    for ( $x = 0 ; $x < $xmax * 2 + 1 ; $x++ ) {
        for ( $y = 0 ; $y < $ymax * 2 + 1 ; $y++ ) {
            ( $r0, $g, $b ) = $img->rgb( $img->getPixel( $x, $y ) );
            $count = 0;
            for ( $i = $x - 1 ; $i < $x + 2 ; $i++ ) {
                for ( $j = $y - 1 ; $j < $y + 2 ; $j++ ) {
                    ( $r, $g, $b ) = $img->rgb( $img->getPixel( $i, $j ) );
                    if ( $r > 0 ) {
                        $count++;
                    }
                }
            }
            if ( $r0 == 0 && $count > 4 ) {
                $img->setPixel( $x, $y, $white );
            }

            if ( $r0 == 255 && $count < 5 ) {
                $img->setPixel( $x, $y, $black );
            }

        }
    }

    # desparcle 3
    for ( $x = 0 ; $x < $xmax * 2 + 1 ; $x++ ) {
        for ( $y = 0 ; $y < $ymax * 2 + 1 ; $y++ ) {
            ( $r0, $g, $b ) = $img->rgb( $img->getPixel( $x, $y ) );
            $count = 0;
            for ( $i = $x - 1 ; $i < $x + 2 ; $i++ ) {
                for ( $j = $y - 1 ; $j < $y + 2 ; $j++ ) {
                    ( $r, $g, $b ) = $img->rgb( $img->getPixel( $i, $j ) );
                    if ( $r > 0 ) {
                        $count++;
                    }
                }
            }
            if ( $r0 == 0 && $count > 4 ) {
                $img->setPixel( $x, $y, $white );
            }

            if ( $r0 == 255 && $count < 5 ) {
                $img->setPixel( $x, $y, $black );
            }

        }
    }

    # desparcle 4
    for ( $x = 0 ; $x < $xmax * 2 + 1 ; $x++ ) {
        for ( $y = 0 ; $y < $ymax * 2 + 1 ; $y++ ) {
            ( $r0, $g, $b ) = $img->rgb( $img->getPixel( $x, $y ) );
            $count = 0;
            for ( $i = $x - 1 ; $i < $x + 2 ; $i++ ) {
                for ( $j = $y - 1 ; $j < $y + 2 ; $j++ ) {
                    ( $r, $g, $b ) = $img->rgb( $img->getPixel( $i, $j ) );
                    if ( $r > 0 ) {
                        $count++;
                    }
                }
            }
            if ( $r0 == 0 && $count > 4 ) {
                $img->setPixel( $x, $y, $white );
            }

            if ( $r0 == 255 && $count < 5 ) {
                $img->setPixel( $x, $y, $black );
            }

        }
    }
    open( IMAGE, ">" . $tempfolder . "/blocks.png" );

    binmode IMAGE;
    print IMAGE $img->png;
    close IMAGE;
    print "..\n";
    exit;
}

if ( $command eq 'dxfmerge' || $command eq 'merge' ) {

    use File::stat;

    @dxflist_with_dirs =
      map { File::Spec->canonpath($_) } glob( $batchoutfolder . '/*.dxf' );
    @dxflist = map { basename($_) } @dxflist_with_dirs;
    $dxflist = join( " ", @dxflist_with_dirs );

## contours
    open( ULOS2, ">merged.dxf" );
    open( ULOS,  ">merged_contours.dxf" );
    foreach $dx (@dxflist) {
        chomp($dx);

        $dxf = $batchoutfolder . "/" . $dx;
        if ( -e $dxf && ( $dxf =~ /contours.dxf/i ) ) {
            open( SISAAN, "<$dxf" );
            @dxf = <SISAAN>;
            close(SISAAN);
            $d = join( '', @dxf );
            if ( $d =~ /POLYLINE/ ) {
                ( $head, $d )      = split( /POLYLINE/, $d, 2 );
                ( $d,    $footer ) = split( /ENDSEC/,   $d, 2 );

                if ( $headprinted eq '' ) {
                    $headout = $head;
                    print ULOS $headout;
                    print ULOS2 $headout;
                    $headprinted = 1;
                }
                print ULOS 'POLYLINE';
                print ULOS $d;
                @plines = split( /POLYLINE/, $d );
                foreach $pl (@plines) {
                    if ( $pl =~ /_intermed/ ) {
                    }
                    else {
                        print ULOS2 'POLYLINE';
                        print ULOS2 $pl;
                    }
                }
            }
        }
    }
    print ULOS 'ENDSEC' . $footer;
    close ULOS;

###
    $headprinted = '';
##cliffs
    open( ULOS, ">merged_c2.dxf" );
    foreach $dx (@dxflist) {
        chomp($dx);

        $dxf = $batchoutfolder . "/" . $dx;
        if ( -e $dxf && ( $dxf =~ /\_c2g.dxf/i ) ) {
            open( SISAAN, "<$dxf" );
            @dxf = <SISAAN>;
            close(SISAAN);
            $d = join( '', @dxf );
            if ( $d =~ /POLYLINE/ ) {
                ( $head, $d )      = split( /POLYLINE/, $d, 2 );
                ( $d,    $footer ) = split( /ENDSEC/,   $d, 2 );

                if ( $headprinted eq '' ) {
                    print ULOS $headout;
                    $headprinted = 1;
                }
                print ULOS 'POLYLINE';
                print ULOS $d;
                print ULOS2 'POLYLINE';
                print ULOS2 $d;
            }
        }
    }
    print ULOS 'ENDSEC' . $footer;
    close ULOS;
### basemap
    if ( $basemapcontours > 0 ) {
        $headprinted = '';
        open( ULOS, ">merged_basemap.dxf" );
        foreach $dx (@dxflist) {
            chomp($dx);

            $dxf = $batchoutfolder . "/" . $dx;
            if ( -e $dxf && ( $dxf =~ /\_basemap.dxf/i ) ) {
                open( SISAAN, "<$dxf" );
                @dxf = <SISAAN>;
                close(SISAAN);
                $d = join( '', @dxf );
                if ( $d =~ /POLYLINE/ ) {
                    ( $head, $d )      = split( /POLYLINE/, $d, 2 );
                    ( $d,    $footer ) = split( /ENDSEC/,   $d, 2 );

                    if ( $headprinted eq '' ) {
                        print ULOS $headout;
                        $headprinted = 1;
                    }
                    print ULOS 'POLYLINE';
                    print ULOS $d;
                    print ULOS2 'POLYLINE';
                    print ULOS2 $d;
                }
            }
        }
        print ULOS 'ENDSEC' . $footer;
        close ULOS;
    }
#####
###
    $headprinted = '';
    open( ULOS, ">merged_c3.dxf" );
    foreach $dx (@dxflist) {
        chomp($dx);

        $dxf = $batchoutfolder . "/" . $dx;
        if ( -e $dxf && ( $dxf =~ /\_c3g.dxf/i ) ) {
            open( SISAAN, "<$dxf" );
            @dxf = <SISAAN>;
            close(SISAAN);
            $d = join( '', @dxf );
            if ( $d =~ /POLYLINE/ ) {
                ( $head, $d )      = split( /POLYLINE/, $d, 2 );
                ( $d,    $footer ) = split( /ENDSEC/,   $d, 2 );

                if ( $headprinted eq '' ) {
                    print ULOS $headout;
                    $headprinted = 1;
                }
                print ULOS 'POLYLINE';
                print ULOS $d;
                print ULOS2 'POLYLINE';
                print ULOS2 $d;
            }
        }
    }
    print ULOS 'ENDSEC' . $footer;
    close ULOS;
#####
### formlines
    $headprinted = '';
    open( ULOS, ">formlines.dxf" );
    foreach $dx (@dxflist) {
        chomp($dx);

        $dxf = $batchoutfolder . "/" . $dx;
        if ( -e $dxf && ( $dxf =~ /\_formlines.dxf/i ) ) {
            open( SISAAN, "<$dxf" );
            @dxf = <SISAAN>;
            close(SISAAN);
            $d = join( '', @dxf );
            if ( $d =~ /POLYLINE/ ) {
                ( $head, $d )      = split( /POLYLINE/, $d, 2 );
                ( $d,    $footer ) = split( /ENDSEC/,   $d, 2 );

                if ( $headprinted eq '' ) {
                    print ULOS $headout;
                    $headprinted = 1;
                }
                print ULOS 'POLYLINE';
                print ULOS $d;
                print ULOS2 'POLYLINE';
                print ULOS2 $d;
            }
        }
    }
    print ULOS 'ENDSEC' . $footer;
    close ULOS;
#####
## dotknolls
    $headprinted = '';
    open( ULOS, ">merged_dotknolls.dxf" );
    foreach $dx (@dxflist) {
        chomp($dx);

        $dxf = $batchoutfolder . "/" . $dx;
        if ( -e $dxf && ( $dxf =~ /\_dotknolls.dxf/i ) ) {
            open( SISAAN, "<$dxf" );
            @dxf = <SISAAN>;
            close(SISAAN);
            $d = join( '', @dxf );
            if ( $d =~ /POINT/ ) {
                ( $head, $d )      = split( /POINT/,  $d, 2 );
                ( $d,    $footer ) = split( /ENDSEC/, $d, 2 );

                if ( $headprinted eq '' ) {
                    print ULOS $headout;
                    $headprinted = 1;
                }
                print ULOS 'POINT';
                print ULOS $d;
                print ULOS2 'POINT';
                print ULOS2 $d;

            }
        }
    }
    print ULOS 'ENDSEC' . $footer;
    close ULOS;
###
    $headprinted = '';
    open( ULOS, ">merged_detected.dxf" );
    foreach $dx (@dxflist) {
        chomp($dx);

        $dxf = $batchoutfolder . "/" . $dx;
        if ( -e $dxf && ( $dxf =~ /\_detected.dxf/i ) ) {
            open( SISAAN, "<$dxf" );
            @dxf = <SISAAN>;
            close(SISAAN);
            $d = join( '', @dxf );
            if ( $d =~ /POLYLINE/ ) {
                ( $head, $d )      = split( /POLYLINE/, $d, 2 );
                ( $d,    $footer ) = split( /ENDSEC/,   $d, 2 );

                if ( $headprinted eq '' ) {
                    print ULOS $headout;
                    $headprinted = 1;
                }
                print ULOS 'POLYLINE';
                print ULOS $d;
            }
        }
    }
    print ULOS 'ENDSEC' . $footer;
    close ULOS;
    print ULOS2 'ENDSEC' . $footer;
    close ULOS2;
    ###

    if ( $command eq 'merge' ) {
        $command = 'pngmergevege';
    }
    else {
        exit;
    }
}

if ( $command eq 'pngmerge' || $command eq 'pngmergedepr' ) {

    use GD;
    use File::stat;

    @pnglist_with_dirs =
      map { File::Spec->canonpath($_) } glob( $batchoutfolder . '/*.png' );
    @pnglist = map { basename($_) } @pnglist_with_dirs;
    $pnglist = join( " ", @pnglist_with_dirs );

    @pnglistorig = @pnglist;

    $scale = 1 * $ARGV[1];
    if ( $scale == 0 ) {
        $scale = 4;
    }

    foreach $png (@pnglist) {
        chomp($png);
        $png0 = $png;
        $png =~ s/\.png/\.pgw/;

        print "$png\n";
        $png = $batchoutfolder . "/" . $png;

        if (
               -e $png
            && !( $png =~ /\_vege\.png/ )
            && (   ( $png =~ /depr/ && $command eq 'pngmergedepr' )
                || ( !( $png =~ /depr/ ) && $command eq 'pngmerge' ) )
          )
        {
            print("in here\n");
            $myImage = newFromPng GD::Image( $batchoutfolder . "/" . $png0, 1 );

            ( $width, $height ) = $myImage->getBounds();

            open( SISAAN, "<$png" );
            @tfw = <SISAAN>;
            close(SISAAN);

            if ( $res eq '' ) {
                $res = 1 * $tfw[0];
            }

            if ( $tfw[4] < $xmin || $xmin eq '' ) {
                $xmin = 1 * $tfw[4];
            }
            if ( $tfw[4] + $width * $res > $xmax || $xmax eq '' ) {
                $xmax = 1 * $tfw[4] + $width * $res;
            }
            if ( $tfw[5] > $ymax || $ymax eq '' ) {
                $ymax = 1 * $tfw[5];
            }
            if ( $tfw[5] - $height * $res < $ymin || $ymin eq '' ) {
                $ymin = 1 * $tfw[5] - $height * $res;
            }
        }
    }

    @pnglist = @pnglistorig;
    $i       = 0;
    foreach $png (@pnglist) {

        chomp($png);
        $png = $batchoutfolder . "/" . $png;

        print "$png\n";

        $filesize = stat($png)->size;
        if (
               $filesize > 0
            && -e $png
            && !( $png =~ /\_vege\.png/ )
            && (   ( $png =~ /depr/ && $command eq 'pngmergedepr' )
                || ( !( $png =~ /depr/ ) && $command eq 'pngmerge' ) )
          )
        {

            $myImage = newFromPng GD::Image( $png, 1 );

            ( $width, $height ) = $myImage->getBounds();
            $i++;
            if ( $i == 1 ) {
                if ( $scale == 1 ) {
                    print("creating image\n");
                    $im = new GD::Image( ( $xmax - $xmin ) / $res / $scale,
                        ( $ymax - $ymin ) / $res / $scale, 0 );
                }
                else {
                    $im = new GD::Image( ( $xmax - $xmin ) / $res / $scale,
                        ( $ymax - $ymin ) / $res / $scale, 1 );
                }
            }

            $png =~ s/\.png/\.pgw/;

            open( SISAAN, "<$png" );
            @tfw = <SISAAN>;
            close(SISAAN);

            $im->copyResampled(
                $myImage,
                ( $tfw[4] - $xmin ) / $res / $scale,
                ( -$tfw[5] + $ymax ) / $res / $scale,
                0,
                0,
                $width / $scale + 0.5,
                $height / $scale + 0.5,
                $width,
                $height
            );

        }
    }

    $|    = 1;
    $depr = '';
    if ( $command eq 'pngmergedepr' ) { $depr = '_depr'; }
    open( OUT, ">merged" . $depr . ".jpg" );
    binmode OUT;
    print OUT $im->jpeg(90);
    close OUT;

    open( OUT, ">merged" . $depr . ".jgw" );
    print OUT "" . ( $res * $scale ) . "
0
0
-" . ( $res * $scale ) . "
$xmin
$ymax
";
    close OUT;

    open( OUT, ">merged" . $depr . ".png" );
    binmode OUT;
    print OUT $im->png;
    close OUT;

    open( OUT, ">merged" . $depr . ".pgw" );
    print OUT "" . ( $res * $scale ) . "
0
0
-" . ( $res * $scale ) . "
$xmin
$ymax
";
    close OUT;

    exit;
}

## pngmergevege

if ( $command eq 'pngmergevege' ) {

    use GD;
    use File::stat;

    @pnglist_with_dirs =
      map { File::Spec->canonpath($_) } glob( $batchoutfolder . '/*_vege.png' );
    @pnglist = map { basename($_) } @pnglist_with_dirs;
    $pnglist = join( " ", @pnglist_with_dirs );

    @pnglistorig = @pnglist;

    $scale = 1 * $ARGV[1];
    if ( $scale == 0 ) {
        $scale = 1;
    }

    foreach $png (@pnglist) {
        chomp($png);

        $myImage = newFromPng GD::Image( $batchoutfolder . "/" . $png, 1 );

        ( $width, $height ) = $myImage->getBounds();

        $png =~ s/\.png/\.pgw/;

        $png = $batchoutfolder . "/" . $png;
        if ( -e $png ) {
            open( SISAAN, "<$png" );
            @tfw = <SISAAN>;
            close(SISAAN);

            if ( $res eq '' ) {
                $res = 1 * $tfw[0];
            }

            if ( $tfw[4] < $xmin || $xmin eq '' ) {
                $xmin = 1 * $tfw[4];
            }
            if ( $tfw[4] + $width * $res > $xmax || $xmax eq '' ) {
                $xmax = 1 * $tfw[4] + $width * $res;
            }
            if ( $tfw[5] > $ymax || $ymax eq '' ) {
                $ymax = 1 * $tfw[5];
            }
            if ( $tfw[5] - $height * $res < $ymin || $ymin eq '' ) {
                $ymin = 1 * $tfw[5] - $height * $res;
            }
        }
    }

    @pnglist = @pnglistorig;

    $i = 0;
    foreach $png (@pnglist) {

        chomp($png);
        $png = $batchoutfolder . "/" . $png;

        print "$png\n";

        $filesize = stat($png)->size;
        if ( $filesize > 0 && -e $png ) {

            $myImage = newFromPng GD::Image( $png, 1 );

            ( $width, $height ) = $myImage->getBounds();
            $i++;
            if ( $i == 1 ) {
                if ( $scale == 1 ) {
                    $im = new GD::Image( ( $xmax - $xmin ) / $res / $scale,
                        ( $ymax - $ymin ) / $res / $scale, 0 );
                }
                else {
                    $im = new GD::Image( ( $xmax - $xmin ) / $res / $scale,
                        ( $ymax - $ymin ) / $res / $scale, 1 );
                }
            }

            $png =~ s/\.png/\.pgw/;

            open( SISAAN, "<$png" );
            @tfw = <SISAAN>;
            close(SISAAN);

            $im->copyResampled(
                $myImage,
                ( $tfw[4] - $xmin ) / $res / $scale,
                ( -$tfw[5] + $ymax ) / $res / $scale,
                0,
                0,
                $width / $scale + 0.5,
                $height / $scale + 0.5,
                $width,
                $height
            );

        }
    }

    $| = 1;
    open( OUT, ">merged_vege.jpg" );
    binmode OUT;
    print OUT $im->jpeg(90);
    close OUT;

    open( OUT, ">merged_vege.jgw" );
    print OUT "" . ( $res * $scale ) . "
0
0
-" . ( $res * $scale ) . "
$xmin
$ymax
";
    close OUT;

    open( OUT, ">merged_vege.png" );
    binmode OUT;
    print OUT $im->png;
    close OUT;

    open( OUT, ">merged_vege.pgw" );
    print OUT "" . ( $res * $scale ) . "
0
0
-" . ( $res * $scale ) . "
$xmin
$ymax
";
    close OUT;

    exit;
}

if ( $command eq '' && $batch == 1 && $proc > 1 ) {
    print "\nstarting batch processing\n";
    for ( $i = 1 ; $i < $proc + 1 ; $i++ ) {

        # start independent shell window
        system("pullauta startthread $i &");
    }
    exit;
}

if (   ( $command eq '' && $batch == 1 && $proc < 2 )
    || ( $command eq 'startthread' && $batch == 1 ) )
{

    $thread = 1 * $ARGV[1];
    sleep( $thread * 3 )
      ;    #to make it less likely processes would start processing same tile
    if ( $thread == 0 ) { $thread = ''; }

    # batch process
    mkdir $batchoutfolder;

    @ziplist_with_dirs =
      map { File::Spec->canonpath($_) } glob( $lazfolder . '/*.zip' );
    @ziplist = map { basename($_) } @ziplist_with_dirs;
    $ziplist = join( " ", @ziplist_with_dirs );

    if ( $ziplist =~ /zip/i ) {

        #ok
    }
    else {
        print "Shape zips not found. Processing laser files only.";
        $ziplist = '';
    }

####

    @lazlist_with_dirs = map { File::Spec->canonpath($_) }
      glob( $lazfolder . '/*.laz ' . $lazfolder . '/*.las' );
    @lazlist = map { basename($_) } @lazlist_with_dirs;
    $lazlist = join( " ", @lazlist_with_dirs );

    $i = 0;

    foreach $laz (@lazlist) {
        chomp($laz);
        $i++;

        if ( -e $batchoutfolder . '/' . $laz . '.png' ) {
            print "skipping $laz" . '.png'
              . " it exists already in out folder.\n";
        }
        else {
            # Create an empty png file to allow parallel processing to proceed
            print "$laz -> $laz" . ".png\n";
            touch( $batchoutfolder . '/' . $laz . '.png' );

            # Extract header information
            @d =
              capture( "las2txt -i  "
                  . $lazfolder
                  . "/$laz -header pound -keep_xy 0 0 0 0 -stdout" );
            foreach $rec (@d) {

                chomp($rec);

                if ( $rec =~ /# min x y z / ) {

                    #print "$rec\n";
                    ( $pois, $d ) = split( /# min x y z /, $rec, 2 );
                    ( $pois, $minx, $miny, $minz ) = split( / +/, $d );
                }

                if ( $rec =~ /# max x y z / ) {

                    #print "$rec\n";
                    ( $pois, $d ) = split( /# max x y z/, $rec, 2 );
                    ( $pois, $maxx, $maxy, $maxz ) = split( / +/, $d );
                }
            }

            $minx2 = $minx - 127;
            $miny2 = $miny - 127;
            $maxx2 = $maxx + 127;
            $maxy2 = $maxy + 127;
            if ( $zoff != 0 ) {
                $translate = " -translate_z " . ( 1 * $zoff );
            }

            unlink "temp$thread.xyz";
            run(
"las2txt -i $lazlist -merged -o temp$thread.xyz -parse xyzcnri -inside $minx2 $miny2 $maxx2 $maxy2"
                  . $translate );

            if ( $ziplist ne '' ) {
                run("pullauta $thread temp$thread.xyz norender");
            }
            else {
                run("pullauta $thread temp$thread.xyz");
            }
            if ( $ziplist ne '' ) {
                run("pullauta $thread $ziplist");
            }

            #crop

            $myImage = newFromPng GD::Image( 'pullautus' . $thread . '.png' );

            ( $width, $height ) = $myImage->getBounds();

           #$im = new GD::Image($width-127*600/254*2+2,$height-127*600/254*2+2);
            $im = new GD::Image(
                ( $maxx - $minx ) * 600 / 254 / $scalefactor + 2,
                ( $maxy - $miny ) * 600 / 254 / $scalefactor + 2
            );

            #$foo=($maxx-$minx)*600/254+2;
            #print "#$foo#";
            #$foo=($maxy-$miny)*600/254+2;
            #print "#$foo#\n";

            open( SISAAN, "<pullautus$thread.pgw" );
            @tfw = <SISAAN>;
            close(SISAAN);

            $dx     = $minx - $tfw[4];
            $dy     = -$maxy + $tfw[5];
            $tfw[4] = $minx + $tfw[0] / 2;
            $tfw[5] = $maxy - $tfw[0] / 2;
            $tfw[4] .= "\n";
            $tfw[5] .= "\n";

            open( OUT, ">pullautus$thread.pgw" );
            print OUT @tfw;
            close OUT;

            open( OUT, ">pullautus_depr$thread.pgw" );
            print OUT @tfw;
            close OUT;

            #print "copy 0,0, $dx*600/254,$dy*600/254,$width,$height\n";

            $im->copy(
                $myImage,
                -$dx * 600 / 254 / $scalefactor,
                -$dy * 600 / 254 / $scalefactor,
                0, 0, $width, $height
            );

            open( OUT, ">pullautus$thread.png" );
            binmode OUT;

            # Convert the image to PNG and print it on standard output
            print OUT $im->png;
            close OUT;

            $myImage = newFromPng GD::Image("pullautus_depr$thread.png");

            $im = new GD::Image(
                ( $maxx - $minx ) * 600 / 254 / $scalefactor + 2,
                ( $maxy - $miny ) * 600 / 254 / $scalefactor + 2
            );

            $im->copy(
                $myImage,
                -$dx * 600 / 254 / $scalefactor,
                -$dy * 600 / 254 / $scalefactor,
                0, 0, $width, $height
            );

            open( OUT, ">pullautus_depr$thread.png" );
            binmode OUT;

            # Convert the image to PNG and print it on standard output
            print OUT $im->png;
            close OUT;

            #print "filecopy ";

            copy( "pullautus$thread.png",
                $batchoutfolderwin . "/" . $laz . '.png' );
            copy( "pullautus$thread.pgw",
                $batchoutfolderwin . "/" . $laz . '.pgw' );
            copy( "pullautus_depr$thread.png",
                $batchoutfolderwin . "/" . $laz . '_depr.png' );
            copy( "pullautus_depr$thread.pgw",
                $batchoutfolderwin . "/" . $laz . '_depr.pgw' );

            #print "filecopy done!";

            ## copy files from temp folder
            if ( $savetempfiles == 1 ) {

                $myImage = newFromPng GD::Image("temp$thread/undergrowth.png");

                $im = new GD::Image(
                    ( $maxx - $minx ) * 600 / 254 / $scalefactor + 2,
                    ( $maxy - $miny ) * 600 / 254 / $scalefactor + 2
                );
                $white = $im->colorAllocate( 255, 255, 255 );

                $im->filledRectangle(
                    0, 0,
                    ( $maxx - $minx ) * 600 / 254 / $scalefactor + 3,
                    ( $maxy - $miny ) * 600 / 254 / $scalefactor + 3, $white
                );
                $im->copy(
                    $myImage,
                    -$dx * 600 / 254 / $scalefactor,
                    -$dy * 600 / 254 / $scalefactor,
                    0, 0, $width, $height
                );

                open( OUT,
                        ">"
                      . $batchoutfolderwin . "/"
                      . $laz
                      . '_undergrowth.png' );
                binmode OUT;

                # Convert the image to PNG and print it on standard output
                print OUT $im->png;
                close OUT;

                open( OUT,
                        ">"
                      . $batchoutfolderwin . "/"
                      . $laz
                      . '_undergrowth.pgw' );
                print OUT @tfw;
                close OUT;

                $myImage = newFromPng GD::Image("temp$thread/vegetation.png");
                ( $width, $height ) = $myImage->getBounds();
                $im =
                  new GD::Image( ( $maxx - $minx ) + 1, ( $maxy - $miny ) + 1 );

                $im->copy( $myImage, -$dx, -$dy, 0, 0, $width, $height );

                open( OUT,
                    ">" . $batchoutfolderwin . "/" . $laz . '_vege.png' );
                binmode OUT;
                print OUT $im->png;
                close OUT;

                $tfw[0] = "1.0\n";
                $tfw[1] = "0.0\n";
                $tfw[2] = "0.0\n";
                $tfw[3] = "-1.0\n";
                $tfw[4] = $minx + 0.5;
                $tfw[5] = $maxy - 0.5;
                $tfw[4] .= "\n";
                $tfw[5] .= "\n";

                open( OUT,
                    ">" . $batchoutfolderwin . "/" . $laz . '_vege.pgw' );
                print OUT @tfw;
                close OUT;
                ## dxf files

                open( SISAAN, "<temp$thread/out2.dxf" );
                @d = <SISAAN>;
                close SISAAN;

                &polylinedxfcrop;

                open( OUT,
                    ">" . $batchoutfolderwin . "/" . $laz . '_contours.dxf' );
                print OUT $out;
                close OUT;

                ## out2.dxf done

                open( SISAAN, "<temp$thread/c2g.dxf" );
                @d = <SISAAN>;
                close SISAAN;

                &polylinedxfcrop;

                open( OUT, ">" . $batchoutfolderwin . "/" . $laz . '_c2g.dxf' );
                print OUT $out;
                close OUT;

                open( SISAAN, "<temp$thread/c3g.dxf" );
                @d = <SISAAN>;
                close SISAAN;

                &polylinedxfcrop;

                open( OUT, ">" . $batchoutfolderwin . "/" . $laz . '_c3g.dxf' );
                print OUT $out;
                close OUT;

                open( SISAAN, "<temp$thread/contours03.dxf" );
                @d = <SISAAN>;
                close SISAAN;

                &polylinedxfcrop;

                open( OUT,
                    ">" . $batchoutfolderwin . "/" . $laz . '_contours03.dxf' );
                print OUT $out;
                close OUT;

                open( SISAAN, "<temp$thread/detected.dxf" );
                @d = <SISAAN>;
                close SISAAN;

                &polylinedxfcrop;

                open( OUT,
                    ">" . $batchoutfolderwin . "/" . $laz . '_detected.dxf' );
                print OUT $out;
                close OUT;

                if ( -e "temp$thread/formlines.dxf" ) {
                    open( SISAAN, "<temp$thread/formlines.dxf" );
                    @d = <SISAAN>;
                    close SISAAN;

                    &polylinedxfcrop;

                    open( OUT,
                            ">"
                          . $batchoutfolderwin . "/"
                          . $laz
                          . '_formlines.dxf' );
                    print OUT $out;
                    close OUT;
                }

                ## dotknolls.dxf
                open( SISAAN, "<temp$thread/dotknolls.dxf" );
                @d = <SISAAN>;
                close SISAAN;

                $out = '';

                $d = join( '', @d );

                @d = split( /POINT/, $d );
                $out .= $d[0];
                ( $d[$#d], $end ) = split( /ENDSEC/, $d[$#d], 20 );
                $end = 'ENDSEC' . $end;
                $j   = 0;
                foreach $rec (@d) {
                    $j++;
                    if ( $j > 1 ) {
                        @temp = split( /\n/, $rec );

                        if (   $temp[4] >= $minx
                            && $temp[4] <= $maxx
                            && $temp[6] >= $miny
                            && $temp[6] <= $maxy )
                        {
                            $out .= 'POINT' . $rec;

                        }
                    }
                }
                $out .= $end;
                open( OUT,
                    ">" . $batchoutfolderwin . "/" . $laz . '_dotknolls.dxf' );
                print OUT $out;
                close OUT;
                ## dotknolls.dxf done
            }

            if ( $basemapcontours > 0 ) {
                open( SISAAN, "<temp$thread/basemap.dxf" );
                @d = <SISAAN>;
                close SISAAN;
                &polylinedxfcrop;
                open( OUT,
                    ">" . $batchoutfolderwin . "/" . $laz . '_basemap.dxf' );
                print OUT $out;
                close OUT;
            }

            if ( $savetempfolders == 1 ) {
                system "mkdir \"temp_" . $laz . "_dir\"";
                system "cp temp$thread/\*\.\* \"temp_" . $laz . "_dir/\"";
            }

        }
    }
    exit;
}

mkdir $tempfolder;

if ( $command =~ /\.zip/i ) {    ## rendering with mtk data
    print "Rendering  shape files\n.....\n";

    #print "pullauta $thread unzipmtk " . join( ' ', @ARGV );
    system "pullauta $thread unzipmtk " . join( ' ', @ARGV );

    print "\nRendering png map with depressions\n";
    system("pullauta $thread render $pnorthlinesangle $pnorthlineswidth ");

    print "\nRendering png map without depressions\n";

    system(
"pullauta $thread render $pnorthlinesangle $pnorthlineswidth  nodepressions"
    );

    print "\n\nAll done!\n";
    exit;

}

if ( $command =~ /\.laz/ || $command =~ /\.las/ || $command =~ /\.xyz/ ) {

    print "Preparing input file\n.....";
    if ( $command =~ /\.xyz/ ) {

        open( SISAAN, "<$command" );

        $d = <SISAAN>;
        $d = <SISAAN>;
        $d = <SISAAN>;
        close SISAAN;

        @r = split( / /, $d );

        if ( $#r == 6 ) {
## 4 field, so may be xyzcnri format
            $skiplas2txt = 1;
        }
    }

    # main
    # convert laz to txt using las2txt

    if ( $skiplas2txt != 1 ) {
        $lastxtexe = 0;

        #las2txt check
        open( TEST, "las2txt -version 2>&1 |" );
        @las2txtversion = <TEST>;
        close(TEST);
        if ( join( '', @las2txtversion ) =~ /version/i ) {
            $lastxtexe = 1;
        }

        if ( -e 'las2txt.exe' || $lastxtexe == 1 ) {

            # unlink "$tempfolder/header.xyz";

            #system "las2txt -i \"" . $command
            #  . "\" -header pound -clip 0 0 0 0 -o $tempfolder/header.xyz";

            #open( SISAAN, "<" . $tempfolder . "/header.xyz" );
            #@d=<SISAAN>;
            #close(SISAAN);
            #foreach $rec (@d){
            #
            #chomp($rec);
            #if($rec =~/# number of point records/){
            #($pois,$val)=split(/# number of point records/,$rec,2);
            #
            #$numberofpointrecords=1*$val;
            #
            #}
            #if($rec =~/# min x y z /){
            #print "$rec\n";
            #($pois,$d)=split(/# min x y z /,$rec,2);
            #($pois,$minx,$miny,$minz)=split(/ +/,$d);
            #}
            #if($rec =~/# max x y z /){
            #print "$rec\n";
            #($pois,$d)=split(/# max x y z/,$rec,2);
            #($pois,$maxx,$maxy,$maxz)=split(/ +/,$d);
            #}
            #}

            #$area=($maxx-$minx)*($maxy-$miny)*$xfactor*$yfactor;
            #if($thinfactor ==1 && $area > 0 && $numberofpointrecords > 0){
            #if($numberofpointrecords > $area * 2){
            #$thinfactor = $area * 2/$numberofpointrecords;
            #print "Using thinning factor $thinfactor\n";
            #}
            #}

            if ( $thinfactor != 1 ) {
                print "Using thinning factor $thinfactor\n";
            }

            if (   $xfactor == 1
                && $coordyfactor == 1
                && $zfactor == 1
                && $zoff == 0 )
            {
                system "las2txt -i \"" . $command
                  . "\" -parse xyzcnri -keep_random_fraction $thinfactor -o $tempfolder/xyztemp.xyz";

            }
            else {
                system "las2txt -i \"" . $command
                  . "\" -parse xyzcnri -keep_random_fraction $thinfactor -o $tempfolder/xyztemp1.xyz";

                print "Scaling xyz...";
                open( SISAAN, "<" . $tempfolder . "/xyztemp1.xyz" );
                open( ULOS,   ">" . $tempfolder . "/xyztemp.xyz" );
                while ( $d = <SISAAN> ) {
                    ( $x, $y, $z, $rest ) = split( / /, $d, 4 );
                    $x = $x * $xfactor;
                    $y = $y * $coordyfactor;
                    $z = $z * $zfactor + $zoff;

                    print ULOS "$x $y $z $rest";
                }
                close ULOS;
                close SISAAN;
                unlink "$tempfolder/xyztemp1.xyz";
            }

        }
        else {
            print
              "Can't find las2txt.exe. It is needed if input file is not xyz 
file with xyzc data. Make sure it is in path or  copy it 
to the same folder as pullautin.exe \n ";
            sleep 10;
            exit;
        }

    }
    else {

        #print "copying \"$command\" as $tempfolder/xyztemp.xyz\n";

        open( SISAAN, "<$command" );
        open( ULOS,   ">" . $tempfolder . "/xyztemp.xyz" );
        while ( $d = <SISAAN> ) {
            print ULOS $d;
        }
        close ULOS;
        close SISAAN;

    }
    print "..... done.";
    undef @d;
## 2m grid & controus 0.3
    print "\nKnoll detection part 1\n";
    system( "pullauta $thread xyz2contours "
          . ( 0.3 * $scalefactor )
          . " xyztemp.xyz xyz_03.xyz contours03.dxf ground" );

## copy xyz2.xyz
    open( SISAAN, "<" . $tempfolder . "/xyz_03.xyz" );
    open( ULOS,   ">" . $tempfolder . "/xyz2.xyz" );
    while ( $d = <SISAAN> ) {
        print ULOS $d;
    }
    close ULOS;
    close SISAAN;
    if ( $basemapcontours > 0 ) {
        print "\nBasemap contours\n";
        system( "pullauta $thread xyz2contours "
              . ($basemapcontours)
              . " xyz2.xyz null basemap.dxf" );
    }
    if ( 1 * $Config->{_}->{skipknolldetection} != 1 ) {
## detector
        print "\nKnoll detection part 2\n";
        system("pullauta $thread knolldetector");
    }
## xyz_knolls
    print "\nContour generation part 1\n";
    system("pullauta $thread xyzknolls");
    if ( 1 * $Config->{_}->{skipknolldetection} != 1 ) {
## contours 2.5
        print "\nContour generation part 2\n";
        system( "pullauta $thread xyz2contours "
              . ( 2.5 * $scalefactor )
              . " xyz_knolls.xyz null out.dxf" );
    }
    else {
        system( "pullauta $thread xyz2contours "
              . ( 2.5 * $scalefactor )
              . " xyztemp.xyz null out.dxf ground" );
    }
## smoothjoin
    print "\nContour generation part 3\n";
    system("pullauta $thread smoothjoin");
    print "\nContour generation part 4\n";
    system("pullauta $thread dotknolls");
## vege.png
    if ( $vegemode == 0 ) {
        ## new vege
        print "\nVegetation generation\n";
        system("pullauta $thread makevegenew");
    }
    else {
        ## old vege
## vege.png
        print "\nVegetation generation part 1\n";
        system("pullauta makevege xyztemp.xyz $pvege_yellow $pvege_green ");
## vege rest
        print "\nVegetation generation part 2\n";
        system(
"pullauta vege $lightgreenlimit $darkgreenlimit $gfactor $yfactor $wfactor $yellowlimit"
        );
    }
## cliff maker
    print "\nCliff generation \n";

    if ( $pcliff3 > 0 && $pcliff2 > 0 ) {
        print "Old cliff3 parameter found, using cliff3 instead of cliff2...\n";
        $pcliff2 = $pcliff3;
    }
    system("pullauta $thread makecliffs xyztemp.xyz");
## cliff generalizer
    #    print "\nCliff generation part 2\n";
    #    system("pullauta $thread cliffgeneralize $psteepness");
## renderer
    if ( $detectbuildings == 1 ) {
        print "\nDetecting buildings\n";
        system("pullauta $thread blocks");
    }

    if ( $ARGV[1] ne 'norender' ) {
        print "\nRendering png map with depressions\n";
        system("pullauta $thread render $pnorthlinesangle $pnorthlineswidth ");
        print "\nRendering png map without depressions\n";
        system(
"pullauta $thread render $pnorthlinesangle $pnorthlineswidth  nodepressions"
        );
    }
    else {
        print "Skipped rendering";
    }

    print "\n\nAll done!\n";
    exit;
}
$tempfolder = $tempfolder . '/';
##############################
if ( $command eq 'makecliffsold' ) {

    $xyzin   = $ARGV[1];
    $c1limit = $ARGV[2];
    $c2limit = $ARGV[3];
    $c3limit = $ARGV[4];
    $step    = $c1limit * 0.8;
    $xmax    = '';
    $ymax    = '';
    $xmin    = '';
    $ymin    = '';
    $hmin    = 999999;
    $hmax    = -999999;

    open( SISAAN, "<" . $tempfolder . "$xyzin" );

    while ( $rec = <SISAAN> ) {

        @r = split( / /, $rec );
        if ( $r[3] == 2 ) {
            if ( $xmin ne '' ) {
                if ( $r[0] < $xmin ) { $xmin = $r[0]; }
            }
            else { $xmin = $r[0]; }
            if ( $xmax ne '' ) {
                if ( $r[0] > $xmax ) { $xmax = $r[0]; }
            }
            else { $xmax = $r[0]; }
            if ( $ymin ne '' ) {
                if ( $r[1] < $ymin ) { $ymin = $r[1]; }
            }
            else { $ymin = $r[1]; }
            if ( $ymax ne '' ) {
                if ( $r[1] > $ymax ) { $ymax = $r[1]; }
            }
            else { $ymax = $r[1]; }

            if ( $r[2] > $hmax ) { $hmax = $r[2]; }
            if ( $r[2] < $hmin ) { $hmin = $r[2]; }
        }
    }

    close SISAAN;

    #print "
    #    $xmax
    #    $ymax
    #    $xmin
    #    $ymin
    #
    #    $hmin
    #    $hmax
    #";
    print "..";
    open( SISAAN, "<" . $tempfolder . "$xyzin" );

    while ( $rec = <SISAAN> ) {

        @r = split( / /, $rec );
        $i = 0;
        $j = 0;
        if ( $r[3] == 2 ) {

            #@cols=split(/\#/,$row[ floor($r[0] - $xmin ) ]);
            #$cols[ floor( $r[1] - $ymin ) ] .=              '|' . $r[2];
            #$row[ floor($r[0] - $xmin ) ]=join('#',@cols);

            $row[ floor( $r[0] - $xmin ) ] .=
              '#' . $r[2] . '|' . ( floor( $r[1] - $ymin ) );

        }

    }
    close SISAAN;
    undef @d;

    print "..";

    $w = floor( $xmax - $xmin );
    $h = floor( $ymax - $ymin );

    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {
        undef @cols;
        @temp = split( /\#/, $row[$x] );
        foreach $rec (@temp) {
            if ( $rec ne '' ) {
                ( $val, $y ) = split( /\|/, $rec );
                $cols[$y] .= '|' . $val;
            }
        }
        $row[$x] = join( '#', @cols );

    }
    print "..";
####
    undef @cols;
    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {
        @cols = split( /\#/, $row[$x] );
        for ( $y = 0 ; $y < $h + 1 ; $y++ ) {

            if ( $cols[$y] ne '' ) {

                # print "X $cols[$y] X";
                @t   = split( /\|/, $cols[$y] );
                $val = 0;
                $c   = 0;
                foreach $v (@t) {
                    if ( $v ne '' ) {
                        $c++;
                        $val += 1 * $v;
                    }

                }

                $cols[$y] = 1000 + $val / $c;

            }

        }
        $row[$x] = join( '#', @cols );

    }

###

    print "..";

    for ( $x = 1 ; $x < $w ; $x++ ) {
        @cols0 = split( /\#/, $row[ $x - 1 ] );
        @cols1 = split( /\#/, $row[$x] );
        @cols2 = split( /\#/, $row[ $x + 1 ] );
        for ( $y = 1 ; $y < $h ; $y++ ) {

            if ( $cols1[$y] eq '' ) {
## interpolate here

                $val = 0;
                $c   = 0;

                if (   $cols0[ $y - 1 ] ne ''
                    && $cols2[ $y + 1 ] ne '' )
                {
                    $c = $c + 2;
                    $val += 1 * $cols0[ $y - 1 ] + 1 * $cols2[ $y + 1 ];
                }

                if (   $cols0[ $y + 1 ] ne ''
                    && $cols2[ $y - 1 ] ne '' )
                {
                    $c = $c + 2;
                    $val += 1 * $cols0[ $y + 1 ] + 1 * $cols2[ $y - 1 ];
                }

                if ( $cols1[ $y - 1 ] ne '' && $cols1[ $y + 1 ] ne '' ) {
                    $c = $c + 2;
                    $val += 1 * $cols1[ $y - 1 ] + 1 * $cols1[ $y + 1 ];
                }
                if ( $cols0[$y] ne '' && $cols2[$y] ne '' ) {
                    $c = $c + 2;
                    $val += 1 * $cols0[$y] + 1 * $cols2[$y];
                }

                ######
                if ( $c > 0 ) {
                    $cols1[$y] = $val / $c;

                }

            }
        }
        $row[$x] = join( '#', @cols1 );

    }

####################################################

    print ".";
    for ( $x = 1 ; $x < $w ; $x++ ) {
        @cols0 = split( /\#/, $row[ $x - 1 ] );
        @cols1 = split( /\#/, $row[$x] );

        for ( $y = 1 ; $y < $h ; $y++ ) {

            if ( ( $cols1[$y] ) < 100 ) {
## interpolate here

                if ( abs( $cols0[$y] ) > abs( $cols1[ $y - 1 ] ) ) {
                    $cols1[$y] = -abs( $cols0[$y] ) + $step;
                }
                else {
                    $cols1[$y] = -abs( $cols1[ $y - 1 ] ) + $step;
                }
                if ( abs( $cols0[ $y - 1 ] ) > abs( $cols1[$y] ) + $step * 1.4 )
                {
                    $cols1[$y] = -abs( $cols0[ $y - 1 ] ) + $step * 1.4;
                }
                if ( abs( $cols0[ $y + 1 ] ) > abs( $cols1[$y] ) + $step * 1.4 )
                {
                    $cols1[$y] = -abs( $cols0[ $y + 1 ] ) + $step * 1.4;
                }

            }
        }
        $row[$x] = join( '#', @cols1 );
    }

    print ".";
    for ( $x = $w - 1 ; $x > 1 ; $x = $x - 1 ) {
        @cols0 = split( /\#/, $row[ $x + 1 ] );
        @cols1 = split( /\#/, $row[$x] );

        for ( $y = $h - 1 ; $y > 1 ; $y = $y - 1 ) {

            if ( ( $cols1[$y] ) < 100 ) {
## interpolate here

                if ( abs( $cols0[$y] ) > abs( $cols1[ $y + 1 ] ) ) {
                    $tmp = -abs( $cols0[$y] ) + $step;
                }
                else {
                    $tmp = -abs( $cols1[ $y + 1 ] ) + $step;
                }
                if ( abs( $cols0[ $y + 1 ] ) > abs($tmp) + $step * 1.4 ) {
                    $tmp = -abs( $cols0[ $y + 1 ] ) + $step * 1.4;
                }
                if ( abs( $cols0[ $y - 1 ] ) > abs($tmp) + $step * 1.4 ) {
                    $tmp = -abs( $cols0[ $y - 1 ] ) + $step * 1.4;
                }

                if ( abs($tmp) > abs( $cols1[$y] ) ) { $cols1[$y] = $tmp; }

            }
        }
        $row[$x] = join( '#', @cols1 );
    }

##

    print ".";

    for ( $x = 0 ; $x < $w ; $x++ ) {

        @cols1 = split( /\#/, $row[$x] );

        for ( $y = 0 ; $y < $h ; $y++ ) {

            #print ";".(1*$cols1[$y]);
            $cols1[$y] = abs( $cols1[$y] );
        }

        #print "\n";
        $row[$x] = join( '#', @cols1 );
    }

####################3##Cliffs
    for ( $layer = 1 ; $layer < 4 ; $layer++ ) {
        print "..";
        if ( $layer == 1 ) { $limit = $c1limit; }
        if ( $layer == 2 ) { $limit = $c2limit; }
        if ( $layer == 3 ) { $limit = $c3limit; }
        $cliffs = '';
        undef %bottom;
        undef %jo;
        undef %head;
        undef %tail;
        undef @cl;
        $dxf = '';
###################################3
        for ( $x = 4 ; $x < $w - 4 ; $x++ ) {

            #@cols0=split(/\#/,$row[ $x-1 ]);
            @cols1 = split( /\#/, $row[$x] );
            @cols2 = split( /\#/, $row[ $x + 1 ] );
            for ( $y = 4 ; $y < $h - 4 ; $y++ ) {

                if ( ( $cols1[$y] - $cols2[$y] ) > $limit ) {
                    $cliffs .= '|'
                      . ( $x + .5 ) . ','
                      . ( $y + .5 ) . ','
                      . ( $x + .5 ) . ','
                      . ( $y - .5 ) . ','
                      . ($x) . ','
                      . ($y);
                    $bottom{ '' . ( $x + 1 ) . '_' . ($y) } = 1;
                }
                if ( ( $cols1[$y] - $cols1[ $y + 1 ] ) > $limit ) {
                    $cliffs .= '|'
                      . ( $x - .5 ) . ','
                      . ( $y + .5 ) . ','
                      . ( $x + .5 ) . ','
                      . ( $y + .5 ) . ','
                      . ($x) . ','
                      . ($y);
                    $bottom{ '' . ($x) . '_' . ( $y + 1 ) } = 1;
                }

                if ( ( -$cols1[$y] + $cols2[$y] ) > $limit ) {
                    $cliffs .= '|'
                      . ( $x + .5 ) . ','
                      . ( $y + .5 ) . ','
                      . ( $x + .5 ) . ','
                      . ( $y - .5 ) . ','
                      . ( $x + 1 ) . ','
                      . ($y);
                    $bottom{ '' . ($x) . '_' . ($y) } = 1;
                }
                if ( ( -$cols1[$y] + $cols1[ $y + 1 ] ) > $limit ) {
                    $cliffs .= '|'
                      . ( $x - .5 ) . ','
                      . ( $y + .5 ) . ','
                      . ( $x + .5 ) . ','
                      . ( $y + .5 ) . ','
                      . ($x) . ','
                      . ( $y + 1 );
                    $bottom{ '' . ($x) . '_' . ($y) } = 1;
                }

                if ( ( $cols1[$y] - $cols2[ $y + 1 ] ) > $limit * 1.4 ) {
                    $cliffs .= '|'
                      . ( $x + .5 ) . ','
                      . ( $y + .5 ) . ','
                      . ( $x + .5 ) . ','
                      . ( $y - .5 ) . ','
                      . ($x) . ','
                      . ($y);
                    $cliffs .= '|'
                      . ( $x - .5 ) . ','
                      . ( $y + .5 ) . ','
                      . ( $x + .5 ) . ','
                      . ( $y + .5 ) . ','
                      . ($x) . ','
                      . ($y);
                    $bottom{ '' . ( $x + 1 ) . '_' . ( $y + 1 ) } = 1;
                    $bottom{ '' . ($x) . '_' . ( $y + 1 ) }       = 1;
                    $bottom{ '' . ( $x + 1 ) . '_' . ($y) }       = 1;
                }
                if ( ( -$cols1[$y] + $cols2[ $y + 1 ] ) > $limit * 1.4 ) {
                    $cliffs .= '|'
                      . ( $x + .5 ) . ','
                      . ( $y + .5 ) . ','
                      . ( $x + .5 ) . ','
                      . ( $y + 1.5 ) . ','
                      . ( $x + 1 ) . ','
                      . ( $y + 1 );
                    $cliffs .= '|'
                      . ( $x + .5 ) . ','
                      . ( $y + .5 ) . ','
                      . ( $x + 1.5 ) . ','
                      . ( $y + .5 ) . ','
                      . ( $x + 1 ) . ','
                      . ( $y + 1 );
                    $bottom{ '' . ($x) . '_' . ($y) }       = 1;
                    $bottom{ '' . ($x) . '_' . ( $y + 1 ) } = 1;
                    $bottom{ '' . ( $x + 1 ) . '_' . ($y) } = 1;
                }

                if ( ( $cols1[$y] - $cols2[ $y - 1 ] ) > $limit * 1.4 ) {
                    $cliffs .= '|'
                      . ( $x - .5 ) . ','
                      . ( $y - .5 ) . ','
                      . ( $x + .5 ) . ','
                      . ( $y - .5 ) . ','
                      . ($x) . ','
                      . ($y);
                    $cliffs .= '|'
                      . ( $x + .5 ) . ','
                      . ( $y - .5 ) . ','
                      . ( $x + .5 ) . ','
                      . ( $y + .5 ) . ','
                      . ($x) . ','
                      . ($y);
                    $bottom{ '' . ( $x + 1 ) . '_' . ( $y - 1 ) } = 1;
                    $bottom{ '' . ($x) . '_' . ( $y - 1 ) }       = 1;
                    $bottom{ '' . ( $x + 1 ) . '_' . ($y) }       = 1;

                }
                if ( ( -$cols1[$y] + $cols2[ $y - 1 ] ) > $limit * 1.4 ) {
                    $cliffs .= '|'
                      . ( $x + .5 ) . ','
                      . ( $y - .5 ) . ','
                      . ( $x + .5 ) . ','
                      . ( $y - 1.5 ) . ','
                      . ( $x + 1 ) . ','
                      . ( $y - 1 );
                    $cliffs .= '|'
                      . ( $x + .5 ) . ','
                      . ( $y - .5 ) . ','
                      . ( $x + 1.5 ) . ','
                      . ( $y - .5 ) . ','
                      . ( $x + 1 ) . ','
                      . ( $y - 1 );
                    $bottom{ '' . ($x) . '_' . ($y) }       = 1;
                    $bottom{ '' . ($x) . '_' . ( $y - 1 ) } = 1;
                    $bottom{ '' . ( $x + 1 ) . '_' . ($y) } = 1;
                }

            }

        }

        @c1 = split( /\|/, $cliffs );

        #foreach $cliff (@c1){

        #

        #JOIN

        foreach $reca (@c1) {
            chomp($reca);

            if ( $reca ne '' ) {
                ( $x1, $y1, $x2, $y2, $tx, $ty ) = split( /\,/, $reca );

                if (   $bottom{ '' . $tx . '_' . $ty } != 1
                    && $jo{ '' . $x1 . '_' . $y1 . '_' . $x2 . '_' . $y2 } !=
                    1 )
                {

                    $jo{ '' . $x1 . '_' . $y1 . '_' . $x2 . '_' . $y2 } = 1;
                    $jo{ '' . $x2 . '_' . $y2 . '_' . $x1 . '_' . $y1 } = 1;

                    $cl[ $#cl + 1 ] = $reca;

                    if ( $head{ '' . ( 1 * $x1 ) . '_' . ( 1 * $y1 ) . '_1' } eq
                        '' )
                    {
                        $head{ '' . ( 1 * $x1 ) . '_' . ( 1 * $y1 ) . '_1' } =
                          $#cl;
                    }
                    else {
                        $head{ '' . ( 1 * $x1 ) . '_' . ( 1 * $y1 ) . '_2' } =
                          $#cl;
                    }

                    if ( $tail{ '' . ( 1 * $x2 ) . '_' . ( 1 * $y2 ) . '_1' } eq
                        '' )
                    {
                        $tail{ '' . ( 1 * $x2 ) . '_' . ( 1 * $y2 ) . '_1' } =
                          $#cl;
                    }
                    else {
                        $tail{ '' . ( 1 * $x2 ) . '_' . ( 1 * $y2 ) . '_2' } =
                          $#cl;
                    }

                }
            }
        }

        $i = -1;
        foreach $c (@cl) {
            $i++;
            if ( $c ne '' ) {
                ( $x1, $y1, $x2, $y2, $tx, $ty ) = split( /\,/, $c );
                $he     = '' . ( 1 * $x1 ) . '_' . ( 1 * $y1 );
                $e      = '' . ( 1 * $x2 ) . '_' . ( 1 * $y2 );
                $out    = '' . $x1 . ',' . $y1 . '|' . $x2 . ',' . $y2;
                $cl[$i] = '';

                while (
                    (
                           $head{ $e . '_1' } ne ''
                        && $cl[ $head{ $e . '_1' } ] ne ''
                    )
                    || (   $head{ $e . '_2' } ne ''
                        && $cl[ $head{ $e . '_2' } ] ne '' )
                    || (   $tail{ $e . '_2' } ne ''
                        && $cl[ $tail{ $e . '_2' } ] ne '' )
                    || (   $tail{ $e . '_1' } ne ''
                        && $cl[ $tail{ $e . '_1' } ] ne '' )
                  )
                {

                    if (   $head{ $e . '_1' } ne ''
                        && $cl[ $head{ $e . '_1' } ] ne '' )
                    {
                        @tmp = split( /\,/, $cl[ $head{ $e . '_1' } ] );
                        $out .= '|'
                          . $tmp[0] . ','
                          . $tmp[1] . '|'
                          . $tmp[2] . ','
                          . $tmp[3];
                        $cl[ $head{ $e . '_1' } ] = '';
                        $head{ $e . '_1' }        = '';
                        $e = '' . ( 1 * $tmp[2] ) . '_' . ( 1 * $tmp[3] );
                    }

                    if (   $head{ $e . '_2' } ne ''
                        && $cl[ $head{ $e . '_2' } ] ne '' )
                    {
                        @tmp = split( /\,/, $cl[ $head{ $e . '_2' } ] );
                        $out .= '|'
                          . $tmp[0] . ','
                          . $tmp[1] . '|'
                          . $tmp[2] . ','
                          . $tmp[3];
                        $cl[ $head{ $e . '_2' } ] = '';
                        $head{ $e . '_2' }        = '';
                        $e = '' . ( 1 * $tmp[2] ) . '_' . ( 1 * $tmp[3] );
                    }

                    if (   $tail{ $e . '_1' } ne ''
                        && $cl[ $tail{ $e . '_1' } ] ne '' )
                    {
                        @tmp = split( /\,/, $cl[ $tail{ $e . '_1' } ] );
                        $out .= '|'
                          . $tmp[2] . ','
                          . $tmp[3] . '|'
                          . $tmp[0] . ','
                          . $tmp[1];
                        $cl[ $tail{ $e . '_1' } ] = '';
                        $tail{ $e . '_1' }        = '';
                        $e = '' . ( 1 * $tmp[0] ) . '_' . ( 1 * $tmp[1] );
                    }

                    if (   $tail{ $e . '_2' } ne ''
                        && $cl[ $tail{ $e . '_2' } ] ne '' )
                    {
                        @tmp = split( /\,/, $cl[ $tail{ $e . '_2' } ] );
                        $out .= '|'
                          . $tmp[2] . ','
                          . $tmp[3] . '|'
                          . $tmp[0] . ','
                          . $tmp[1];
                        $cl[ $tail{ $e . '_2' } ] = '';
                        $tail{ $e . '_2' }        = '';
                        $e = '' . ( 1 * $tmp[0] ) . '_' . ( 1 * $tmp[1] );
                    }
                }

###

                while (
                    (
                           $tail{ $he . '_1' } ne ''
                        && $cl[ $tail{ $he . '_1' } ] ne ''
                    )
                    || (   $tail{ $he . '_2' } ne ''
                        && $cl[ $tail{ $he . '_2' } ] ne '' )
                    || (   $head{ $he . '_2' } ne ''
                        && $cl[ $head{ $he . '_2' } ] ne '' )
                    || (   $head{ $he . '_1' } ne ''
                        && $cl[ $head{ $he . '_1' } ] ne '' )
                  )
                {

                    if (   $tail{ $he . '_1' } ne ''
                        && $cl[ $tail{ $he . '_1' } ] ne '' )
                    {
                        @tmp = split( /\,/, $cl[ $tail{ $he . '_1' } ] );
                        $out = ''
                          . $tmp[0] . ','
                          . $tmp[1] . '|'
                          . $tmp[2] . ','
                          . $tmp[3] . '|'
                          . $out;
                        $cl[ $tail{ $he . '_1' } ] = '';
                        $tail{ $he . '_1' }        = '';
                        $he = '' . ( 1 * $tmp[0] ) . '_' . ( 1 * $tmp[1] );
                    }

                    if (   $tail{ $he . '_2' } ne ''
                        && $cl[ $tail{ $he . '_2' } ] ne '' )
                    {
                        @tmp = split( /\,/, $cl[ $tail{ $he . '_2' } ] );
                        $out = ''
                          . $tmp[0] . ','
                          . $tmp[1] . '|'
                          . $tmp[2] . ','
                          . $tmp[3] . '|'
                          . $out;
                        $cl[ $tail{ $he . '_2' } ] = '';
                        $tail{ $he . '_2' }        = '';
                        $he = '' . ( 1 * $tmp[0] ) . '_' . ( 1 * $tmp[1] );
                    }

                    if (   $head{ $he . '_1' } ne ''
                        && $cl[ $head{ $he . '_1' } ] ne '' )
                    {
                        @tmp = split( /\,/, $cl[ $head{ $he . '_1' } ] );
                        $out = ''
                          . $tmp[2] . ','
                          . $tmp[3] . '|'
                          . $tmp[0] . ','
                          . $tmp[1] . '|'
                          . $out;
                        $cl[ $head{ $he . '_1' } ] = '';
                        $head{ $he . '_1' }        = '';
                        $he = '' . ( 1 * $tmp[2] ) . '_' . ( 1 * $tmp[3] );
                    }
                    if (   $head{ $he . '_2' } ne ''
                        && $cl[ $head{ $he . '_2' } ] ne '' )
                    {
                        @tmp = split( /\,/, $cl[ $head{ $he . '_2' } ] );
                        $out = ''
                          . $tmp[2] . ','
                          . $tmp[3] . '|'
                          . $tmp[0] . ','
                          . $tmp[1] . '|'
                          . $out;
                        $cl[ $head{ $he . '_2' } ] = '';
                        $head{ $he . '_2' }        = '';
                        $he = '' . ( 1 * $tmp[2] ) . '_' . ( 1 * $tmp[3] );
                    }

                }

###

                $dxf .= '#' . $out;
            }
        }

###########33
        open( ULOS, ">" . $tempfolder . "c" . $layer . ".dxf" );
        print ULOS "  0
SECTION
  2
HEADER
  9
\$EXTMIN
 10
$xmin
 20
$ymin
  9
\$EXTMAX
 10
$xmax
 20
$ymax
  0
ENDSEC
  0
SECTION
  2
ENTITIES
  0
";

        @d = split( /\#/, $dxf );

        foreach $poly (@d) {
            chomp($poly);

            if ( $poly ne '' ) {
                @pairs = split( /\|/, $poly );

                for ( $k = 1 ; $k < $#pairs ; $k++ ) {
                    ( $x0, $y0 ) = split( /\,/, $pairs[ $k - 1 ] );
                    ( $x1, $y1 ) = split( /\,/, $pairs[$k] );
                    ( $x2, $y2 ) = split( /\,/, $pairs[ $k + 1 ] );

                    $x         = ( $x0 + $x1 + $x2 ) / 3;
                    $y         = ( $y0 + $y1 + $y2 ) / 3;
                    $pairs[$k] = '' . $x . ',' . $y;
                }
                for ( $k = 1 ; $k < $#pairs ; $k++ ) {
                    ( $x0, $y0 ) = split( /\,/, $pairs[ $k - 1 ] );
                    ( $x1, $y1 ) = split( /\,/, $pairs[$k] );
                    ( $x2, $y2 ) = split( /\,/, $pairs[ $k + 1 ] );

                    $x         = ( $x0 + $x1 + $x2 ) / 3;
                    $y         = ( $y0 + $y1 + $y2 ) / 3;
                    $pairs[$k] = '' . $x . ',' . $y;

                }
                print ULOS "POLYLINE
 66
1
  8
cliff1
  0\n";

                foreach $pair (@pairs) {
                    ( $x1, $y1 ) = split( /\,/, $pair );
                    $x1 = $x1 + $xmin;
                    $y1 = $y1 + $ymin;
                    print ULOS "VERTEX
  8
cliff1
 10
$x1
 20
$y1
  0\n";

                }
                print ULOS "SEQEND
  0\n";

            }
        }

###########3
        print ULOS "ENDSEC\n";
        print ULOS "  0\n";
        print ULOS "EOF\n";
        close(ULOS);

    }

    print ".... done.";
}

if ( $command eq 'makecliffs' ) {

    $xyzin     = 'xyztemp.xyz';
    $c1limit   = $pcliff1;        #$ARGV[2];
    $c2limit   = $pcliff2;        #$ARGV[3];
    $c3limit   = $pcliff2;        #$ARGV[4];
    $xyzfilein = 'xyztemp.xyz';

    $Config = Config::Tiny->new;
    $Config = Config::Tiny->read('pullauta.ini');

    $cliffthin = 1 * $Config->{_}->{cliffthin};
    if ( $cliffthin * 1 == 0 ) {
        $cliffthin = 1;
    }
    $steepfactor = 1 * $Config->{_}->{cliffsteepfactor};
    if ( $steepfactor * 1 == 0 ) {
        $steepfactor = 0.33;
    }

    $flatplace = 1 * $Config->{_}->{cliffflatplace};

    if ( $flatplace * 1 == 0 ) {
        $flatplace = 6.6;
    }

    $nosmallciffs = 1 * $Config->{_}->{cliffnosmallciffs};

    if ( $nosmallciffs * 1 == 0 ) {
        $nosmallciffs = 6;
    }
    else {
        $nosmallciffs = $nosmallciffs - $flatplace;
    }

    #print "#    $c1limit     $c2limit#\n";

    #$tempfolder='temp/';
    #$xyzfilein='xyztemp.xyz';

    print ".";
    $xmax = '';
    $ymax = '';
    $xmin = '';
    $ymin = '';
    $hmin = 999999;
    $hmax = -999999;

    open( SISAAN, "<" . $tempfolder . "$xyzfilein" );

    while ( $rec = <SISAAN> ) {
        @r = split( / /, $rec );
        if ( $r[3] == 2 ) {
            if ( $xmin ne '' ) {
                if ( $r[0] < $xmin ) { $xmin = $r[0]; }
            }
            else { $xmin = $r[0]; }
            if ( $xmax ne '' ) {
                if ( $r[0] > $xmax ) { $xmax = $r[0]; }
            }
            else { $xmax = $r[0]; }
            if ( $ymin ne '' ) {
                if ( $r[1] < $ymin ) { $ymin = $r[1]; }
            }
            else { $ymin = $r[1]; }
            if ( $ymax ne '' ) {
                if ( $r[1] > $ymax ) { $ymax = $r[1]; }
            }
            else { $ymax = $r[1]; }

            if ( $r[2] > $hmax ) { $hmax = $r[2]; }
            if ( $r[2] < $hmin ) { $hmin = $r[2]; }
        }
    }

    close SISAAN;
    print ".";

    ####
    open( SISAAN, "<" . $tempfolder . "xyz2.xyz" );
    @d = <SISAAN>;
    close SISAAN;

    @r1     = split( / /, $d[0] );
    @r2     = split( / /, $d[1] );
    $size   = $r2[1] - $r1[1];
    $xstart = $r1[0];
    $ystart = $r1[1];
    $sxmax  = -9999999999;
    $symax  = -9999999999;
    foreach $rec (@d) {
        @r = split( / /, $rec );

        $xyz[ floor( ( $r[0] - $xstart ) / $size ) ]
          [ floor( ( $r[1] - $ystart ) / $size ) ] = 1 * $r[2];
        if (   floor( ( $r[0] - $xstart ) / $size ) < 0
            || floor( ( $r[1] - $ystart ) / $size ) < 0 )
        {
            print "error";
            exit;
        }
        if ( $sxmax < floor( ( $r[0] - $xstart ) / $size ) ) {
            $sxmax = floor( ( $r[0] - $xstart ) / $size );
        }
        if ( $symax < floor( ( $r[1] - $ystart ) / $size ) ) {
            $symax = floor( ( $r[1] - $ystart ) / $size );
        }
        $c++;
    }
    print "..";

    # print "steepness\n";
    for ( $i = 3 ; $i < $sxmax - 4 ; $i++ ) {
        for ( $j = 3 ; $j < $symax - 4 ; $j++ ) {
            $low  = 999999999;
            $high = -999999999;
            for ( $ii = $i - 3 ; $ii < $i + 4 ; $ii++ ) {
                for ( $jj = $j - 3 ; $jj < $j + 4 ; $jj++ ) {
                    if ( $xyz[$ii][$jj] < $low )  { $low  = $xyz[$ii][$jj]; }
                    if ( $xyz[$ii][$jj] > $high ) { $high = $xyz[$ii][$jj]; }

                }
            }
            $steepness[$i][$j] = $high - $low;
        }
    }
    print ".";

    ####

    $img1 = new GD::Image( floor( $xmax - $xmin ), floor( $ymax - $ymin ) );
    $img2 = new GD::Image( floor( $xmax - $xmin ), floor( $ymax - $ymin ) );

    $white = $img1->colorAllocate( 255, 255, 255 );
    $black = $img1->colorAllocate( 0,   0,   0 );
    $white = $img2->colorAllocate( 255, 255, 255 );
    $black = $img2->colorAllocate( 0,   0,   0 );

    $xmin = floor( $xmin / 3 ) * 3;
    $ymin = floor( $ymin / 3 ) * 3;

    open( SISAAN, "<" . $tempfolder . "$xyzfilein" );

    while ( $rec = <SISAAN> ) {

        if ( $cliffthin > rand() ) {

            @r = split( / /, $rec );
            $i = 0;
            $j = 0;
            if ( $r[3] == 2 ) {

                $m[ floor( $r[0] - $xmin ) / 3 ][ floor( $r[1] - $ymin ) / 3 ]
                  .= '|'
                  . ( floor( $r[0] * 10 ) / 10 ) . ','
                  . ( floor( $r[1] * 10 ) / 10 ) . ','
                  . ( floor( $r[2] * 100 ) / 100 );

            }

        }
    }
    close SISAAN;
    $w = floor( $xmax - $xmin ) / 3;
    $h = floor( $ymax - $ymin ) / 3;
    undef @d;
####

    open( ULOS2, ">" . $tempfolder . "c2g.dxf" );
    print ULOS2 "  0
SECTION
  2
HEADER
  9
\$EXTMIN
 10
$xmin
 20
$ymin
  9
\$EXTMAX
 10
$xmax
 20
$ymax
  0
ENDSEC
  0
SECTION
  2
ENTITIES
  0
";
    open( ULOS3, ">" . $tempfolder . "c3g.dxf" );
    print ULOS3 "  0
SECTION
  2
HEADER
  9
\$EXTMIN
 10
$xmin
 20
$ymin
  9
\$EXTMAX
 10
$xmax
 20
$ymax
  0
ENDSEC
  0
SECTION
  2
ENTITIES
  0
";

    #  $img = new GD::Image( $w*3*600/254, $h*3*600/254 );

    #    $white = $img->colorAllocate( 255, 255, 255 );
    #   $black = $img->colorAllocate( 0, 0, 0 );

    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {
        if ( $x % ( floor( $w / 19 ) ) == 0 ) { print "."; }

        for ( $y = 0 ; $y < $h + 1 ; $y++ ) {

            if ( $m[$x][$y] ne '' ) {

                $test =
                    $m[ $x - 1 ][ $y - 1 ] . '|'
                  . $m[$x][ $y - 1 ] . '|'
                  . $m[ $x + 1 ][ $y - 1 ] . '|'
                  . $m[ $x - 1 ][$y] . '|'
                  . $m[$x][$y] . '|'
                  . $m[ $x + 1 ][$y] . '|'
                  . $m[ $x - 1 ][ $y + 1 ] . '|'
                  . $m[$x][ $y + 1 ] . '|'
                  . $m[ $x + 1 ][ $y + 1 ];
                $loop = $m[$x][$y];

                @d = split( /\|/, $loop );
                @t = split( /\|/, $test );

                if ( $#d > 30 ) {
                    $b = floor( $#d / 30 );
                    for ( $i = 0 ; $i < $#d ; $i++ ) {
                        splice( @d, $i, $b );
                    }
                }

                if ( $#t > 300 ) {
                    $b = floor( $#t / 300 );
                    for ( $i = 0 ; $i < $#t ; $i++ ) {
                        splice( @t, $i, $b );
                    }
                }

                # test is minmax big enough
                $tempmax = '';
                $tempmin = '';
                foreach $rec (@t) {
                    if ( $rec ne '' ) {
                        ( $x0, $y0, $h0 ) = split( /\,/, $rec );
                        if ( $tempmax eq '' || $tempmax < $h0 ) {
                            $tempmax = $h0;
                        }
                        if ( $tempin eq '' || $tempmin > $h0 ) {
                            $tempmin = $h0;
                        }
                    }
                }
                if ( $tempmax - $tempmin < $c1limit * 0.999 ) { @d = (); }

                foreach $rec (@d) {
                    if ( $rec ne '' ) {
                        ( $x0, $y0, $h0 ) = split( /\,/, $rec );

                        $clifflength = 1.47;
                        $steep =
                          $steepness[ floor( ( $x0 - $xstart ) / $size + 0.5 ) ]
                          [ floor( ( $y0 - $ystart ) / $size + 0.5 ) ] -
                          $flatplace;
                        if ( $steep < 0 )  { $steep = 0; }
                        if ( $steep > 17 ) { $steep = 17; }

                        $bonus = ( $c2limit - $c1limit ) *
                          ( 1 - ( $nosmallciffs - $steep ) / $nosmallciffs );
                        $limit = $c1limit + $bonus;

                        $bonus =
                          $c2limit * $steepfactor * ( $steep - $nosmallciffs );
                        if ( $bonus < 0 ) { $bonus = 0; }

                        $limit2 = $c2limit + $bonus;

                        foreach $rec2 (@t) {
                            if ( $rec2 ne '' ) {
                                ( $xt, $yt, $ht ) = split( /\,/, $rec2 );
                                $temp = $h0 - $ht;
                                $dist =
                                  sqrt( ( $x0 - $xt ) * ( $x0 - $xt ) +
                                      ( $y0 - $yt ) * ( $y0 - $yt ) );

                                if ( $dist > 0 ) {
                                    if (
                                           $steep < $nosmallciffs
                                        && $temp > $limit
                                        && $temp > (
                                            $limit + ( $dist - $limit ) * 0.85
                                        )
                                      )
                                    {
                                        ( $r, $g, $b ) = $img2->rgb(
                                            $img2->getPixel(
                                                floor(
                                                    ( $x0 + $xt ) / 2 -
                                                      $xmin + 0.5
                                                ),
                                                floor(
                                                    ( $y0 + $yt ) / 2 -
                                                      $ymin + 0.5
                                                )
                                            )
                                        );

                                        if ( $r == 255 ) {
                                            $img2->setPixel(
                                                floor(
                                                    ( $x0 + $xt ) / 2 -
                                                      $xmin + 0.5
                                                ),
                                                floor(
                                                    ( $y0 + $yt ) / 2 -
                                                      $ymin + 0.5
                                                ),
                                                $black
                                            );
                                            print ULOS2 "POLYLINE
 66
1
  8
cliff2
  0\n";

                                            print ULOS2 "VERTEX
  8
cliff2
 10
" . ( ( $x0 + $xt ) / 2 + $clifflength * ( ( $y0 - $yt ) / $dist ) ) . "
 20
" . ( ( ( $y0 + $yt ) / 2 ) - $clifflength * ( ( $x0 - $xt ) / $dist ) ) . "
  0\n";
                                            print ULOS2 "VERTEX
  8
cliff2
 10
" . ( ( $x0 + $xt ) / 2 - $clifflength * ( ( $y0 - $yt ) / $dist ) ) . "
 20
" . ( ( ( $y0 + $yt ) / 2 ) + $clifflength * ( ( $x0 - $xt ) / $dist ) ) . "
  0\n";
                                            print ULOS2 "SEQEND
  0\n";

                                        }
                                    }

                                    if (
                                        $temp > $limit2
                                        && $temp > (
                                            $limit2 +
                                              ( $dist - $limit2 ) * 0.85
                                        )
                                      )
                                    {
                                        print ULOS3 "POLYLINE
 66
1
  8
cliff3
  0\n";

                                        print ULOS3 "VERTEX
  8
cliff3
 10
" . ( ( $x0 + $xt ) / 2 + $clifflength * ( ( $y0 - $yt ) / $dist ) ) . "
 20
" . ( ( ( $y0 + $yt ) / 2 ) - $clifflength * ( ( $x0 - $xt ) / $dist ) ) . "
  0\n";
                                        print ULOS3 "VERTEX
  8
cliff3
 10
" . ( ( $x0 + $xt ) / 2 - $clifflength * ( ( $y0 - $yt ) / $dist ) ) . "
 20
" . ( ( ( $y0 + $yt ) / 2 ) + $clifflength * ( ( $x0 - $xt ) / $dist ) ) . "
  0\n";
                                        print ULOS3 "SEQEND
  0\n";

                                    }
                                }

                                #   $img->line(
                                #      ( $x0-$xmin ),
                                #     ( $y0-$ymin),
                                #     ( $xt-$xmin ),
                                #   ( $yt-$ymin), $black
                                #);

#   $img->filledArc( 600/254*(($x0+$xt)/2-$xmin), $h*3*600/254-600/254*((($y0+$yt)/2-$ymin)), 8, 8, 0, 360, $black );

#     $img->filledArc( 600/254*(($x0+$xt)/2-$xmin +2*(($y0-$yt)/$dist)), $h*3*600/254-600/254*((($y0+$yt)/2-$ymin) -2*(($x0-$xt)/$dist)), 8, 8, 0, 360, $black );
#     $img->filledArc( 600/254*(($x0+$xt)/2-$xmin -2*(($y0-$yt)/$dist)), $h*3*600/254-600/254*((($y0+$yt)/2-$ymin) +2*(($x0-$xt)/$dist)), 8, 8, 0, 360, $black );
#}

                            }
                        }

                    }

                }

            }

        }
    }

########################

    # grid based impassable cliffs

    # grid based impassable cliffs
    $c2limit = 2.6 * 2.75;
    undef @m;

    open( SISAAN, "<" . $tempfolder . "xyz2.xyz" );

    while ( $rec = <SISAAN> ) {

        @r = split( / /, $rec );
        $i = 0;
        $j = 0;

        $m[ floor( $r[0] - $xmin ) / 3 ][ floor( $r[1] - $ymin ) / 3 ] .= '|'
          . ( floor( $r[0] * 10 ) / 10 ) . ','
          . ( floor( $r[1] * 10 ) / 10 ) . ','
          . ( floor( $r[2] * 100 ) / 100 );

    }
    close SISAAN;
    $w = floor( $xmax - $xmin ) / 3;
    $h = floor( $ymax - $ymin ) / 3;
    undef @d;

    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {

        for ( $y = 0 ; $y < $h + 1 ; $y++ ) {

            if ( $m[$x][$y] ne '' ) {

                $test =
                    $m[ $x - 1 ][ $y - 1 ] . '|'
                  . $m[$x][ $y - 1 ] . '|'
                  . $m[ $x + 1 ][ $y - 1 ] . '|'
                  . $m[ $x - 1 ][$y] . '|'
                  . $m[$x][$y] . '|'
                  . $m[ $x + 1 ][$y] . '|'
                  . $m[ $x - 1 ][ $y + 1 ] . '|'
                  . $m[$x][ $y + 1 ] . '|'
                  . $m[ $x + 1 ][ $y + 1 ];
                $loop = $m[$x][$y];

                @d = split( /\|/, $loop );
                @t = split( /\|/, $test );

                foreach $rec (@d) {
                    if ( $rec ne '' ) {
                        ( $x0, $y0, $h0 ) = split( /\,/, $rec );

                        $clifflength = 1.47;

                        $limit = $c2limit;

                        foreach $rec2 (@t) {
                            if ( $rec2 ne '' ) {
                                ( $xt, $yt, $ht ) = split( /\,/, $rec2 );
                                $temp = $h0 - $ht;
                                $dist =
                                  sqrt( ( $x0 - $xt ) * ( $x0 - $xt ) +
                                      ( $y0 - $yt ) * ( $y0 - $yt ) );

                                if ( $dist > 0 ) {
                                    if (   $temp > $limit
                                        && $temp >
                                        ( $limit + ( $dist - $limit ) ) )
                                    {

                                        print ULOS3 "POLYLINE
 66
1
  8
cliff4
  0\n";

                                        print ULOS3 "VERTEX
  8
cliff4
 10
" . ( ( $x0 + $xt ) / 2 + $clifflength * ( ( $y0 - $yt ) / $dist ) ) . "
 20
" . ( ( ( $y0 + $yt ) / 2 ) - $clifflength * ( ( $x0 - $xt ) / $dist ) ) . "
  0\n";
                                        print ULOS3 "VERTEX
  8
cliff4
 10
" . ( ( $x0 + $xt ) / 2 - $clifflength * ( ( $y0 - $yt ) / $dist ) ) . "
 20
" . ( ( ( $y0 + $yt ) / 2 ) + $clifflength * ( ( $x0 - $xt ) / $dist ) ) . "
  0\n";
                                        print ULOS3 "SEQEND
  0\n";

                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
#######################3
#######################3

    print ULOS1 "ENDSEC\n";
    print ULOS1 "  0\n";
    print ULOS1 "EOF\n";
    close(ULOS1);
    print ULOS2 "ENDSEC\n";
    print ULOS2 "  0\n";
    print ULOS2 "EOF\n";
    close(ULOS);
    print ULOS3 "ENDSEC\n";
    print ULOS3 "  0\n";
    print ULOS3 "EOF\n";
    close(ULOS3);

    # open( ULOS, ">" . $tempfolder . "c1.png" );
    # binmode ULOS;
    # print ULOS $img1->png;
    # close ULOS;

    open( ULOS, ">" . $tempfolder . "c2.png" );
    binmode ULOS;
    print ULOS $img2->png;
    close ULOS;

    print ".done.";
}
####################################
if ( $command eq 'makevegenew' ) {

    $block = 1 * $Config->{_}->{'greendetectsize'};
    open( SISAAN, "<" . $tempfolder . "xyz2.xyz" );
    @d = <SISAAN>;
    close SISAAN;

    @r1     = split( / /, $d[0] );
    @r2     = split( / /, $d[1] );
    $size   = $r2[1] - $r1[1];
    $xstart = $r1[0];
    $ystart = $r1[1];

    $xmax = 0;
    $ymax = 0;
    foreach $rec (@d) {
        @r = split( / /, $rec );

        $xyz[ floor( ( $r[0] - $xstart ) / $size ) ]
          [ floor( ( $r[1] - $ystart ) / $size ) ] = 1 * $r[2];
        if (   floor( ( $r[0] - $xstart ) / $size ) < 0
            || floor( ( $r[1] - $ystart ) / $size ) < 0 )
        {
            print "error";
            exit;
        }

        if ( $xmax < floor( ( $r[0] - $xstart ) / $size ) ) {
            $xmax = floor( ( $r[0] - $xstart ) / $size );
        }
        if ( $ymax < floor( ( $r[1] - $ystart ) / $size ) ) {
            $ymax = floor( ( $r[1] - $ystart ) / $size );
        }
        $c++;
        if ( $r[2] > $top[ floor( ( $r[0] - $xstart ) / $block ) ]
            [ floor( ( $r[1] - $ystart ) / $block ) ] )
        {
            $top[ floor( ( $r[0] - $xstart ) / $block ) ]
              [ floor( ( $r[1] - $ystart ) / $block ) ] = $r[2];
        }
    }
    print "..";

    # low|high|roof|factor
    #zone1=0.5|1|99|0.7
    #zone2=1|4|99|1
    #zone3=4|9.0|11.0|0.4
    #zone4=4|100|100|0.01

    # roof low|roof high| greenhits/ground ratio to trigger green value 1
    #thresold1=0.5|3|0.14
    #thresold2=3|6|0.20
    #thresold3=6|12|0.3
    #thresold4=12|99|0.4

    # green values for triggering green shades. 5 shades.
    #greenshades=0.5|1.0|1.5|2.0|2.5

    # block size for calculation, unit is 3m side. 5 means 15x15m area.
    #blocksize=5

    # green dot size in meters to be drawn
    #dotsize=8

    #yellowheight=0.5
    #yellowthresold=0.87

    $i = 1;
    while ( $Config->{_}->{ 'zone' . $i } ne '' ) {
        $zone[$i] = $Config->{_}->{ 'zone' . $i };
        $i++;
    }
    $i = 1;
    while ( $Config->{_}->{ 'thresold' . $i } ne '' ) {
        $thresold[$i] = $Config->{_}->{ 'thresold' . $i };
        $i++;
    }

    @greenshades         = split( /\|/, $Config->{_}->{'greenshades'} );
    $greensize           = 0;    # = 1 * $Config->{_}->{'greendetectsize'};
    $dotsize             = 1 * $Config->{_}->{'dotsize'};
    $yellowheight        = 1 * $Config->{_}->{'yellowheight'};
    $yellowthresold      = 1 * $Config->{_}->{'yellowthresold'};
    $greenground         = 1 * $Config->{_}->{'greenground'};
    $pointvolumefactor   = 1 * $Config->{_}->{'pointvolumefactor'};
    $pointvolumeexponent = 1 * $Config->{_}->{'pointvolumeexponent'};
    $greenhigh           = 1 * $Config->{_}->{'greenhigh'};
    $topweight           = 1 * $Config->{_}->{'topweight'};
    $greentone           = 1 * $Config->{_}->{'lightgreentone'};
    $zoffset             = 1 * $Config->{_}->{'vegezoffset'};

    $uglimit  = 1 * $Config->{_}->{'undergrowth'};
    $uglimit2 = 1 * $Config->{_}->{'undergrowth2'};

    $xyzin = 'xyztemp.xyz';

    $xmin     = $xstart;
    $ymin     = $ystart;
    $hmin     = 999999;
    $hmax     = -999999;
    $counter  = 0;
    $addition = 1 * $Config->{_}->{'greendotsize'};

    $firstandlastreturnasground =
      1 * $Config->{_}->{'firstandlastreturnasground'};
    if ( $firstandlastreturnasground == 0 ) {
        $firstandlastreturnasground = 1;
    }
    $firstandlastfactor = 1 * $Config->{_}->{'firstandlastreturnfactor'};
    $lastfactor         = 1 * $Config->{_}->{'lastreturnfactor'};
    if ( $Config->{_}->{'yellowfirstlast'} eq '' ) {
        $yellowfirstlast = 1;
    }
    else {
        $yellowfirstlast = 1 * $Config->{_}->{'yellowfirstlast'};
    }

    #print "
    #    $xmax
    #    $ymax
    #    $xmin
    #    $ymin
    #
    #    $hmin
    #    $hmax
    #";
    print "..";

    open( SISAAN, "<" . $tempfolder . "$xyzin" );
    $counter = 0;
    while ( $rec = <SISAAN> ) {
        $counter++;
        if ( $vegethin == 0 || $counter % $vegethin == 0 ) {
            @r = split( / /, $rec );
            $i = 0;
            $j = 0;

            if ( $xmax ne '' ) {
                if ( $r[0] > $xmax ) { $xmax = $r[0]; }
            }
            else { $xmax = $r[0]; }

            if ( $ymax ne '' ) {
                if ( $r[1] > $ymax ) { $ymax = $r[1]; }
            }
            else { $ymax = $r[1]; }

            if ( $r[0] > $xmin && $r[1] > $ymin ) {
                if ( $r[2] > $top[ floor( ( $r[0] - $xmin ) / $block ) ]
                    [ floor( ( $r[1] - $ymin ) / $block ) ] )
                {
                    $top[ floor( ( $r[0] - $xmin ) / $block ) ]
                      [ floor( ( $r[1] - $ymin ) / $block ) ] = $r[2];
                }
            }
        }
    }

    close SISAAN;
    undef @d;

    # yellow

    print "..";
    ##
    open( SISAAN, "<" . $tempfolder . "$xyzin" );
    $counter = 0;
    while ( $rec = <SISAAN> ) {
        $counter++;
        if ( $vegethin == 0 || $counter % $vegethin == 0 ) {
            @r = split( / /, $rec );
            $i = 0;
            $j = 0;

            if ( $xmax ne '' ) {
                if ( $r[0] > $xmax ) { $xmax = $r[0]; }
            }
            else { $xmax = $r[0]; }

            if ( $ymax ne '' ) {
                if ( $r[1] > $ymax ) { $ymax = $r[1]; }
            }
            else { $ymax = $r[1]; }

            if ( $r[0] > $xmin && $r[1] > $ymin ) {
                $hits[ floor( ( $r[0] - $xmin ) / 3 ) ]
                  [ floor( ( $r[1] - $ymin ) / 3 ) ] += 1;
                if (   $r[3] == 2
                    || $r[2] <= $yellowheight +
                    $xyz[ floor( ( $r[0] - $xmin ) / $size ) ]
                    [ floor( ( $r[1] - $ymin ) / $size ) ] )
                {

                    $yhit[ floor( ( $r[0] - $xmin ) / 3 ) ]
                      [ floor( ( $r[1] - $ymin ) / 3 ) ] += 1;
                }
                else {
                    if ( ( $r[4] == 1 && $r[5] == 1 ) ) {
                        $noyhit[ floor( ( $r[0] - $xmin ) / 3 ) ]
                          [ floor( ( $r[1] - $ymin ) / 3 ) ] +=
                          $yellowfirstlast;
                    }
                    else {
                        $noyhit[ floor( ( $r[0] - $xmin ) / 3 ) ]
                          [ floor( ( $r[1] - $ymin ) / 3 ) ] += 1;
                    }
                }
            }
        }
    }
    close SISAAN;
    undef @d;

    # green
    print "..";
    ##
    open( SISAAN, "<" . $tempfolder . "$xyzin" );
    $counter = 0;
    while ( $rec = <SISAAN> ) {
        $counter++;
        if ( $vegethin == 0 || $counter % $vegethin == 0 ) {
            @r = split( / /, $rec );
            $i = 0;
            $j = 0;

            $r[2] = $r[2] - $zoffset;
            if ( $r[0] > $xmin && $r[1] > $ymin ) {

                if ( $r[5] == 1 ) {
                    $firsthit[ floor( ( $r[0] - $xmin ) / $block + 0.5 ) ]
                      [ floor( ( $r[1] - $ymin ) / $block + 0.5 ) ] += 1;

                }

                $a = $xyz[ floor( ( $r[0] - $xmin ) / $size ) ]
                  [ floor( ( $r[1] - $ymin ) / $size ) ];
                $b = $xyz[ floor( ( $r[0] - $xmin ) / $size ) + 1 ]
                  [ floor( ( $r[1] - $ymin ) / $size ) ];
                $c = $xyz[ floor( ( $r[0] - $xmin ) / $size ) ]
                  [ floor( ( $r[1] - $ymin ) / $size ) + 1 ];
                $d = $xyz[ floor( ( $r[0] - $xmin ) / $size ) + 1 ]
                  [ floor( ( $r[1] - $ymin ) / $size ) + 1 ];

                $distx = ( $r[0] - $xmin ) / $size -
                  floor( ( $r[0] - $xmin ) / $size );
                $disty = ( $r[1] - $ymin ) / $size -
                  floor( ( $r[1] - $ymin ) / $size );

                $ab = $a * ( 1 - $distx ) + $b * $distx;
                $cd = $c * ( 1 - $distx ) + $d * $distx;

                $thelele = $ab * ( 1 - $disty ) + $cd * $disty;
## undergrowth
                if ( $r[0] > $xmin && $r[1] > $ymin ) {
                    if ( 1.2 >= $r[2] - $thelele ) {

                        if ( $r[3] == 2 ) {
                            $ugg[ floor( ( $r[0] - $xmin ) / $block / 6 + .5 ) ]
                              [ floor( ( $r[1] - $ymin ) / $block / 6 ) + .5 ]
                              += 1;
                        }
                        else {
                            if ( 0.25 < $r[2] - $thelele ) {
                                $ug[ floor(
                                      ( $r[0] - $xmin ) / $block / 6 + .5 ) ]
                                  [ floor( ( $r[1] - $ymin ) / $block / 6 ) +
                                  .5 ] += 1;
                            }
                            else {
                                $ugg[ floor(
                                      ( $r[0] - $xmin ) / $block / 6 + .5 ) ]
                                  [ floor( ( $r[1] - $ymin ) / $block / 6 ) +
                                  .5 ] += 1;
                            }
                        }

                    }
                    else {
                        $ugg[ floor( ( $r[0] - $xmin ) / $block / 6 + .5 ) ]
                          [ floor( ( $r[1] - $ymin ) / $block / 6 ) + .5 ] +=
                          0.05;
                    }
                }
##
                if (   $r[3] == 2
                    || $greenground >= $r[2] - $thelele )
                {
                    if   ( $r[3] == 2 ) { $foo1++; }
                    else                { $foo2++; }

                   #@cols=split(/\#/,$row[ floor($r[0] - $xmin ) ]);
                   #$cols[ floor( $r[1] - $ymin ) ] .=              '|' . $r[2];
                   #$row[ floor($r[0] - $xmin ) ]=join('#',@cols);
                    if ( $r[0] > $xmin && $r[1] > $ymin ) {

                        if ( $r[4] == 1 && $r[5] == 1 ) {
                            $ghit[ floor( ( $r[0] - $xmin ) / $block + .5 ) ]
                              [ floor( ( $r[1] - $ymin ) / $block ) + .5 ] +=
                              $firstandlastreturnasground;
                        }
                        else {
                            $ghit[ floor( ( $r[0] - $xmin ) / $block + .5 ) ]
                              [ floor( ( $r[1] - $ymin ) / $block ) + .5 ] += 1;
                        }
                    }
                }
                else {

#	pullauta $thread makevegenew xyztemp.xyz $pvege_yellow $pvege_green $lightgreenlimit $darkgreenlimit $yellowlimit
# && ( $r[4] != 1 || $r[5] != 1  )
                    if (   $r[0] > $xmin
                        && $r[1] > $ymin )
                    {
                        #interpolated elevation needed?

                        #last
                        $last = 1;
                        if ( $r[5] == $r[4] ) {

                            #if($r[2] -$thelele  < 7){
                            $last = $lastfactor;

                            #}
                        }

                        #firstandlast
                        if ( $r[4] == 1 && $r[5] == 1 ) {
                            if ( $r[2] - $thelele < 5 ) {
                                $last = $firstandlastfactor;
                            }

                        }

                        #zone1=0.5|1|99|0.7
                        $out = 0;
                        for ( $i = 0 ; $i < $#zone + 1 && $out == 0 ; $i++ ) {
                            @vals = split( /\|/, $zone[$i] );
                            if (
                                   $out == 0
                                && $r[2] - $thelele >= $vals[0]
                                && $r[2] - $thelele < $vals[1]
                                && $top[
                                floor( ( $r[0] - $xmin ) / $block + 0.5 )
                                ][ floor( ( $r[1] - $ymin ) / $block + 0.5 ) ]
                                - $thelele < $vals[2]
                              )
                            {

                                $greenhit[ floor(
                                      ( $r[0] - $xmin ) / $block + 0.5 ) ]
                                  [ floor( ( $r[1] - $ymin ) / $block + 0.5 ) ]
                                  += $vals[3] * $last;
                                $out = 1;
                            }

                        }

                        if ( $thelele + $greenhigh < $r[2] ) {
                            $highit[ floor( ( $r[0] - $xmin ) / $block + 0.5 ) ]
                              [ floor( ( $r[1] - $ymin ) / $block + 0.5 ) ] +=
                              1;

                        }

#				if($r[2] < $pvege_green+$xyz[ floor( ($r[0] - $xmin )/$size) ][floor( ($r[1] - $ymin )/$size)] && $r[2] > $pvege_low+$xyz[ floor( ($r[0] - $xmin )/$size) ][floor( ($r[1] - $ymin )/$size)]) {
#$greenhit[ floor( ($r[0] - $xmin )/$block) ][floor( ($r[1] - $ymin )/$block)] +=1;
#               }else{
#				#print "".$top[ floor( ($r[0] - $xmin )/$block) ][floor( ($r[1] - $ymin )/$block)].' '.$highheight.'  '.$xyz[ floor( ($r[0] - $xmin )/$size) ][floor( ($r[1] - $ymin )/$size)]."\n";
#				if($r[2]  >= $pvege_green+$xyz[ floor( ($r[0] - $xmin )/$size) ][floor( ($r[1] - $ymin )/$size)] && $highheight >  $top[ floor( ($r[0] - $xmin )/$block) ][floor( ($r[1] - $ymin )/$block)] -$xyz[ floor( ($r[0] - $xmin )/$size) ][floor( ($r[1] - $ymin )/$size)] ) {
#				$greenhit[ floor( ($r[0] - $xmin )/$block) ][floor( ($r[1] - $ymin )/$block)] +=1*$highfactor;
#				#print "X\n";
###				}else{
#				if($r[2]  >= $pvege_green+$xyz[ floor( ($r[0] - $xmin )/$size) ][floor( ($r[1] - $ymin )/$size)]) {
#
#				$highhit[ floor( ($r[0] - $xmin )/$block) ][floor( ($r[1] - $ymin )/$block)] +=1;
#}
#				if($r[2]  <= $pvege_low+$xyz[ floor( ($r[0] - $xmin )/$size) ][floor( ($r[1] - $ymin )/$size)]) {
#
#				$ghit[ floor( ($r[0] - $xmin )/$block) ][floor( ($r[1] - $ymin )/$block)] +=1;
#}
#}
#				}
                    }
                }
            }
        }
    }
    close SISAAN;
    undef @d;

    print "..";

    $w  = floor( $xmax - $xmin ) / $block;
    $h  = floor( $ymax - $ymin ) / $block;
    $wy = floor( $xmax - $xmin ) / 3;
    $hy = floor( $ymax - $ymin ) / 3;

    $avevolume = $counter / $w / $h;

    #print "\n $greenground  $foo1 $foo2 \n";
####################################################
    use GD;

    # 600 / 254 /$scalefactor
    $imgug = new GD::Image(
        $w * $block * 600 / 254 / $scalefactor,
        $h * $block * 600 / 254 / $scalefactor
    );

    $imggr1  = new GD::Image( $w * $block, $h * $block );
    $imggr1b = new GD::Image( $w * $block, $h * $block );

    $imgye2 = new GD::Image( $w * $block, $h * $block );

    $imgwater = new GD::Image( $w * $block, $h * $block );
    $wh2      = $imgwater->colorAllocate( 255, 255, 255 );

    #252,254,252
    #252,254,4
    #4,254,4

    $wh2 = $imggr1->colorAllocate( 255, 255, 255 );
    $foo = $imggr1b->colorAllocate( 255, 255, 255 );

    #print "\n$wh2  $foo\n";
    for ( $gshade = 0 ; $gshade < $#greenshades + 1 ; $gshade++ ) {
        $gr1[$gshade] = $imggr1->colorAllocate(
            $greentone - ( $greentone / $#greenshades ) * $gshade,
            254 - ( 74 / $#greenshades ) * $gshade,
            $greentone - ( $greentone / $#greenshades ) * $gshade
        );
        $foo = $imggr1b->colorAllocate(
            $greentone - ( $greentone / $#greenshades ) * $gshade,
            254 - ( 74 / $#greenshades ) * $gshade,
            $greentone - ( $greentone / $#greenshades ) * $gshade
        );

        #print ''.$gr1[$gshade].'  '.$foo."\n";
    }

    $wh2 = $imgye2->colorAllocate( 255, 255, 255 );

    $ye2 = $imgye2->colorAllocate( 255, 219, 166 );

    $imgwater->filledRectangle( 0, 0, $w * $block + 1, $h * $block + 1, $wh2 );
    $imggr1->filledRectangle( 0, 0, $w * $block + 1, $h * $block + 1, $wh2 );
    $imgye2->filledRectangle( 0, 0, $w * $block + 1, $h * $block + 1, $wh2 );
    print "...";
    $greendetectsize = $greendetectsize / 2;

    $aveg     = 0;
    $avecount = 0;
    for ( $x = $greensize + 1 ; $x < $w - $greensize ; $x++ ) {

        for ( $y = $greensize + 1 ; $y < $h - $greensize ; $y++ ) {
            if ( $ghit[$x][$y] > 1 ) {

                $aveg += $firsthit[$x][$y];
                $avecount++;
            }
        }
    }
    $aveg = $aveg / $avecount;

    # yellow

    for ( $x = 3 + 1 ; $x < $wy - 3 ; $x++ ) {

        for ( $y = 3 + 1 ; $y < $hy - 3 ; $y++ ) {

            $ghit      = 0;
            $greenhit  = 0;
            $highhit   = 0;
            $roof      = 0;
            $count     = 0;
            $totalhits = 0;
            $avetotal  = 0;
            $inhit     = 0;
            $outhit    = 0;
            $highit    = 0;
            $firsthit  = 0;

            $i = $x;
            $j = $y;

            $ghit2     = 0;
            $greenhit2 = 0;
            $highhit2  = 0;
            for ( $i = $x ; $i < $x + 2 ; $i++ ) {
                for ( $j = $y ; $j < $y + 2 ; $j++ ) {
                    $ghit2    += $yhit[$i][$j];
                    $highhit2 += $noyhit[$i][$j];
                }
            }

            if ( ($ghit2) / ( $highhit2 + $ghit2 + 0.01 ) > $yellowthresold ) {

                #                $imgye2->filledArc(
                #                    $x * 3 + 3 / 2+3,
                #                    ( $hy - $y ) * 3 - 3 / 2-3,
                #                    3*1.7, 3*1.7, 0, 360, $ye2
                #                );

                $imgye2->filledRectangle(
                    $x * 3 - 1 + 3,
                    ( $hy - $y ) * 3 - 1 - 3,
                    $x * 3 + 1 + 3,
                    ( $hy - $y ) * 3 + 1 - 3, $ye2
                );

            }
        }

    }

    #green
    for ( $x = $greensize + 2 ; $x < $w - $greensize * 1 ; $x++ ) {

        for ( $y = $greensize + 2 ; $y < $h - $greensize * 2 ; $y++ ) {

            $ghit      = 0;
            $greenhit  = 0;
            $highhit   = 0;
            $roof      = 0;
            $count     = 0;
            $totalhits = 0;
            $avetotal  = 0;
            $inhit     = 0;
            $outhit    = 0;
            $highit    = 0;
            $firsthit  = 0;

#$top[ floor( $x) ][floor($y)] -$xyz[ floor( $x*$block/$size) ][floor( $y*$block/$size)]
#thresold1=0.5|3|0.14
            $i = $x;
            $j = $y;
            $roof +=
              $top[ floor($x) ][ floor($y) ] -
              $xyz[ floor( $x * $block / $size ) ]
              [ floor( $y * $block / $size ) ];
            $outhit++;
            $greenhit = $greenhit[$i][$j];
            $firsthit = $firsthit[$i][$j];
            for ( $x_ = $x - 2 ; $x_ < $x + 3 ; $x_++ ) {
                for ( $y_ = $y - 2 ; $y_ < $y + 3 ; $y_++ ) {
                    if ( $firsthit > $firsthit[$x_][$y_] ) {
                        $firsthit = $firsthit[$x_][$y_];
                    }
                }
            }

            $highit += $highit[$i][$j];

#if(floor($i) == floor($x) &&  floor($j) == floor($y) ){ $inhit++; $greenhit += $greenhit[$i][$j];}

            $ghit += $ghit[$i][$j];
            $count++;
            $totalhits += $hits[$i][$j];
            $avetotal  += $avevolume;

            $vol  = $totalhits / $avetotal;
            $roof = $roof / $count;

            #$highgreenfactor $highgreenheight

            $greenlimit = 9999;
            for ( $i = 0 ; $i < $#thresold + 1 ; $i++ ) {
                @vals = split( /\|/, $thresold[$i] );

                if ( $roof >= $vals[0] && $roof < $vals[1] ) {
                    $greenlimit = $vals[2];
                    last;
                }
            }

            #print " $colsvege[$y]- $cols[$y] \n";
            #$col = $ye2;
            #if ( $colsvege[$y] eq '' ) {
            $col = $wh2;

#   }
#else {
#	pullauta $thread makevegenew xyztemp.xyz $pvege_yellow $pvege_green $lightgreenlimit $darkgreenlimit $yellowlimit
            $greenshade = 0;
            $highfactor = 0;

#$myfactor =  0;#(0.2+( $totalhits - $avetotal ) / $avetotal) * ($pointvolumefactor-1);
#if($myfactor < 0){$myfactor=0;}

            # $ghit=$ghit + $ghit * $myfactor;
            #print "$ghit  $aveg  $count\n";
            #if($ghit < $aveg *$count * 0.25){
            #$ghit=$aveg *$count * 0.25;
            #}

            $thevalue =
              $greenhit /
              ( $ghit + $greenhit + 1 ) *
              ( 1 - $topweight +
                  $topweight * $highit / ( $ghit + $greenhit + $highit + 1 ) )
              * ( 1 - $pointvolumefactor * $firsthit / ( $aveg + 0.00001 ) )
              **$pointvolumeexponent;

            if ( $thevalue > 0 ) {
                for ( $gshade = 0 ; $gshade < $#greenshades + 1 ; $gshade++ ) {

                    if ( $thevalue > ( $greenlimit * $greenshades[$gshade] ) ) {
                        $greenshade = $gshade + 1;
                    }

                }
                if ( $greenshade > 0 ) {

                    $imggr1->filledRectangle(
                        $block / 2 + $x * $block - $addition,
                        -$block / 2 + ( $h - $y ) * $block - $addition,
                        $block / 2 + $x * $block + $block - 1 + $addition,
                        -$block / 2 +
                          ( $h - $y ) * $block +
                          $block - 1 +
                          $addition,
                        $gr1[ $greenshade - 1 ]
                    );
                }
            }

        }

    }

    print "..";

    $imgye2->transparent($wh2);

    # median filter
    for ( $y = 0 ; $y < $h * $block - $med ; $y++ ) {
        undef @v;
        $k = 0;
        for ( $x = $med ; $x < $w * $block - $med ; $x++ ) {

            #for($i=-$med/2;$i<$med/2;$i++){
            for ( $j = -$med / 2 ; $j < $med / 2 ; $j++ ) {

                $v[$k] = $imggr1->getPixel( floor( $x + $med / 2 ),
                    floor( $y + $j + .5 ) );
                $k++;
            }
            if ( $k > $med * $med - 1 ) {
                $k = 0;
            }

            #}
            @w = sort { $a <=> $b } @v;

            $imggr1b->setPixel( $x, $y, $w[ $#w / 2 ] );
        }
    }
    #
    # median filter 2

    if ( $med2 > 0 ) {
        for ( $y = 0 ; $y < $h * $block - $med2 ; $y++ ) {
            undef @v;
            $k = 0;
            for ( $x = $med2 ; $x < $w * $block - $med2 ; $x++ ) {

                #for($i=-$med/2;$i<$med/2;$i++){
                for ( $j = -$med2 / 2 ; $j < $med2 / 2 ; $j++ ) {

                    $v[$k] = $imggr1b->getPixel( floor( $x + $med2 / 2 ),
                        floor( $y + $j + .5 ) );
                    $k++;
                }
                if ( $k > $med2 * $med2 - 1 ) {
                    $k = 0;
                }

                #}
                @w = sort { $a <=> $b } @v;

                $imggr1->setPixel( $x, $y, $w[ $#w / 2 ] );
            }
        }
    }
    else {
        #
        $imggr1->copy( $imggr1b, 0, 0, 0, 0, $w * $block, $h * $block );
    }
    $imggr1->copy( $imgye2, 0, 0, 0, 0, $w * $block, $h * $block );

    $black = $imgwater->colorAllocate( 0,  0,   0 );
    $blue  = $imgwater->colorAllocate( 29, 190, 255 );

    if ( $buildings > 0 || $water > 0 ) {

        open( SISAAN, "<" . $tempfolder . "/xyztemp.xyz" );

        while ( $rec = <SISAAN> ) {
            @r = split( / /, $rec );

            if ( $r[3] == $buildings ) {
                $imgwater->setPixel( ( $r[0] - $xmin + 1 ),
                    ( $ymax - $r[1] - 1 ), $black );
                $imgwater->setPixel( ( $r[0] - $xmin + 1 ),
                    ( $ymax - $r[1] ), $black );
                $imgwater->setPixel( ( $r[0] - $xmin + 1 ),
                    ( $ymax - $r[1] + 1 ), $black );
                $imgwater->setPixel( ( $r[0] - $xmin ),
                    ( $ymax - $r[1] - 1 ), $black );
                $imgwater->setPixel( ( $r[0] - $xmin ),
                    ( $ymax - $r[1] ), $black );
                $imgwater->setPixel( ( $r[0] - $xmin ),
                    ( $ymax - $r[1] + 1 ), $black );
                $imgwater->setPixel( ( $r[0] - $xmin - 1 ),
                    ( $ymax - $r[1] - 1 ), $black );
                $imgwater->setPixel( ( $r[0] - $xmin - 1 ),
                    ( $ymax - $r[1] ), $black );
                $imgwater->setPixel( ( $r[0] - $xmin - 1 ),
                    ( $ymax - $r[1] + 1 ), $black );
            }
            if ( $r[3] == $water ) {
                $imgwater->setPixel( ( $r[0] - $xmin + 1 ),
                    ( $ymax - $r[1] - 1 ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin + 1 ),
                    ( $ymax - $r[1] ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin + 1 ),
                    ( $ymax - $r[1] + 1 ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin ),
                    ( $ymax - $r[1] - 1 ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin ),
                    ( $ymax - $r[1] ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin ),
                    ( $ymax - $r[1] + 1 ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin - 1 ),
                    ( $ymax - $r[1] - 1 ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin - 1 ),
                    ( $ymax - $r[1] ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin - 1 ),
                    ( $ymax - $r[1] + 1 ), $blue );
            }
        }
        close SISAAN;
    }

    if ( $waterele > -90 ) {

        open( SISAAN, "<" . $tempfolder . "/xyz2.xyz" );

        while ( $rec = <SISAAN> ) {

            @r = split( / /, $rec );

            if ( $r[2] < $waterele ) {
                $imgwater->setPixel( ( $r[0] - $xmin + 1 ),
                    ( $ymax - $r[1] - 1 ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin + 1 ),
                    ( $ymax - $r[1] ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin + 1 ),
                    ( $ymax - $r[1] + 1 ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin ),
                    ( $ymax - $r[1] - 1 ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin ),
                    ( $ymax - $r[1] ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin ),
                    ( $ymax - $r[1] + 1 ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin - 1 ),
                    ( $ymax - $r[1] - 1 ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin - 1 ),
                    ( $ymax - $r[1] ), $blue );
                $imgwater->setPixel( ( $r[0] - $xmin - 1 ),
                    ( $ymax - $r[1] + 1 ), $blue );
            }

        }

        close SISAAN;
    }

    ## undergrowth
    $uqwhite  = $imgug->colorAllocate( 255, 255, 255 );
    $underg   = $imgug->colorAllocate( 64,  121, 0 );
    $tmpfacor = 600 / 254 / $scalefactor;
    for ( $x = 0 ; $x < $w * $block ; $x = $x + $block * 6 ) {
        for ( $y = 0 ; $y < $h * $block ; $y = $y + $block * 6 ) {
            if (
                $ug[ $x / $block / 6 ][ $y / $block / 6 ] / (
                    $ug[ $x / $block / 6 ][ $y / $block / 6 ] +
                      $ugg[ $x / $block / 6 ][ $y / $block / 6 ] + 0.01
                ) > $uglimit
              )
            {

                $imgug->line(
                    $tmpfacor * ( $x + $block * 3 ),
                    $tmpfacor * ( $h * $block - $y - $block * 3 ),
                    $tmpfacor * ( $x + $block * 3 ),
                    $tmpfacor * ( $h * $block - $y + $block * 3 ),
                    $underg
                );
                $imgug->line(
                    $tmpfacor * ( $x + $block * 3 ) + 1,
                    $tmpfacor * ( $h * $block - $y - $block * 3 ),
                    $tmpfacor * ( $x + $block * 3 ) + 1,
                    $tmpfacor * ( $h * $block - $y + $block * 3 ),
                    $underg
                );

                $imgug->line(
                    $tmpfacor * ( $x - $block * 3 ),
                    $tmpfacor * ( $h * $block - $y - $block * 3 ),
                    $tmpfacor * ( $x - $block * 3 ),
                    $tmpfacor * ( $h * $block - $y + $block * 3 ),
                    $underg
                );
                $imgug->line(
                    $tmpfacor * ( $x - $block * 3 ) + 1,
                    $tmpfacor * ( $h * $block - $y - $block * 3 ),
                    $tmpfacor * ( $x - $block * 3 ) + 1,
                    $tmpfacor * ( $h * $block - $y + $block * 3 ),
                    $underg
                );

            }
            if (
                $ug[ $x / $block / 6 ][ $y / $block / 6 ] / (
                    $ug[ $x / $block / 6 ][ $y / $block / 6 ] +
                      $ugg[ $x / $block / 6 ][ $y / $block / 6 ] + 0.01
                ) > $uglimit2
              )
            {

                $imgug->line(
                    $tmpfacor * $x,
                    $tmpfacor * ( $h * $block - $y - $block * 3 ),
                    $tmpfacor * ($x),
                    $tmpfacor * ( $h * $block - $y + $block * 3 ),
                    $underg
                );
                $imgug->line(
                    $tmpfacor * $x + 1,
                    $tmpfacor * ( $h * $block - $y - $block * 3 ),
                    $tmpfacor * ($x) + 1,
                    $tmpfacor * ( $h * $block - $y + $block * 3 ),
                    $underg
                );
            }
        }
    }
    $imgug->transparent($uqwhite);
    $underg = $imggr1->colorAllocate( 64, 121, 0 );

    #$imggr1->copy( $imgug, 0, 0, 0, 0, $w * $block, $h * $block );
    ## undegrowth

    open( ULOS, ">" . $tempfolder . "blueblack.png" );
    binmode ULOS;
    print ULOS $imgwater->png;
    close ULOS;

    open( ULOS, ">" . $tempfolder . "vegetation.png" );
    binmode ULOS;
    print ULOS $imggr1->png;
    close ULOS;

    open( ULOS, ">" . $tempfolder . "undergrowth.png" );
    binmode ULOS;
    print ULOS $imgug->png;
    close ULOS;

    open( ULOS, ">" . $tempfolder . "vegetation.pgw" );
    print ULOS "1.0
0.0
0.0
-1.0
$xmin
$ymax
";

    close ULOS;

    open( ULOS, ">" . $tempfolder . "undergrowth.pgw" );
    print ULOS "" . ( 1 / $tmpfacor ) . "
0.0
0.0
-" . ( 1 / $tmpfacor ) . "
$xmin
$ymax
";

    close ULOS;

    print "..... done.";
}

#####
if ( $command eq 'makeheight' ) {

    $block = 3;    # = 1 * $Config->{_}->{'blocksize'};
    open( SISAAN, "<" . $tempfolder . "xyz2.xyz" );
    @d = <SISAAN>;
    close SISAAN;

    @r1     = split( / /, $d[0] );
    @r2     = split( / /, $d[1] );
    $size   = $r2[1] - $r1[1];
    $xstart = $r1[0];
    $ystart = $r1[1];

    $xmax = 0;
    $ymax = 0;
    foreach $rec (@d) {
        @r = split( / /, $rec );

        $xyz[ floor( ( $r[0] - $xstart ) / $size ) ]
          [ floor( ( $r[1] - $ystart ) / $size ) ] = 1 * $r[2];
        if (   floor( ( $r[0] - $xstart ) / $size ) < 0
            || floor( ( $r[1] - $ystart ) / $size ) < 0 )
        {
            print "error";
            exit;
        }

        if ( $xmax < floor( ( $r[0] - $xstart ) / $size ) ) {
            $xmax = floor( ( $r[0] - $xstart ) / $size );
        }
        if ( $ymax < floor( ( $r[1] - $ystart ) / $size ) ) {
            $ymax = floor( ( $r[1] - $ystart ) / $size );
        }
        $c++;
    }

    $xyzin = 'xyztemp.xyz';

    print "..";

    open( SISAAN, "<" . $tempfolder . "$xyzin" );
    while ( $rec = <SISAAN> ) {
        @r = split( / /, $rec );
        if ( $r[2] > $top[ floor( ( $r[0] - $xstart ) / $block ) ]
            [ floor( ( $r[1] - $ystart ) / $block ) ] )
        {
            $top[ floor( ( $r[0] - $xstart ) / $block ) ]
              [ floor( ( $r[1] - $ystart ) / $block ) ] = $r[2];
        }
    }
    print "..";

    $w = floor( $xmax - $xmin ) * $size / $block;
    $h = floor( $ymax - $ymin ) * $size / $block;

    use GD;

    $imggr1 = new GD::Image( $w * $block, $h * $block, 1 );

    for ( $x = 0 ; $x < $w ; $x++ ) {

        for ( $y = 0 ; $y < $h ; $y++ ) {
            $tone =
              ( $top[$x][$y] -
                  $xyz[ floor( 0.5 + $x * 3 / 2 ) ][ floor( 0.5 + $y * 3 / 2 ) ]
              ) * 5;

   #print ''.$top[$x][$y].' - '.$xyz[floor(0.5+$x*3/2)][floor(0.5+$y*3/2)]."\n";
            if ( $tone > 255 ) { $tone = 255; }
            if ( $tone < 1 )   { $tone = 0; }
            $imggr1->filledRectangle(
                $x * $block,
                ( $h - $y ) * $block,
                $block + $x * $block - 1,
                ( $h - $y ) * $block + $block - 1,
                $imggr1->colorAllocate( $tone, $tone, $tone )
            );

        }
    }

    open( ULOS, ">height.png" );
    binmode ULOS;
    print ULOS $imggr1->png;
    close ULOS;

}
####################################
if ( $command eq 'makevege' ) {

    $xyzin       = $ARGV[1];
    $yellowlimit = $ARGV[2];
    $greenlimit  = $ARGV[3];
    $xmax        = '';
    $ymax        = '';
    $xmin        = '';
    $ymin        = '';
    $hmin        = 999999;
    $hmax        = -999999;
    $counter     = 0;
    open( SISAAN, "<" . $tempfolder . "$xyzin" );

    while ( $rec = <SISAAN> ) {
        $counter++;
        @r = split( / /, $rec );

        #if ( $r[3] == 2 ) {
        if ( $xmin ne '' ) {
            if ( $r[0] < $xmin ) { $xmin = $r[0]; }
        }
        else { $xmin = $r[0]; }
        if ( $xmax ne '' ) {
            if ( $r[0] > $xmax ) { $xmax = $r[0]; }
        }
        else { $xmax = $r[0]; }
        if ( $ymin ne '' ) {
            if ( $r[1] < $ymin ) { $ymin = $r[1]; }
        }
        else { $ymin = $r[1]; }
        if ( $ymax ne '' ) {
            if ( $r[1] > $ymax ) { $ymax = $r[1]; }
        }
        else { $ymax = $r[1]; }

        if ( $r[2] > $hmax ) { $hmax = $r[2]; }
        if ( $r[2] < $hmin ) { $hmin = $r[2]; }

        #}
    }

    close SISAAN;

    if ( $vegethin == 0 && $counter > 70000000 ) {
        $vegethin = floor( $counter / 70000000 ) + 1;
    }

    #print "
    #    $xmax
    #    $ymax
    #    $xmin
    #    $ymin
    #
    #    $hmin
    #    $hmax
    #";
    print "..";
    open( SISAAN, "<" . $tempfolder . "$xyzin" );
    $counter = 0;
    while ( $rec = <SISAAN> ) {
        $counter++;
        if ( $vegethin == 0 || $counter % $vegethin == 0 ) {
            @r = split( / /, $rec );
            $i = 0;
            $j = 0;
            if ( $r[3] == 2 ) {

                #@cols=split(/\#/,$row[ floor($r[0] - $xmin ) ]);
                #$cols[ floor( $r[1] - $ymin ) ] .=              '|' . $r[2];
                #$row[ floor($r[0] - $xmin ) ]=join('#',@cols);

                $row[ floor( $r[0] - $xmin ) ] .=
                  '#' . $r[2] . '|' . ( floor( $r[1] - $ymin ) );
                $rowvege[ floor( $r[0] - $xmin ) ] .=
                  '#' . $r[2] . '|' . ( floor( $r[1] - $ymin ) );
            }
            else {
                if ( $r[0] > $xmin && $r[1] > $ymin ) {
                    $rowvege[ floor( $r[0] - $xmin ) ] .=
                      '#' . $r[2] . '|' . ( floor( $r[1] - $ymin ) );
                }
            }
        }
    }
    close SISAAN;
    undef @d;

    print "..";

    $w = floor( $xmax - $xmin );
    $h = floor( $ymax - $ymin );

    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {
        undef @cols;
        @temp = split( /\#/, $row[$x] );
        foreach $rec (@temp) {
            if ( $rec ne '' ) {
                ( $val, $y ) = split( /\|/, $rec );
                $cols[$y] .= '|' . $val;
            }
        }
        $row[$x] = join( '#', @cols );

    }

    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {
        undef @cols;
        @temp = split( /\#/, $rowvege[$x] );
        foreach $rec (@temp) {
            if ( $rec ne '' ) {
                ( $val, $y ) = split( /\|/, $rec );
                $cols[$y] .= '|' . $val;
            }
        }
        $rowvege[$x] = join( '#', @cols );

    }
    print "..";

####
    undef @cols;
    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {
        @cols = split( /\#/, $row[$x] );
        for ( $y = 0 ; $y < $h + 1 ; $y++ ) {

            if ( $cols[$y] ne '' ) {

                # print "X $cols[$y] X";
                @t   = split( /\|/, $cols[$y] );
                $val = 0;
                $c   = 0;
                foreach $v (@t) {
                    if ( $v ne '' && $val < $v ) {
                        $val = $v;
                        $cols[$y] = 1 * $v;

                    }

                }

            }

        }
        $row[$x] = join( '#', @cols );

    }

    undef @cols;
    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {
        @cols = split( /\#/, $rowvege[$x] );
        for ( $y = 0 ; $y < $h + 1 ; $y++ ) {

            if ( $cols[$y] ne '' ) {

                # print "X $cols[$y] X";
                @t   = split( /\|/, $cols[$y] );
                $val = 0;
                $c   = 0;
                foreach $v (@t) {
                    if ( $v ne '' && $v > $val ) {
                        $cols[$y] = 1 * $v;
                        $val = $v;
                    }

                }
            }

        }
        $rowvege[$x] = join( '#', @cols );

    }
    undef @cols;
###

    print "..";

    for ( $x = 1 ; $x < $w ; $x++ ) {

        @cols0 = split( /\#/, $row[ $x - 1 ] );
        @cols1 = split( /\#/, $row[$x] );
        @cols2 = split( /\#/, $row[ $x + 1 ] );
        for ( $y = 1 ; $y < $h ; $y++ ) {

            if ( $cols1[$y] eq '' ) {
## interpolate here

                $val = 0;
                $c   = 0;

                if (   $cols0[ $y - 1 ] ne ''
                    && $cols2[ $y + 1 ] ne '' )
                {
                    $c = $c + 2;
                    $val += 1 * $cols0[ $y - 1 ] + 1 * $cols2[ $y + 1 ];
                }
                if ( $cols1[ $y - 1 ] ne '' && $cols1[ $y + 1 ] ne '' ) {
                    $c = $c + 2;
                    $val += 1 * $cols1[ $y - 1 ] + 1 * $cols1[ $y + 1 ];
                }
                if ( $cols0[$y] ne '' && $cols2[$y] ne '' ) {
                    $c = $c + 2;
                    $val += 1 * $cols0[$y] + 1 * $cols2[$y];
                }

                ######
                if ( $c > 0 ) {
                    $cols1[$y] = $val / $c;

                }

            }
        }
        $row[$x] = join( '#', @cols1 );

    }
###############################################

    for ( $x = 1 ; $x < $w ; $x++ ) {
        @cols0 = split( /\#/, $row[ $x - 1 ] );
        @cols1 = split( /\#/, $row[$x] );
        @cols2 = split( /\#/, $row[ $x + 1 ] );

        for ( $y = 1 ; $y < $h ; $y++ ) {

            if ( $cols1[$y] eq '' ) {
## interpolate here

                $val = 0;
                $c   = 0;

                for ( $j = -1 ; $j < 2 ; $j++ ) {

                    if ( $cols0[ $y + $j ] ne '' ) {
                        $c++;
                        $val += 1 * $cols0[ $y + $j ];
                    }
                    if ( $cols1[ $y + $j ] ne '' ) {
                        $c++;
                        $val += 1 * $cols1[ $y + $j ];
                    }
                    if ( $cols2[ $y + $j ] ne '' ) {
                        $c++;
                        $val += 1 * $cols2[ $y + $j ];
                    }

                }

                ######
                if ( $c > 0 ) {
                    $cols1[$y] = $val / $c;

                }

            }
        }
        $row[$x] = join( '#', @cols1 );
    }

####################################################
    use GD;

    $img2 = new GD::Image( $w, $h );

    #252,254,252
    #252,254,4
    #4,254,4

    $wh2 = $img2->colorAllocate( 255, 255, 255 );
    $gr2 = $img2->colorAllocate( 4,   254, 4 );
    $ye2 = $img2->colorAllocate( 255, 219, 166 );
    $pur = $img2->colorAllocate( 255, 0,   255 );

    $img2->filledRectangle( 0, 0, $w + 1, $h + 1, $wh );
    print "..";
    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {

        @cols     = split( /\#/, $row[$x] );
        @colsvege = split( /\#/, $rowvege[$x] );

        for ( $y = 0 ; $y < $h + 1 ; $y++ ) {

            #print " $colsvege[$y]- $cols[$y] \n";
            $col = $ye2;
            if ( $colsvege[$y] eq '' ) {
                $col = $pur;

            }
            else {

                if ( $colsvege[$y] - $cols[$y] > $yellowlimit ) {
                    $col = $gr2;
                }
                if ( $colsvege[$y] - $cols[$y] > $greenlimit ) {
                    $col = $wh;
                }

            }
            $img2->setPixel( $x, $h - $y, $col );

        }

    }

    print "..";

    open( ULOS, ">" . $tempfolder . "vege.png" );
    binmode ULOS;
    print ULOS $img2->png;
    close ULOS;

    open( ULOS, ">" . $tempfolder . "vege.pgw" );
    print ULOS "1.0
0.0
0.0
-1.0
$xmin
$ymax
";

    close ULOS;

    print "..... done.";
}
#################################
if ( $command eq 'xyz2contours' ) {

    $cinterval  = $ARGV[1];
    $xyzfilein  = $ARGV[2];
    $xyzfileout = $ARGV[3];
    $dxffile    = $ARGV[4];
    $ground     = $ARGV[5];
    if ( $ground eq 'ground' ) {
        $ground = 1;
    }

    #print "Contours $cinterval\n$xyzfilein -> $xyzfileout -> $dxffile\n";
    print ".";
    $xmax = '';
    $ymax = '';
    $xmin = '';
    $ymin = '';
    $hmin = 999999;
    $hmax = -999999;

    open( SISAAN, "<" . $tempfolder . "$xyzfilein" );

    while ( $rec = <SISAAN> ) {
        @r = split( / /, $rec );
        if ( ( $r[3] == 2 || $r[3] == $water ) || $ground != 1 ) {
            if ( $xmin ne '' ) {
                if ( $r[0] < $xmin ) { $xmin = $r[0]; }
            }
            else { $xmin = $r[0]; }
            if ( $xmax ne '' ) {
                if ( $r[0] > $xmax ) { $xmax = $r[0]; }
            }
            else { $xmax = $r[0]; }
            if ( $ymin ne '' ) {
                if ( $r[1] < $ymin ) { $ymin = $r[1]; }
            }
            else { $ymin = $r[1]; }
            if ( $ymax ne '' ) {
                if ( $r[1] > $ymax ) { $ymax = $r[1]; }
            }
            else { $ymax = $r[1]; }

            if ( $r[2] > $hmax ) { $hmax = $r[2]; }
            if ( $r[2] < $hmin ) { $hmin = $r[2]; }
        }
    }

    close SISAAN;

    #print "
    #    $xmax
    #    $ymax
    #    $xmin
    #    $ymin
    #
    #    $hmin
    #    $hmax
    #";

    $xmin = floor( $xmin / 2 / $scalefactor ) * 2 * $scalefactor;
    $ymin = floor( $ymin / 2 / $scalefactor ) * 2 * $scalefactor;

    open( SISAAN, "<" . $tempfolder . "$xyzfilein" );

    while ( $rec = <SISAAN> ) {

        @r = split( / /, $rec );
        $i = 0;
        $j = 0;
        if ( ( $r[3] == 2 || $r[3] == $water ) || $ground != 1 ) {

            $m[ floor( $r[0] - $xmin ) / 2 / $scalefactor ]
              [ floor( $r[1] - $ymin ) / 2 / $scalefactor ] .= '|' . $r[2];

        }

    }
    close SISAAN;
    $w = floor( $xmax - $xmin ) / 2 / $scalefactor;
    $h = floor( $ymax - $ymin ) / 2 / $scalefactor;
    undef @d;
####
    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {

        for ( $y = 0 ; $y < $h + 1 ; $y++ ) {

            if ( $m[$x][$y] ne '' ) {
                @t   = split( /\|/, $m[$x][$y] );
                $val = 0;
                $c   = 0;
                foreach $v (@t) {
                    if ( $v ne '' ) {
                        $c++;
                        $val += 1 * $v;
                    }

                }
                $m[$x][$y] = $val / $c;

            }

        }

    }

###

    $count  = 0;
    $count2 = 0;
    $row    = 0;
###
    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {

        for ( $y = 0 ; $y < $h + 1 ; $y++ ) {
            if ( $m[$x][$y] eq '' ) {
## interpolate here
                $i1 = $x;
                $i2 = $x;
                $j1 = $y;
                $j2 = $y;

                while ( $m[$i1][$y] eq '' && $i1 > 0 ) {
                    $i1 = $i1 - 1;
                }

                while ( $m[$i2][$y] eq '' && $i2 < $w ) {
                    $i2++;
                }

                while ( $m[$x][$j1] eq '' && $j1 > 0 ) {
                    $j1 = $j1 - 1;
                }

                while ( $m[$x][$j2] eq '' && $j2 < $h ) {
                    $j2++;
                }

                $val1 = '';
                $val2 = '';

                if ( $m[$i1][$y] ne '' && $m[$i2][$y] ne '' ) {
                    $val1 =
                      ( ( $i2 - $x ) * $m[$i1][$y] +
                          ( $x - $i1 ) * $m[$i2][$y] ) /
                      ( $i2 - $i1 );
                }
                if ( $m[$x][$j1] ne '' && $m[$x][$j2] ne '' ) {
                    $val2 =
                      ( ( $j2 - $y ) * $m[$x][$j1] +
                          ( $y - $j1 ) * $m[$x][$j2] ) /
                      ( $j2 - $j1 );
                }

                if ( $val1 ne '' ) {
                    $m[$x][$y] = $val1;
                }
                if ( $val2 ne '' ) {
                    if ( $val1 ne '' ) {
                        $m[$x][$y] = ( $val1 + $val2 ) / 2;
                    }
                    else {
                        $m[$x][$y] = $val2;
                    }
                }
            }
        }

    }

###
    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {

        for ( $y = 0 ; $y < $h + 1 ; $y++ ) {
            if ( $m[$x][$y] eq '' ) {
## interpolate here

                $val = 0;
                $c   = 0;
                for ( $i = -1 ; $i < 2 ; $i++ ) {
                    for ( $j = -1 ; $j < 2 ; $j++ ) {

                        if ( $m[ $x + $i ][ $y + $j ] ne '' ) {
                            $c++;
                            $val += 1 * $m[ $x + $i ][ $y + $j ];
                        }
                    }
                }
                if ( $c > 0 ) {
                    $m[$x][$y] = $val / $c;

                }

            }
        }

    }

##
    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {

        for ( $y = 1 ; $y < $h + 1 ; $y++ ) {
            if ( $m[$x][$y] eq '' ) { $m[$x][$y] = $m[$x][ $y - 1 ]; }
        }
        for ( $y = $h - 1 ; $y > -1 ; $y = $y - 1 ) {
            if ( $m[$x][$y] eq '' ) { $m[$x][$y] = $m[$x][ $y + 1 ]; }
        }

    }

###
    $xmin++;
    $ymin++;

    ##
    for ( $x = 0 ; $x < $w + 1 ; $x++ ) {

        for ( $y = 0 ; $y < $h + 1 ; $y++ ) {
            $ele  = $m[$x][$y];
            $temp = ( floor( ( $ele / $cinterval + 0.5 ) ) * $cinterval );
            if ( abs( $ele - $temp ) < 0.02 ) {
                if ( $$ele - $temp < 0 ) {
                    $ele = $temp - 0.02;
                }
                else {
                    $ele = $temp + 0.02;
                }
                $m[$x][$y] = $ele;
            }
        }
    }

    if ( $xyzfileout ne 'null' ) {
        open( ULOS, ">" . $tempfolder . "$xyzfileout" );
        for ( $x = 0 ; $x < $w + 1 ; $x++ ) {

            for ( $y = 0 ; $y < $h + 1 ; $y++ ) {
                $ele = $m[$x][$y];

                print ULOS ''
                  . ( $x * 2 * $scalefactor + $xmin ) . ' '
                  . ( $y * 2 * $scalefactor + $ymin ) . ' '
                  . $ele . "\n";
            }

        }
        close ULOS;
    }

##
    $v = $cinterval;

    #$l=70;

    #print "$w $h\n";
    open( ULOS2, ">" . $tempfolder . "temp_polylines.txt" );
    close ULOS2;
    $progress    = 0;
    $progressend = ( $hmax - $hmin ) / $v;
    for ( $l = floor( $hmin / $v ) * $v ; $l < $hmax ; $l = $l + $v ) {
        $progress++;
        if ( floor( $progress / $progressend * 18 ) > $progprev ) {
            $progprev = floor( $progress / $progressend * 18 );
            print ".";
        }

        $ob = 0;
        undef %kayra;
        undef @ka;

        #print " $l \n";

        for ( $i = 1 ; $i < $w - 1 ; $i++ ) {

            for ( $j = 2 ; $j < $h - 1 ; $j++ ) {

                #print "$i $j - ";
                $a = 1 * ( $m[$i][$j] );
                $b = 1 * ( $m[$i][ $j + 1 ] );
                $c = 1 * ( $m[ $i + 1 ][$j] );
                $d = 1 * ( $m[ $i + 1 ][ $j + 1 ] );

                if (   $a < $l && $b < $l && $c < $l && $d < $l
                    || $a > $l && $b > $l && $c > $l && $d > $l )
                {

                    # skip
                }
                else {

                    $temp = ( floor( ( $a / $v + 0.5 ) ) * $v );
                    if ( abs( $a - $temp ) < 0.05 ) {
                        if ( $a - $temp < 0 ) {
                            $a = $temp - 0.05;
                        }
                        else {
                            $a = $temp + 0.05;
                        }

                    }
                    $temp = ( floor( ( $b / $v + 0.5 ) ) * $v );
                    if ( abs( $b - $temp ) < 0.05 ) {
                        if ( $b - $temp < 0 ) {
                            $b = $temp - 0.05;
                        }
                        else {
                            $b = $temp + 0.05;
                        }

                    }
                    $temp = ( floor( ( $c / $v + 0.5 ) ) * $v );
                    if ( abs( $c - $temp ) < 0.05 ) {
                        if ( $c - $temp < 0 ) {
                            $c = $temp - 0.05;
                        }
                        else {
                            $c = $temp + 0.05;
                        }

                    }
                    $temp = ( floor( ( $d / $v + 0.5 ) ) * $v );
                    if ( abs( $d - $temp ) < 0.05 ) {
                        if ( $d - $temp < 0 ) {
                            $d = $temp - 0.05;
                        }
                        else {
                            $d = $temp + 0.05;
                        }

                    }

                    if ( $a < $b ) {

                        #$l = floor($a / $v) * $v + $v;
                        #while($l<$b){
                        if ( $l < $b && $l > $a ) {
                            $x1 = $i;
                            $y1 = $j + ( $l - $a ) / ( $b - $a );
                            if ( $l > $c ) {
                                $x2 = $i + ( $b - $l ) / ( $b - $c );
                                $y2 = $j + ( $l - $c ) / ( $b - $c );
                                &kaksataa;
                            }
                            if ( $l < $c ) {
                                $x2 = $i + ( $l - $a ) / ( $c - $a );
                                $y2 = $j;
                                &kaksataa;
                            }
                        }

                        #$l = $l + $v;
                        #}
                    }

                    if ( $b < $a ) {

                        #$l = floor($b / $v) * $v + $v;
                        #while( $l < $a){
                        if ( $l < $a && $l > $b ) {
                            $x1 = $i;
                            $y1 = $j + ( $a - $l ) / ( $a - $b );
                            if ( $l < $c ) {
                                $x2 = $i + ( $l - $b ) / ( $c - $b );
                                $y2 = $j + ( $c - $l ) / ( $c - $b );
                                &kaksataa;
                            }
                            if ( $l > $c ) {
                                $x2 = $i + ( $a - $l ) / ( $a - $c );
                                $y2 = $j;
                                &kaksataa;
                            }
                        }

                        #$l = $l + $v;
                        #}
                    }

                    if ( $a < $c ) {

                        #$l = floor($a / $v) * $v + $v;
                        #while($l < $c){
                        if ( $l < $c && $l > $a ) {
                            $x1 = $i + ( $l - $a ) / ( $c - $a );
                            $y1 = $j;
                            if ( $l > $b ) {
                                $x2 = $i + ( $l - $b ) / ( $c - $b );
                                $y2 = $j + ( $c - $l ) / ( $c - $b );
                                &kaksataa;
                            }
                        }

                        #$l = $l + $v;
                        #}
                    }

                    if ( $a > $c ) {

                        #$l = floor($c / $v) * $v + $v;
                        #while( $l < $a){
                        if ( $l < $a && $l > $c ) {
                            $x1 = $i + ( $a - $l ) / ( $a - $c );
                            $y1 = $j;
                            if ( $b > $l ) {
                                $x2 = $i + ( $b - $l ) / ( $b - $c );
                                $y2 = $j + ( $l - $c ) / ( $b - $c );
                                &kaksataa;
                            }
                        }

                        #$l = $l + $v;
                        #}
                    }

                    # se oli abc-kolmio, seuraavana cdb

                    if ( $c < $d ) {

                        #$l = floor($c / $v) * $v + $v;
                        #while($l < $d){
                        if ( $l < $d && $l > $c ) {
                            $x1 = $i + 1;
                            $y1 = $j + ( $l - $c ) / ( $d - $c );
                            if ( $l < $b ) {
                                $x2 = $i + ( $b - $l ) / ( $b - $c );
                                $y2 = $j + ( $l - $c ) / ( $b - $c );
                                &kaksataa;
                            }
                            if ( $l > $b ) {
                                $x2 = $i + ( $l - $b ) / ( $d - $b );
                                $y2 = $j + 1;
                                &kaksataa;
                            }
                        }

                        #$l = $l + $v;
                        #}
                    }

                    if ( $c > $d ) {

                        #$l = floor($d / $v) * $v + $v;
                        #while($l < $c){
                        if ( $l < $c && $l > $d ) {
                            $x1 = $i + 1;
                            $y1 = $j + ( $c - $l ) / ( $c - $d );
                            if ( $l > $b ) {
                                $x2 = $i + ( $l - $b ) / ( $c - $b );
                                $y2 = $j + ( $c - $l ) / ( $c - $b );
                                &kaksataa;
                            }
                            if ( $l < $b ) {
                                $x2 = $i + ( $b - $l ) / ( $b - $d );
                                $y2 = $j + 1;
                                &kaksataa;
                            }
                        }

                        #$l = $l + $v;
                        #}
                    }

                    if ( $d < $b ) {

                        #$l = floor($d / $v) * $v + $v;
                        #while($l < $b){
                        if ( $l < $b && $l > $d ) {
                            $x1 = $i + ( $b - $l ) / ( $b - $d );
                            $y1 = $j + 1;
                            if ( $l > $c ) {
                                $x2 = $i + ( $b - $l ) / ( $b - $c );
                                $y2 = $j + ( $l - $c ) / ( $b - $c );
                                &kaksataa;
                            }
                        }

                        #$l = $l + $v;
                        #}
                    }

                    if ( $b < $d ) {

                        #$l = floor($b / $v) * $v + $v;
                        #while($l < $d){
                        if ( $l < $d && $l > $b ) {
                            $x1 = $i + ( $l - $b ) / ( $d - $b );
                            $y1 = $j + 1;
                            if ( $c > $l ) {
                                $x2 = $i + ( $l - $b ) / ( $c - $b );
                                $y2 = $j + ( $c - $l ) / ( $c - $b );
                                &kaksataa;
                            }
                        }

                        #$l = $l + $v;
                        #}
                    }

                    #' se siita kolmiosta sitten

                }
            }
        }

        #print "Number of objects ".$ob;

#####################

        #print "\n\nYhdist�\n";
        open( ULOS2, ">>" . $tempfolder . "temp_polylines.txt" );

        for ( $i = 0 ; $i < $ob ; $i++ ) {

            if ( $kayra{ $ka[$i] } ne "" ) {
                ( $x, $y, $n ) = split( /\_/, $ka[$i] );

                print ULOS2 "$x,$y;";
                $tulo = $x . "_" . $y;
                ( $x, $y ) = split( /\_/, $kayra{ $ka[$i] } );

                print ULOS2 "$x,$y;";
                $kayra{ $ka[$i] } = "";
                $loppu            = 0;
                $paa              = $x . "_" . $y;
                if ( $kayra{ $paa . "_1" } eq $tulo ) {
                    $kayra{ $paa . "_1" } = "";
                }
                if ( $kayra{ $paa . "_2" } eq $tulo ) {
                    $kayra{ $paa . "_2" } = "";
                }
                while ( $loppu == 0 ) {

                    if (   $kayra{ $paa . "_1" } ne ""
                        && $kayra{ $paa . "_1" } ne $tulo )
                    {
                        $tulo = $paa;
                        ( $x, $y ) = split( /\_/, $kayra{ $paa . "_1" } );

                        print ULOS2 "$x,$y;";
                        $kayra{ $paa . "_1" } = "";
                        $paa = $x . "_" . $y;
                        if ( $kayra{ $paa . "_1" } eq $tulo ) {
                            $kayra{ $paa . "_1" } = "";
                        }
                        if ( $kayra{ $paa . "_2" } eq $tulo ) {
                            $kayra{ $paa . "_2" } = "";
                        }
                    }
                    else {
                        if (   $kayra{ $paa . "_2" } ne ""
                            && $kayra{ $paa . "_2" } ne $tulo )
                        {
                            $tulo = $paa;
                            ( $x, $y ) = split( /\_/, $kayra{ $paa . "_2" } );

                            print ULOS2 "$x,$y;";
                            $kayra{ $paa . "_2" } = "";
                            $paa = $x . "_" . $y;
                            if ( $kayra{ $paa . "_1" } eq $tulo ) {
                                $kayra{ $paa . "_1" } = "";
                            }
                            if ( $kayra{ $paa . "_2" } eq $tulo ) {
                                $kayra{ $paa . "_2" } = "";
                            }
                        }
                        else {
                            $loppu = 1;
                            print ULOS2 "\n";
                        }
                    }

                }
            }
        }
        close(ULOS2);

    }

##############

    open( SISAAN, "<" . $tempfolder . "temp_polylines.txt" );
    @poly = <SISAAN>;
    close(SISAAN);

    open( ULOS, ">" . $tempfolder . "$dxffile" );
    print ULOS "  0
SECTION
  2
HEADER
  9
\$EXTMIN
 10
$xmin
 20
$ymin
  9
\$EXTMAX
 10
$xmax
 20
$ymax
  0
ENDSEC
  0
SECTION
  2
ENTITIES
  0
";

    foreach $reca (@poly) {
        chomp($reca);
        @data = split( /\;/, $reca );

        $i = 0;
        foreach $rec (@data) {
            $i++;
            if ( $rec ne "" ) {

                if ( $i > 5 && $i < $#data - 5 && $#data > 12 && $i % 2 == 0 ) {
                    $rec = '';
                }
            }
        }

        print ULOS "POLYLINE
 66
1
  8
cont
  0\n";

        foreach $rec (@data) {
            if ( $rec ne "" ) {

                ( $x, $y ) = split( /\,/, $rec );
                $y = $scalefactor * 2 * $y + $ymin;
                $x = $scalefactor * 2 * $x + $xmin;
                print ULOS "VERTEX
  8
cont
 10
$x
 20
$y
  0\n";
            }
        }
        print ULOS "SEQEND
  0\n";
    }
    print ULOS "ENDSEC\n";
    print ULOS "  0\n";
    print ULOS "EOF\n";
    close(ULOS);

    print ". done.";
}

#############################################
if ( $command eq 'vege' ) {
    print ".";
    $lightgreenlimit = $ARGV[1];
    $darkgreenlimit  = $ARGV[2];

    $gfactor = $ARGV[3];
    $yfactor = $ARGV[4];
    $wfactor = $ARGV[5];

    $yellowfactor = $ARGV[6];

    if ( $yellowfactor eq '' ) {
        $yellowfactor = 0.75;
    }

    if ( $lightgreenlimit eq '' ) {
        $lightgreenlimit = 0.30;
    }
    if ( $darkgreenlimit eq '' ) {
        $darkgreenlimit = 0.45;
    }
    if ( $gfactor eq '' ) {
        $gfactor = 1;
    }
    if ( $yfactor eq '' ) {
        $yfactor = -0.25;
    }

    if ( $wfactor eq '' ) {
        $wfactor = 0;
    }
    $lightgreenlimit = $lightgreenlimit * 100;
    $darkgreenlimit  = $darkgreenlimit * 100;
    $yellowfactor    = $yellowfactor * 25;

    $img = newFromPng GD::Image( $tempfolder . 'vege.png' );
    ( $w, $h ) = $img->getBounds();

    $img2 = new GD::Image( $w, $h );

    $wh2 = $img2->colorAllocate( 255, 255, 255 );
    $gr2 = $img2->colorAllocate( 30,  255, 30 );
    $ye2 = $img2->colorAllocate( 255, 219, 166 );

    $img2->filledRectangle( 0, 0, $w + 1, $h + 1, $wh );

    $img3 = new GD::Image( $w, $h );

    $wh3 = $img3->colorAllocate( 255, 255, 255 );
    $gr3 = $img3->colorAllocate( 0,   230, 0 );
    $ye3 = $img3->colorAllocate( 255, 219, 166 );

    $img3->filledRectangle( 0, 0, $w + 1, $h + 1, $wh );

    $img4 = new GD::Image( $w, $h );

    $wh4 = $img4->colorAllocate( 255, 255, 255 );
    $gr4 = $img4->colorAllocate( 160, 255, 160 );
    $ye4 = $img4->colorAllocate( 255, 219, 166 );
    $img4->filledRectangle( 0, 0, $w + 1, $h + 1, $wh4 );

    $img5 = new GD::Image( $w, $h );

    $wh5 = $img5->colorAllocate( 255, 255, 255 );
    $gr5 = $img5->colorAllocate( 160, 255, 160 );
    $ye5 = $img5->colorAllocate( 255, 219, 166 );
    $img5->filledRectangle( 0, 0, $w + 1, $h + 1, $wh5 );

    $c = 0;
    for ( $x = 10 ; $x < $w - 10 ; $x = $x + 4 ) {
        if ( ( ( $x - 10 ) / 4 ) % ( floor( $w / 4 / 9 ) ) == 0 ) { print "."; }

        # print "$x / $w \n";
        for ( $y = 10 ; $y < $h - 10 ; $y = $y + 4 ) {
            $green  = 0;
            $yellow = 0;
            $white  = 0;
            for ( $i = $x - 5 ; $i < $x + 6 ; $i++ ) {
                for ( $j = $y - 5 ; $j < $y + 6 ; $j++ ) {

                    ( $r, $g, $b ) = $img->rgb( $img->getPixel( $i, $j ) );

                    if ( $r == 4 ) {
                        $green++;
                    }

                    if ( $r == 255 && $b == 166 ) {    #255, 219, 166
                        $yellow++;
                    }
                    if ( $r == 255 && $g == 255 && $b == 255 ) {
                        $white++;
                    }

                    #print "$r,$g,$b\n";
                    #$c++;
                    #if($c> 3000){exit;}

                }
            }

            #$white = 100 - $yellow - $green;

            $greenindex =
              ( $gfactor * $green + $yfactor * $yellow + $wfactor * $white ) *
              100 /
              ( $green + $yellow + $white + 0.0001 );

            if ( $greenindex > $darkgreenlimit ) {

                #$img2->filledRectangle($x-4,$y-4,$x+4,$y+4,$gr);
                $img2->filledArc( $x, $y, 13, 13, 0, 360, $gr2 );
            }
            if ( $greenindex > $lightgreenlimit ) {

                #$img2->filledRectangle($x-4,$y-4,$x+4,$y+4,$gr);
                $img4->filledArc( $x, $y, 13, 13, 0, 360, $gr2 );
            }

        }
    }

    # yellow

    $c = 0;
    for ( $x = 10 ; $x < $w - 10 ; $x = $x + 1 ) {
        if ( $x % ( floor( $w / 9 ) ) == 0 ) { print "."; }

        #print "$x / $w \n";
        for ( $y = 10 ; $y < $h - 10 ; $y = $y + 1 ) {

            $yellow = 0;
            $purple = 0;
            $count  = 0;
            for ( $i = $x - 2 ; $i < $x + 3 ; $i++ ) {
                for ( $j = $y - 2 ; $j < $y + 3 ; $j++ ) {

                    ( $r, $g, $b ) = $img->rgb( $img->getPixel( $i, $j ) );

                    if ( $r == 255 && $b == 166 ) {
                        $yellow++;
                    }
                    if ( $r == 255 && $g == 0 && $b == 255 ) {
                        $purple++;
                    }
                    $count++;

                }
            }
            if ( $count - $purple > 0 ) {
                if ( $yellow / ( $count - $purple ) > $yellowfactor / $count ) {

                    $img3->filledRectangle( $x - 1, $y - 1, $x + 1, $y + 1,
                        $ye3 );
                    $img5->filledRectangle( $x - 1, $y - 1, $x + 1, $y + 1,
                        $ye3 );

                    #$img3->filledArc( $x, $y, 3, 3, 0, 360, $ye3 );
                    #$img5->filledArc( $x, $y, 3, 3, 0, 360, $ye3 );
                }
            }
        }
    }

## output

    $img2->transparent($wh2);
    $img4->copy( $img2, 0, 0, 0, 0, $w, $h );

    #open(ULOS, ">".$tempfolder."vege_green.png");
    #binmode ULOS;
    #print ULOS $img4->png;
    #close ULOS;

    #open(ULOS, ">".$tempfolder."vege_yellow.png");
    #binmode ULOS;
    #print ULOS $img3->png;
    #close ULOS;

    $img3->transparent($wh3);
    $img5->transparent($wh3);

    $img4->copy( $img5, -1, -1, 0, 0, $w, $h );
    $img4->copy( $img5, -1, 0,  0, 0, $w, $h );
    $img4->copy( $img5, -1, 1,  0, 0, $w, $h );

    $img4->copy( $img5, 0, -1, 0, 0, $w, $h );
    $img4->copy( $img5, 0, 0,  0, 0, $w, $h );
    $img4->copy( $img5, 0, 1,  0, 0, $w, $h );

    $img4->copy( $img5, 1, -1, 0, 0, $w, $h );
    $img4->copy( $img5, 1, 0,  0, 0, $w, $h );
    $img4->copy( $img5, 1, 1,  0, 0, $w, $h );

    $img4->copy( $img3, 0, 0, 0, 0, $w, $h );

    open( ULOS, ">" . $tempfolder . "vegetation.png" );
    binmode ULOS;
    print ULOS $img4->png;
    close ULOS;

    open( SISAAN, "<" . $tempfolder . "vege.pgw" );
    @d = <SISAAN>;
    close SISAAN;

    open( ULOS, ">" . $tempfolder . "vegetation.tfw" );
    print ULOS @d;
    close ULOS;
    open( ULOS, ">" . $tempfolder . "vegetation.pgw" );
    print ULOS @d;
    close ULOS;
    print ". done.";
}    # vege

###########################################

if ( $command eq 'cliffgeneralize' ) {

    print "..";

    $steepnesslimit = $ARGV[1];
    if ( $steepnesslimit == 0 ) {
        $steepnesslimit = 1 * $psteepness;
    }

    open( SISAAN, "<" . $tempfolder . "xyz2.xyz" );
    @d = <SISAAN>;
    close SISAAN;

    @r1     = split( / /, $d[0] );
    @r2     = split( / /, $d[1] );
    $size   = $r2[1] - $r1[1];
    $xstart = $r1[0];
    $ystart = $r1[1];

    $xmax = 0;
    $ymax = 0;
    foreach $rec (@d) {
        @r = split( / /, $rec );

        $xyz[ floor( ( $r[0] - $xstart ) / $size ) ]
          [ floor( ( $r[1] - $ystart ) / $size ) ] = 1 * $r[2];
        if (   floor( ( $r[0] - $xstart ) / $size ) < 0
            || floor( ( $r[1] - $ystart ) / $size ) < 0 )
        {
            print "error";
            exit;
        }

        if ( $xmax < floor( ( $r[0] - $xstart ) / $size ) ) {
            $xmax = floor( ( $r[0] - $xstart ) / $size );
        }
        if ( $ymax < floor( ( $r[1] - $ystart ) / $size ) ) {
            $ymax = floor( ( $r[1] - $ystart ) / $size );
        }
        $c++;
    }
    print "..";

    # print "steepness\n";
    for ( $i = 3 ; $i < $xmax - 4 ; $i++ ) {
        for ( $j = 3 ; $j < $ymax - 4 ; $j++ ) {
            $low  = 999999999;
            $high = -999999999;
            for ( $ii = $i - 3 ; $ii < $i + 4 ; $ii++ ) {
                for ( $jj = $j - 3 ; $jj < $j + 4 ; $jj++ ) {
                    if ( $xyz[$ii][$jj] < $low )  { $low  = $xyz[$ii][$jj]; }
                    if ( $xyz[$ii][$jj] > $high ) { $high = $xyz[$ii][$jj]; }

                }
            }
            $steepness[$i][$j] = $high - $low;
        }
    }
    print "..";
    $/ = 'POLYLINE';

    open( SISAAN, "<" . $tempfolder . "c1.dxf" );
    open( ULOS,   ">" . $tempfolder . "c1g.dxf" );
    $j = 0;
    while ( $rec = <SISAAN> ) {

        if ( $j == 0 ) {
            print ULOS $rec;    # dxf header
        }

        $temp1 = '';
        $temp2 = '';
        $j++;

        #print "$j / " . $#d . "\n";
        if ( $j > 1 ) {

            @r = split( /VERTEX/, $rec );

            if ( $j == 2 ) {
                $apu = $r[1];
                @val = split( /\n/, $apu );
                $i   = 0;
                foreach $v (@val) {
                    chomp($v);
                    if ( $v eq ' 10' ) {
                        $xline = $i + 1;
                    }
                    if ( $v eq ' 20' ) {
                        $yline = $i + 1;
                    }
                    $i++;
                }
            }

            $rec = join( 'VERTEX', @r );
            $rec =~ s/VERTEXVERTEX/VERTEX/g;

            @val         = split( /\n/, $r[1] );
            @val2        = split( /\n/, $r[$#r] );
            $val[$xline] = ( $val[$xline] + $val2[$xline] ) / 2;
            $val[$yline] = ( $val[$yline] + $val2[$yline] ) / 2;

            if (
                (
                    $steepnesslimit >
                    $steepness[ floor( ( $val[$xline] - $xstart ) / $size ) ]
                    [ floor( ( $val[$yline] - $ystart ) / $size ) ]
                )
                || $j > $#d
              )
            {    ## prnt out if steep enough or last cliff with dxf footer

                print ULOS "" . $rec;

            }

        }
    }

    close ULOS;
    close SISAAN;

####

    open( SISAAN, "<" . $tempfolder . "c2.dxf" );
    open( ULOS,   ">" . $tempfolder . "c2g.dxf" );
    $j = 0;
    while ( $rec = <SISAAN> ) {

        if ( $j == 0 ) {
            print ULOS $rec;    # dxf header
        }

        $temp1 = '';
        $temp2 = '';
        $j++;

        #print "$j / " . $#d . "\n";
        if ( $j > 1 ) {
            @r = split( /VERTEX/, $rec );
            if ( $j == 2 ) {
                $apu = $r[1];
                @val = split( /\n/, $apu );
                $i   = 0;
                foreach $v (@val) {
                    chomp($v);
                    if ( $v eq ' 10' ) {
                        $xline = $i + 1;
                    }
                    if ( $v eq ' 20' ) {
                        $yline = $i + 1;
                    }
                    $i++;
                }
            }

            $rec = join( 'VERTEX', @r );
            $rec =~ s/VERTEXVERTEX/VERTEX/g;

            @val         = split( /\n/, $r[1] );
            @val2        = split( /\n/, $r[$#r] );
            $val[$xline] = ( $val[$xline] + $val2[$xline] ) / 2;
            $val[$yline] = ( $val[$yline] + $val2[$yline] ) / 2;

            print ULOS "" . $rec;

        }
    }

    close ULOS;
    close SISAAN;

####

    open( SISAAN, "<" . $tempfolder . "c3.dxf" );
    open( ULOS,   ">" . $tempfolder . "c3g.dxf" );
    $j = 0;
    while ( $rec = <SISAAN> ) {

        if ( $j == 0 ) {
            print ULOS $rec;    # dxf header
        }

        $temp1 = '';
        $temp2 = '';
        $j++;

        #print "$j / " . $#d . "\n";
        if ( $j > 1 ) {
            @r = split( /VERTEX/, $rec );

            if ( $j == 2 ) {
                $apu = $r[1];
                @val = split( /\n/, $apu );
                $i   = 0;
                foreach $v (@val) {
                    chomp($v);
                    if ( $v eq ' 10' ) {
                        $xline = $i + 1;
                    }
                    if ( $v eq ' 20' ) {
                        $yline = $i + 1;
                    }
                    $i++;
                }
            }

            $rec = join( 'VERTEX', @r );
            $rec =~ s/VERTEXVERTEX/VERTEX/g;

            @val         = split( /\n/, $r[1] );
            @val2        = split( /\n/, $r[$#r] );
            $val[$xline] = ( $val[$xline] + $val2[$xline] ) / 2;
            $val[$yline] = ( $val[$yline] + $val2[$yline] ) / 2;

            print ULOS "" . $rec;

        }
    }

    close ULOS;
    close SISAAN;

    print ".............. done.";
}    # cliffgeneralize

####################################################

if ( $command eq 'xyzfixer' ) {

    $interval = 2;    # contour interval

    use POSIX;
    open( SISAAN, "<" . $tempfolder . "xyz.xyz" );
    @d = <SISAAN>;
    close SISAAN;

    foreach $rec (@d) {
        @r    = split( / /, $rec );
        $temp = ( floor( ( $r[2] / $interval + 0.5 ) ) * $interval );
        if ( abs( $r[2] - $temp ) < 0.05 ) {
            if ( $r[2] - $temp < 0 ) {
                $r[2] = $temp - 0.05;
            }
            else {
                $r[2] = $temp + 0.05;
            }

        }

        $rec = join( ' ', @r );
    }

    open( ULOS, ">" . $tempfolder . "xyz2.xyz" );
    print ULOS @d;
    close ULOS;

############ for 0.3 m contours #######
    $interval = 0.3 * $scalefactor;    # contour interval

    use POSIX;
    open( SISAAN, "<" . $tempfolder . "xyz.xyz" );
    @d = <SISAAN>;
    close SISAAN;

    foreach $rec (@d) {
        @r    = split( / /, $rec );
        $temp = ( floor( ( $r[2] / $interval + 0.5 ) ) * $interval );
        if ( abs( $r[2] - $temp ) < 0.01 ) {
            if ( $r[2] - $temp < 0 ) {
                $r[2] = $temp - 0.01;
            }
            else {
                $r[2] = $temp + 0.01;
            }

        }

        $rec = join( ' ', @r );
    }

    open( ULOS, ">" . $tempfolder . "xyz_03.xyz" );
    print ULOS @d;
    close ULOS;
    print ".................... done.";
}    # xyzfixer

##############

if ( $command eq 'knolldetector' ) {

    print ".";

    $interval = 0.3 * $scalefactor;

    open( SISAAN, "<" . $tempfolder . "xyz_03.xyz" );
    @d = <SISAAN>;
    close SISAAN;

    @r1     = split( / /, $d[0] );
    @r2     = split( / /, $d[1] );
    $size   = $r2[1] - $r1[1];
    $xstart = $r1[0];
    $ystart = $r1[1];

    $xmax = 0;
    $ymax = 0;
    foreach $rec (@d) {
        @r = split( / /, $rec );

        $xyz[ floor( ( $r[0] - $xstart ) / $size ) ]
          [ floor( ( $r[1] - $ystart ) / $size ) ] = 1 * $r[2];
        if (   floor( ( $r[0] - $xstart ) / $size ) < 0
            || floor( ( $r[1] - $ystart ) / $size ) < 0 )
        {
            print "error";
            exit;
        }

        if ( $xmax < floor( ( $r[0] - $xstart ) / $size ) ) {
            $xmax = floor( ( $r[0] - $xstart ) / $size );
        }
        if ( $ymax < floor( ( $r[1] - $ystart ) / $size ) ) {
            $ymax = floor( ( $r[1] - $ystart ) / $size );
        }
        $c++;
    }

    #print " $c points \n";

    # print "reading dxf \n";
    $/ = 'POLYLINE';
    open( SISAAN, "<" . $tempfolder . "contours03.dxf" );
    @d = <SISAAN>;
    close SISAAN;

    open( ULOS, ">" . $tempfolder . "detected.dxf" );

    print ULOS "  0
SECTION
  2
HEADER
  9
\$EXTMIN
 10
$xmin
 20
$ymin
  9
\$EXTMAX
 10
$xmax
 20
$ymax
  0
ENDSEC
  0
SECTION
  2
ENTITIES
  0
";

    #$d=join('',@d);
    #print "done1\n";
    #@d=split(/POLYLINE/,$d);
    #print "done2\n";
    $d = '';
    $j = 0;
    foreach $rec (@d) {
        $temp1 = '';
        $temp2 = '';
        $j++;
        if ( $j > 1 ) {
            @r = split( /VERTEX/, $rec );

########
            $apu = $r[1];
            @val = split( /\n/, $apu );
            $i   = 0;
            foreach $v (@val) {
                chomp($v);
                if ( $v eq ' 10' ) {
                    $xline = $i + 1;
                }
                if ( $v eq ' 20' ) {
                    $yline = $i + 1;
                }
                $i++;
            }
##########

            if ( $#r < 200 ) {
                $i = 0;

                #print "$j\n";
                foreach $v (@r) {
                    $i++;
                    if ( $i > 1 ) {
                        @val = split( /\n/, $v );
                        $temp1 .= ( 1 * $val[$xline] ) . '|';
                        $temp2 .= ( 1 * $val[$yline] ) . '|';

                    }
                }

                #print "#".$temp;
                chop($temp1);
                chop($temp2);
                @x = split( /\|/, $temp1 );
                @y = split( /\|/, $temp2 );

                $head = $x[0] . 'x' . $y[0];
                $tail = $x[$#x] . 'x' . $y[$#x];

                $elex[ $j - 1 ] = $temp1;
                $eley[ $j - 1 ] = $temp2;
                $head[ $j - 1 ] = $head;
                $tail[ $j - 1 ] = $tail;

                if ( $head1{$head} eq '' ) {
                    $head1{$head} = $j - 1;
                }
                else {
                    $head2{$head} = $j - 1;
                }

                if ( $head1{$tail} eq '' ) {
                    $head1{$tail} = $j - 1;
                }
                else {
                    $head2{$tail} = $j - 1;
                }

            }
        }
    }
    print ".";
    for ( $l = 0 ; $l < $j + 1 ; $l++ ) {

        #print "$l\n";
        if ( $elex[$l] ne '' ) {

            $loppu = 0;

            while ( $loppu == 0 ) {

                # loytyyk� vastinparia.

                if (   $head1{ $head[$l] } ne ''
                    && $head1{ $head[$l] } ne $l
                    && $elex[ $head1{ $head[$l] } ] ne '' )
                {
                    $tojoin = $head1{ $head[$l] };
                }
                else {
                    if (   $head2{ $head[$l] } ne ''
                        && $head2{ $head[$l] } ne $l
                        && $elex[ $head2{ $head[$l] } ] ne '' )
                    {
                        $tojoin = $head2{ $head[$l] };
                    }
                    else {
                        if (   $head2{ $tail[$l] } ne ''
                            && $head2{ $tail[$l] } ne $l
                            && $elex[ $head2{ $tail[$l] } ] ne '' )
                        {
                            $tojoin = $head2{ $tail[$l] };
                        }
                        else {
                            if (   $head1{ $tail[$l] } ne ''
                                && $head1{ $tail[$l] } ne $l
                                && $elex[ $head1{ $tail[$l] } ] ne '' )
                            {
                                $tojoin = $head1{ $tail[$l] };
                            }
                            else {

                                $loppu = 1;
                            }

                        }

                    }

                }

                if ( $loppu == 0 ) {

                    # print "join $l + $tojoin \n";

                    $joined++;
## joinataan
## mik� p�� joinataan

                    if ( $tail[$l] eq $head[$tojoin] ) {
                        $head2{ $tail[$l] } = '';
                        $head1{ $tail[$l] } = '';
                        $elex[$l] .= '|' . $elex[$tojoin];
                        $eley[$l] .= '|' . $eley[$tojoin];
                        $tail[$l]      = $tail[$tojoin];
                        $elex[$tojoin] = '';
                    }
                    else {

                        if ( $tail[$l] eq $tail[$tojoin] ) {
                            $head2{ $tail[$l] } = '';
                            $head1{ $tail[$l] } = '';
                            $elex[$l] .= '|'
                              . join( '|',
                                reverse( split( /\|/, $elex[$tojoin] ) ) );
                            $eley[$l] .= '|'
                              . join( '|',
                                reverse( split( /\|/, $eley[$tojoin] ) ) );
                            $tail[$l]      = $head[$tojoin];
                            $elex[$tojoin] = '';
                        }
                        else {

                            if ( $head[$l] eq $tail[$tojoin] ) {
                                $head2{ $head[$l] } = '';
                                $head1{ $head[$l] } = '';
                                $elex[$l] = $elex[$tojoin] . '|' . $elex[$l];
                                $eley[$l] = $eley[$tojoin] . '|' . $eley[$l];
                                $head[$l] = $head[$tojoin];
                                $elex[$tojoin] = '';
                            }
                            else {

                                if ( $head[$l] eq $head[$tojoin] ) {
                                    $head2{ $head[$l] } = '';
                                    $head1{ $head[$l] } = '';
                                    $elex[$l]           = join(
                                        '|',
                                        reverse(
                                            split( /\|/, $elex[$tojoin] )
                                        )
                                      )
                                      . '|'
                                      . $elex[$l];
                                    $eley[$l] = join(
                                        '|',
                                        reverse(
                                            split( /\|/, $eley[$tojoin] )
                                        )
                                      )
                                      . '|'
                                      . $eley[$l];
                                    $head[$l]      = $tail[$tojoin];
                                    $elex[$tojoin] = '';
                                }

                            }

                        }
                    }
                }

            }

        }

    }

################

    for ( $l = 0 ; $l < $j + 1 ; $l++ ) {
        if ( $l % ( floor( $j / 6 ) ) == 0 ) { print "."; }
        $skip = 0;

        if ( $elex[$l] ne '' ) {

            @x = split( /\|/, $elex[$l] );
            @y = split( /\|/, $eley[$l] );

            if ( $#x > 120 ) {
                $skip     = 1;
                $elex[$l] = '';
                $eley[$l] = '';

            }
            if ( $#x < 9 ) {

                # is if long enough
                $p    = 0;
                $dist = 0;
                while ( $p < $#x ) {
                    $dist =
                      $dist +
                      sqrt(
                        ( $x[$p] - $x[ $p + 1 ] ) * ( $x[$p] - $x[ $p + 1 ] ) +
                          ( $y[$p] - $y[ $p + 1 ] ) * ( $y[$p] - $y[ $p + 1 ] )
                      );
                    $p++;
                }

                if ( $dist < 5 || $#x < 3 ) {
                    $skip     = 1;
                    $elex[$l] = '';
                    $eley[$l] = '';

                }
            }
            if ( $x[0] != $x[$#x] || $y[0] != $y[$#y] ) {
                $skip     = 1;
                $elex[$l] = '';
                $eley[$l] = '';

            }

            if (   $skip == 0
                && $#x < 121
                && $x[0] == $x[$#x]
                && $y[0] == $y[$#y] )
            {
                $x[ $#x + 1 ] = $x[0];
                $y[ $#y + 1 ] = $y[0];

                # onko kuoppa
                # k�yr�n tason laskenta

                $m = floor( $#x / 3 ) - 1;
                if ( $m < 0 ) { $m = 0; }
                while ( $m < $#x + 1 ) {

                    # lasketaan k�yr�n taso
                    if ( ( $x[$m] - $xstart ) / $size ==
                        floor( ( $x[$m] - $xstart ) / $size ) )
                    {
                        $h1 =
                          $xyz[ floor( ( $x[$m] - $xstart ) / $size ) ]
                          [ floor( ( $y[$m] - $ystart ) / $size ) ];
                        $h2 =
                          $xyz[ floor( ( $x[$m] - $xstart ) / $size ) ]
                          [ floor( ( $y[$m] - $ystart ) / $size ) + 1 ];
                        $h = (
                            $h1 * (
                                floor( ( $y[$m] - $ystart ) / $size ) + 1 -
                                  ( ( $y[$m] - $ystart ) / $size )
                            ) + $h2 * (
                                ( ( $y[$m] - $ystart ) / $size ) -
                                  floor( ( $y[$m] - $ystart ) / $size )
                            )
                        );
                        $h = ( floor( $h / $interval + 0.5 ) * $interval );

                        #print ''
                        #  . ( floor( $h / $interval + 0.5 ) * $interval )
                        #  . "\n";
                        $m = $#x + 1;
                    }
                    if ( $m < $#x - 2
                        && ( $y[$m] - $ystart ) / $size ==
                        floor( ( $y[$m] - $ystart ) / $size )
                        && ( $x[$m] - $xstart ) / $size !=
                        floor( ( $x[$m] - $xstart ) / $size ) )
                    {
                        $h1 =
                          $xyz[ floor( ( $x[$m] - $xstart ) / $size ) ]
                          [ floor( ( $y[$m] - $ystart ) / $size ) ];
                        $h2 =
                          $xyz[ floor( ( $x[$m] - $xstart ) / $size ) + 1 ]
                          [ floor( ( $y[$m] - $ystart ) / $size ) ];
                        $h = (
                            $h1 * (
                                floor( ( $x[$m] - $xstart ) / $size ) + 1 -
                                  ( ( $x[$m] - $xstart ) / $size )
                            ) + $h2 * (
                                ( ( $x[$m] - $xstart ) / $size ) -
                                  floor( ( $x[$m] - $xstart ) / $size )
                            )
                        );
                        $h = ( floor( $h / $interval + 0.5 ) * $interval );

                        #print ''
                        #  . ( floor( $h / $interval + 0.5 ) * $interval )
                        #  . "\n";
                        #$m = $#x + 1;

                    }

                    $m++;
                }
                $elevation{ 1 * $l } = $h;

                $m = floor( $#x / 3 ) - 1;
                if ( $m < 0 ) { $m = 0; }
                $xave = $x[$m];
                $yave = $y[$m];
                while ( $m < $#x + 1 ) {

                    if ( $m < $#x - 2
                        && ( $y[$m] - $ystart ) / $size ==
                        floor( ( $y[$m] - $ystart ) / $size )
                        && ( $x[$m] - $xstart ) / $size !=
                        floor( ( $x[$m] - $xstart ) / $size ) )
                    {
                        $xave =
                          floor( ( $x[$m] - $xstart ) / $size ) * $size +
                          $xstart;
                        $yave = floor( $y[$m] );
                        $m    = $#x + 1;
                    }
                    $m++;
                }
                $h_center =
                  $xyz[ floor( ( $xave - $xstart ) / $size ) ]
                  [ floor( ( $yave - $ystart ) / $size ) ];

                $hit = 0;

                $xtest = floor( ( $xave - $xstart ) / $size ) * $size +
                  $xstart + 0.000000001;

                $ytest = floor( ( $yave - $ystart ) / $size ) * $size +
                  $ystart + 0.000000001;

                $n = -1;
                while ( $n < $#x ) {
                    $n++;

                    ( $x1, $y1 ) = ( $x[$n], $y[$n] );

                    if ( $n > 0 ) {
                        if (
                            (
                                   ( ( $y0 <= $ytest ) and ( $ytest < $y1 ) )
                                or ( ( $y1 <= $ytest ) and ( $ytest < $y0 ) )
                            )
                            and ( $xtest < ( $x1 - $x0 ) *
                                ( $ytest - $y0 ) /
                                ( $y1 - $y0 ) + $x0 )
                          )
                        {
                            $hit++;
                        }
                    }
                    $x0 = $x1;
                    $y0 = $y1;

                }

                if ( $hit % 2 == 1 ) {

                    #print "IN";
                }
                else {

                    #print "OUT $n $hit $#x $xtest $ytest - $y0 $x0 $y1 $x1 \n";
                }

                # hylk�� kuopat

                if (   ( $h_center < $h && $hit % 2 == 1 )
                    || ( $h_center > $h && $hit % 2 != 1 ) )
                {

                    #print " SKIP $h $h_center\n";
                    $skip     = 1;
                    $elex[$l] = '';
                    $eley[$l] = '';
                }

            }

        }
        if ( $skip == 1 ) {
            $elex[$l] = '';
            $eley[$l] = '';
        }
    }

#######
    $lukema = 0;
    $temp   = '';
    for ( $l = 0 ; $l < $j + 1 ; $l++ ) {

        if ( $elex[$l] ne '' ) {

            @x = split( /\|/, $elex[$l] );
            @y = split( /\|/, $eley[$l] );
            if ( $x[0] == $x[$#x] && $y[0] == $y[$#x] ) {
                $lukema++;
                $temp .= '' . $l . ',' . $#x . ',' . $x[0] . ',' . $y[0] . "\n";
            }
            else {
                $elex[$l] = '';
            }
        }
    }
    @heads = split( /\n/, $temp );

    #print "\nlukema $lukema \n";
##############

##
    #print "\ntops only\n...";
    $temp   = '';
    $lukema = 0;
    for ( $l = 0 ; $l < $j + 1 ; $l++ ) {
        if ( $l % ( floor( $j / 6 ) ) == 0 ) { print "."; }

        #print "$l / $j\n";
        $skip = 0;
        if ( $elex[$l] ne '' ) {

            # print "$l / $j\n";
            @x            = split( /\|/, $elex[$l] );
            @y            = split( /\|/, $eley[$l] );
            $x[ $#x + 1 ] = $x[0];
            $y[ $#y + 1 ] = $y[0];
            $minx         = 999999999;
            $maxx         = -999999999;
            $miny         = 999999999;
            $maxy         = -999999999;

            for ( $k = 0 ; $k < $#x + 1 ; $k++ ) {

                if ( $x[$k] > $maxx ) { $maxx = $x[$k]; }
                if ( $x[$k] < $minx ) { $minx = $x[$k]; }
                if ( $y[$k] > $maxy ) { $maxy = $y[$k]; }
                if ( $y[$k] < $miny ) { $miny = $y[$k]; }

            }
            $bb{$l} = "$minx,$maxx,$miny,$maxy";

            foreach $head (@heads) {
                ( $id, $count, $xtest, $ytest ) = split( /\,/, $head );

                if (   $skip == 0
                    && $elevation{$id} > $elevation{$l}
                    && $id ne $l
                    && $xtest < $maxx
                    && $xtest > $minx
                    && $ytest < $maxy
                    && $ytest > $miny )
                {

                    $hit = 0;

                    $n = -1;

                    #print "($id,$count,$xtest,$ytest)\n";
                    while ( $n < $#x ) {
                        $n++;

                        ( $x1, $y1 ) = ( $x[$n], $y[$n] );

                        if ( $n > 0 ) {
                            if (
                                (
                                    ( ( $y0 <= $ytest ) and ( $ytest < $y1 ) )
                                    or
                                    ( ( $y1 <= $ytest ) and ( $ytest < $y0 ) )
                                )
                                and ( $xtest < ( $x1 - $x0 ) *
                                    ( $ytest - $y0 ) /
                                    ( $y1 - $y0 ) + $x0 )
                              )
                            {
                                $hit++;
                            }
                        }
                        $x0 = $x1;
                        $y0 = $y1;

                    }

                    if ( $hit % 2 == 1 ) {
                        $skip = 1;
                    }
                }    # if count smaller than
            }

            if ( $skip == 0 ) {
                $temp .= '' . $l . ',' . $x[0] . ',' . $y[0] . "\n";
                $lukema++;

            }

        }

    }

    @tops = split( /\n/, $temp );

    #####################

    #print "\nTops: $lukema\n";
###########
    #print "Detecting over 0.3m knolls...\n";
    $temp   = '';
    $lukema = 0;
    for ( $l = 0 ; $l < $j + 1 ; $l++ ) {
        if ( $l % ( floor( $j / 6 ) ) == 0 ) { print "."; }

        #print "$l / $j\n";
        $skip = 1;
        if ( $elex[$l] ne '' ) {

            #print "$l / $j\n";
            @x            = split( /\|/, $elex[$l] );
            @y            = split( /\|/, $eley[$l] );
            $x[ $#x + 1 ] = $x[0];
            $y[ $#y + 1 ] = $y[0];

            #     $minx = 99999999;
            #     $maxx = -99999999;
            #    $miny = 99999999;
            #   $maxy = -99900009;

            #            for ( $k = 0 ; $k < $#x + 1 ; $k++ ) {
            #
            #               if ( $x[$k] > $maxx ) { $maxx = $x[$k]; }
            #              if ( $x[$k] < $minx ) { $minx = $x[$k]; }
            #             if ( $y[$k] > $maxy ) { $maxy = $y[$k]; }
            #            if ( $y[$k] < $miny ) { $miny = $y[$k]; }
            #            }

            ( $minx, $maxx, $miny, $maxy ) = split( /\,/, $bb{$l} );

            foreach $head (@tops) {
                ( $id, $xtest, $ytest ) = split( /\,/, $head );

                if (

                    $elevation{ 1 * $l } < $elevation{ 1 * $id } - 0.1
                    && $elevation{ 1 * $l } > $elevation{ 1 * $id } - 4.6

                    && $skip == 1
                    && $xtest < $maxx
                    && $xtest > $minx
                    && $ytest < $maxy
                    && $ytest > $miny
                  )
                {

                    $hit = 0;

                    $n = -1;

                    #print "($id,$count,$xtest,$ytest)\n";
                    while ( $n < $#x ) {
                        $n++;

                        ( $x1, $y1 ) = ( $x[$n], $y[$n] );

                        if ( $n > 0 ) {
                            if (
                                (
                                    ( ( $y0 <= $ytest ) and ( $ytest < $y1 ) )
                                    or
                                    ( ( $y1 <= $ytest ) and ( $ytest < $y0 ) )
                                )
                                and ( $xtest < ( $x1 - $x0 ) *
                                    ( $ytest - $y0 ) /
                                    ( $y1 - $y0 ) + $x0 )
                              )
                            {
                                $hit++;
                            }
                        }
                        $x0 = $x1;
                        $y0 = $y1;

                    }

                    if ( $hit % 2 == 1 ) {
                        $skip  = 0;
                        $topid = $id;
                    }
                }    # if elvation
            }

            if ( $skip == 0 ) {

                #$lukema++;

                $temp .=
                  '' . $l . ',' . $x[0] . ',' . $y[0] . ',' . $topid . "\n";
            }
            else {
                $elex[$l] = '';

            }

        }

    }

###

    @candidates = split( /\n/, $temp );

    ##########################
    foreach $head (@candidates) {
        ( $id, $xtest, $ytest, $topid ) = split( /\,/, $head );

        $test =
          ( floor( ( ( $elevation{$id} ) / 2.5 + 1 ) ) * 2.5 ) -
          $elevation{$id};

        if ( $best{$topid} eq '' ) {

            $best{$topid} = $id;
            $mov{ $best{$topid} } = $test;

        }
        else {

            if ( $mov{ $best{$topid} } < 1.75
                && abs( $elevation{$topid} - $elevation{ $best{$topid} } - 0.6 )
                < 0.2 )
            {
## we have about perfect already
            }
            else {
                if ( $mov{ $best{$topid} } > $test ) {
                    $best{$topid} = $id;
                    $mov{ $best{$topid} } = $test;
                }
            }
        }
    }

##
    @candidates = split( /\n/, $temp );
    $temp       = '';
    foreach $head (@candidates) {
        ( $id, $xtest, $ytest, $topid ) = split( /\,/, $head );
        @x = split( /\|/, $elex[$id] );
        if (
            $best{$topid} == $id
            && (
                $#x < 12
                || (
                    $elevation{$topid} > $elevation{$id} + 0.45
                    || ( $elevation{$id} -
                        2.5 * floor( ( $elevation{$id} ) / 2.5 ) > 0.45 )
                )
            )
          )
        {
            $lukema++;
            $temp .=
              '' . $id . ',' . $xtest . ',' . $ytest . ',' . $topid . "\n";

        }
        else {
            $elex[$id] = '';
        }
    }
##
    @candidates = split( /\n/, $temp );

    # print "\nCandidates: $lukema\n";

    $pin = '';

    $lukema = 0;
    for ( $l = 0 ; $l < $j + 1 ; $l++ ) {

        #print "$l / $j\n";
        $skip = 0;
        if ( $elex[$l] ne '' ) {

            @x            = split( /\|/, $elex[$l] );
            @y            = split( /\|/, $eley[$l] );
            $x[ $#x + 1 ] = $x[0];
            $y[ $#y + 1 ] = $y[0];

            ( $minx, $maxx, $miny, $maxy ) = split( /\,/, $bb{$l} );

            foreach $head (@candidates) {
                ( $id, $xtest, $ytest, $topid ) = split( /\,/, $head );

                if (   $id ne $l
                    && $skip == 0
                    && $xtest < $maxx
                    && $xtest > $minx
                    && $ytest < $maxy
                    && $ytest > $miny )
                {

                    $hit = 0;

                    $n = -1;

                    #print "($id,$count,$xtest,$ytest)\n";
                    while ( $n < $#x ) {
                        $n++;

                        ( $x1, $y1 ) = ( $x[$n], $y[$n] );

                        if ( $n > 0 ) {
                            if (
                                (
                                    ( ( $y0 <= $ytest ) and ( $ytest < $y1 ) )
                                    or
                                    ( ( $y1 <= $ytest ) and ( $ytest < $y0 ) )
                                )
                                and ( $xtest < ( $x1 - $x0 ) *
                                    ( $ytest - $y0 ) /
                                    ( $y1 - $y0 ) + $x0 )
                              )
                            {
                                $hit++;
                            }
                        }
                        $x0 = $x1;
                        $y0 = $y1;

                    }

                    if ( $hit % 2 == 1 ) {
                        $skip = 1;
                    }
                }    # if id==l
            }

            if ( $skip == 0 ) {
                $lukema++;

                # output

                print ULOS "POLYLINE
 66
1
  8
1010
  0
";

                #print "$#x\n";

                $xave = 0;
                $yave = 0;
                for ( $k = 0 ; $k < $#x + 1 ; $k++ ) {
                    $xave += $x[$k];
                    $yave += $y[$k];
                }
                $xave = $xave / ( $#x + 1 );
                $yave = $yave / ( $#x + 1 );

                $pin .= ''
                  . ( 1 * $x[0] ) . ','
                  . ( 1 * $y[0] ) . ','
                  . $elevation{$l} . ','
                  . $xave . ','
                  . $yave . ','
                  . $elevation{$topid} . ','
                  . join( ' ', @x ) . ','
                  . join( ' ', @y ) . "\n";
                for ( $k = 0 ; $k < $#x + 1 ; $k++ ) {
                    print ULOS "VERTEX
  8
1010
 10
" . ( 1 * $x[$k] ) . "
 20
" . ( 1 * $y[$k] ) . "
  0
";

                }
                print ULOS "SEQEND
  0
";
            }
            else {
                $elex[$l] = '';
            }

        }

    }

##

####

    print ULOS "ENDSEC
  0
EOF
";

    #print "\nlukema $lukema \n";

    open( PINS, ">" . $tempfolder . "pins.txt" );
    print PINS $pin;
    close(PINS);
    print ". done.";
}

#######################################

if ( $command eq 'xyzknolls' ) {

    $interval = 2.5 * $scalefactor;    # contour interval

    open( SISAAN, "<" . $tempfolder . "pins.txt" );
    @pins = <SISAAN>;
    close SISAAN;

    open( SISAAN, "<" . $tempfolder . "xyz_03.xyz" );
    @d = <SISAAN>;
    close SISAAN;

    @r1     = split( / /, $d[0] );
    @r2     = split( / /, $d[1] );
    $size   = $r2[1] - $r1[1];
    $xstart = $r1[0];
    $ystart = $r1[1];

    $xmax = 0;
    $ymax = 0;

    foreach $rec (@d) {
        @r = split( / /, $rec );

        $xyz[ floor( ( $r[0] - $xstart ) / $size ) ]
          [ floor( ( $r[1] - $ystart ) / $size ) ] = 1 * $r[2];

        if ( $xmax < floor( ( $r[0] - $xstart ) / $size ) ) {
            $xmax = floor( ( $r[0] - $xstart ) / $size );
        }
        if ( $ymax < floor( ( $r[1] - $ystart ) / $size ) ) {
            $ymax = floor( ( $r[1] - $ystart ) / $size );
        }
        $c++;
    }

    #print " $c points \n";

## smooth by steepness
    #print "smoothing flat areas...\n";
    for ( $i = 0 ; $i < $xmax + 1 ; $i++ ) {
        for ( $j = 0 ; $j < $ymax + 1 ; $j++ ) {
            $xyz2[$i][$j] = $xyz[$i][$j];
        }
    }

    for ( $i = 2 ; $i < $xmax - 1 ; $i++ ) {
        for ( $j = 2 ; $j < $ymax - 1 ; $j++ ) {
            $low   = 99999999;
            $high  = -99999999;
            $val   = 0;
            $count = 0;
            for ( $ii = $i - 2 ; $ii < $i + 3 ; $ii++ ) {
                for ( $jj = $j - 2 ; $jj < $j + 3 ; $jj++ ) {
                    if ( $xyz[$ii][$jj] < $low )  { $low  = $xyz[$ii][$jj]; }
                    if ( $xyz[$ii][$jj] > $high ) { $high = $xyz[$ii][$jj]; }
                    $count++;
                    $val += $xyz[$ii][$jj];
                }
            }
            $steepness = $high - $low;

            if ( $steepness < 1.25 ) {
                $xyz2[$i][$j] =
                  ( 1.25 - $steepness ) *
                  ( $val - $low - $high ) /
                  ( $count - 2 ) /
                  1.25 + ($steepness) *
                  $xyz2[$i][$j] / 1.25;
            }

        }
    }

############
    $l = 0;
    foreach $rec (@pins) {
        $l++;
        $min = 9999;
        ( $x, $y, $ele, $xx, $yy, $ele2 ) = split( /\,/, $rec );
        $xx = floor( ( $xx - $xstart ) / $size );
        $yy = floor( ( $yy - $ystart ) / $size );
        $k  = 0;
        foreach $rec2 (@pins) {
            $k++;
            ( $x, $y, $ele, $xx2, $yy2, $ele2 ) = split( /\,/, $rec2 );
            $xx2 = floor( ( $xx2 - $xstart ) / $size );
            $yy2 = floor( ( $yy2 - $ystart ) / $size );
            if ( $k != $l ) {
                $dis = abs( $xx2 - $xx );
                if ( abs( $yy2 - $yy ) > $dis ) {
                    $dis = abs( $yy2 - $yy );
                }
                if ( $dis < $min ) { $min = $dis; }
            }
        }
        $dist{$l} = $min;
    }

##
    $l = 0;
    foreach $rec (@pins) {
        $l++;

        # print "$l / $#pins\n";

        ( $x, $y, $ele, $xx, $yy, $ele2, $xlist, $ylist ) = split( /\,/, $rec );
        $x = floor( ( $x - $xstart ) / $size );
        $y = floor( ( $y - $ystart ) / $size );

        @x            = split( / /, $xlist );
        @y            = split( / /, $ylist );
        $x[ $#x + 1 ] = $x[0];
        $y[ $#y + 1 ] = $y[0];

        $elenew = ( floor( ( ( $ele - 0.09 ) / $interval + 1 ) ) * $interval );

        $move  = ( $elenew - $ele ) + 0.15;
        $move2 = $move * 0.4;
        if ( $move > 0.66 * $interval ) { $move2 = $move * 0.6 }
        if ( $move < 0.25 * $interval ) { $move2 = 0; $move = $move + 0.3 }
        $move = $move + 0.5;
        if ( $ele2 + $move >
            ( floor( ( ( $ele - 0.09 ) / $interval + 2 ) ) * $interval ) )
        {
            $move = $move - 0.4;
        }

        if ( ( $elenew - $ele ) > 1.50 * $scalefactor )
        { #resize low, close to lower contour elevation knolls smaller to make it look less violent.
             #print "($#x)";
            if ( $#x > 20 ) {
                for ( $k = 0 ; $k < $#x + 1 ; $k++ ) {
                    $x[$k] = $xx + ( $x[$k] - $xx ) * 0.8;
                    $y[$k] = $yy + ( $y[$k] - $yy ) * 0.8;
                }
            }

        }

        undef %touched;

        $minx = 99999;
        $maxx = -9999;
        $miny = 99999;
        $maxy = -9999;

        for ( $k = 0 ; $k < $#x + 1 ; $k++ ) {
            $x[$k] = floor( ( $x[$k] - $xstart ) / $size + 0.5 );
            $y[$k] = floor( ( $y[$k] - $ystart ) / $size + 0.5 );
            if ( $x[$k] > $maxx ) { $maxx = $x[$k]; }
            if ( $x[$k] < $minx ) { $minx = $x[$k]; }
            if ( $y[$k] > $maxy ) { $maxy = $y[$k]; }
            if ( $y[$k] < $miny ) { $miny = $y[$k]; }

        }

        $xx = floor( ( $xx - $xstart ) / $size );
        $yy = floor( ( $yy - $ystart ) / $size );

        for ( $ii = $minx ; $ii < $maxx + 1 ; $ii++ ) {
            for ( $jj = $miny ; $jj < $maxy + 1 ; $jj++ ) {

                $hit   = 0;
                $xtest = $ii;
                $ytest = $jj;

                $n = -1;

                while ( $n < $#x ) {
                    $n++;

                    ( $x1, $y1 ) = ( $x[$n], $y[$n] );

                    if ( $n > 0 ) {
                        if (
                            (
                                   ( ( $y0 <= $ytest ) and ( $ytest < $y1 ) )
                                or ( ( $y1 <= $ytest ) and ( $ytest < $y0 ) )
                            )
                            and ( $xtest < ( $x1 - $x0 ) *
                                ( $ytest - $y0 ) /
                                ( $y1 - $y0 ) + $x0 )
                          )
                        {
                            $hit++;
                        }
                    }
                    $x0 = $x1;
                    $y0 = $y1;

                }

                if ( $hit % 2 == 1 ) {

                    # in
                    #print "+";
                    $xyz2[$ii][$jj] = $xyz2[$ii][$jj] + $move;
                    $touched{ '' . $ii . '_' . $jj } = 1;
                }
                else {

                    # out
                    # print "-";
                }

            }

            #print "\n";
        }
####

        $sivu = ( $dist{$l} * 0.8 - 1 );
        if ( $sivu < 1 )  { $sivu = 1; }
        if ( $sivu > 12 ) { $sivu = 12; }

        #print "sivu $sivu\n";
        for ( $ii = $xx - $sivu ; $ii < $xx + $sivu + 1 ; $ii++ ) {
            for ( $jj = $yy - $sivu ; $jj < $yy + $sivu + 1 ; $jj++ ) {
                $tmp =
                  ( $sivu - abs( $xx - $ii ) ) /
                  $sivu *
                  ( $sivu - abs( $yy - $jj ) ) /
                  $sivu * $move2;

                if ( $ii > 0 && $ii < $xmax + 1 && $jj > 0 && $jj < $ymax + 1 )
                {
                    if ( $touched{ '' . $ii . '_' . $jj } != 1 ) {
                        $xyz2[$ii][$jj] = $xyz2[$ii][$jj] + $tmp;
                    }
                }
            }
        }
##
    }    # foreach

## interval fix

    foreach $rec (@d) {
        @r = split( / /, $rec );
        $r[2] =
          $xyz2[ floor( ( $r[0] - $xstart ) / $size ) ]
          [ floor( ( $r[1] - $ystart ) / $size ) ];
        $temp = ( floor( ( $r[2] / $interval + 0.5 ) ) * $interval );

        if ( abs( $temp - $r[2] ) < 0.02 ) {
            if ( $r[2] - $temp < 0 ) {
                $r[2] = $temp - 0.02;
            }
            else {
                $r[2] = $temp + 0.02;
            }

        }

        $rec = join( ' ', @r );
    }

    open( ULOS, ">" . $tempfolder . "xyz_knolls.xyz" );
    print ULOS join( "\n", @d );
    close ULOS;
    print ".................... done.";
}

##########################

if ( $command eq 'smoothjoin' ) {

    #print "grid\n";

    $interval = 2.5 * $scalefactor;

    open( SISAAN, "<" . $tempfolder . "xyz_knolls.xyz" );
    @d = <SISAAN>;
    close SISAAN;

    @r1     = split( / /, $d[0] );
    @r2     = split( / /, $d[1] );
    $size   = $r2[1] - $r1[1];
    $xstart = $r1[0];
    $ystart = $r1[1];

    $xmax = 0;
    $ymax = 0;
    foreach $rec (@d) {
        @r = split( / /, $rec );

        $xyz[ floor( ( $r[0] - $xstart ) / $size ) ]
          [ floor( ( $r[1] - $ystart ) / $size ) ] = 1 * $r[2];
        if (   floor( ( $r[0] - $xstart ) / $size ) < 0
            || floor( ( $r[1] - $ystart ) / $size ) < 0 )
        {
            print "error";
            exit;
        }

        if ( $xmax < floor( ( $r[0] - $xstart ) / $size ) ) {
            $xmax = floor( ( $r[0] - $xstart ) / $size );
        }
        if ( $ymax < floor( ( $r[1] - $ystart ) / $size ) ) {
            $ymax = floor( ( $r[1] - $ystart ) / $size );
        }
        $c++;
    }

    #print " $c points \n";

    #print "steepness\n";
    for ( $i = 1 ; $i < $xmax ; $i++ ) {
        for ( $j = 1 ; $j < $ymax ; $j++ ) {
            $low  = 99999999;
            $high = -9999999;
            for ( $ii = $i - 1 ; $ii < $i + 2 ; $ii++ ) {
                for ( $jj = $j - 1 ; $jj < $j + 2 ; $jj++ ) {
                    if ( $xyz[$ii][$jj] < $low )  { $low  = $xyz[$ii][$jj]; }
                    if ( $xyz[$ii][$jj] > $high ) { $high = $xyz[$ii][$jj]; }

                }
            }
            $steepness[$i][$j] = $high - $low;
        }
    }

    #print "reading dxf \n";

    $/ = 'POLYLINE';
    open( SISAAN, "<" . $tempfolder . "out.dxf" );
    @d = <SISAAN>;
    close SISAAN;

    ($dheader) = split( /ENDSEC\n/, $d[0] );
    ( $del, $dheader ) = split( /HEADER/, $dheader );
    $dheader = 'HEADER' . $dheader . "ENDSEC";

    open( KNOLL,    ">" . $tempfolder . "knollheads.txt" );
    open( ULOS,     ">" . $tempfolder . "out2.dxf" );
    open( DOTKNOLL, ">" . $tempfolder . "dotknolls.txt" );
    open( DEPR,     ">" . $tempfolder . "depressions.txt" );

    print ULOS "  0
SECTION
  2
$dheader
  0
SECTION
  2
ENTITIES
  0
";

    #    @d = split( /POLYLINE/, $d );

    $j = 0;
    foreach $rec (@d) {
        $temp1 = '';
        $temp2 = '';
        $j++;
        if ( $j > 1 ) {
            @r = split( /VERTEX/, $rec );

########
            $apu = $r[1];
            @val = split( /\n/, $apu );
            $i   = 0;
            foreach $v (@val) {
                chomp($v);
                if ( $v eq ' 10' ) {
                    $xline = $i + 1;
                }
                if ( $v eq ' 20' ) {
                    $yline = $i + 1;
                }
                $i++;
            }
##########

            $i = 0;

            #print "$j\n";
            foreach $v (@r) {
                $i++;
                if ( $i > 1 ) {
                    @val = split( /\n/, $v );
                    $temp1 .= ( 1 * $val[$xline] ) . '|';
                    $temp2 .= ( 1 * $val[$yline] ) . '|';

                }
            }

            #print "#".$temp;
            chop($temp1);
            chop($temp2);
            @x = split( /\|/, $temp1 );
            @y = split( /\|/, $temp2 );

            $head = $x[0] . 'x' . $y[0];
            $tail = $x[$#x] . 'x' . $y[$#x];

            $elex[ $j - 1 ] = $temp1;
            $eley[ $j - 1 ] = $temp2;
            $head[ $j - 1 ] = $head;
            $tail[ $j - 1 ] = $tail;

            if ( $head1{$head} eq '' ) {
                $head1{$head} = $j - 1;
            }
            else {
                $head2{$head} = $j - 1;
            }

            if ( $head1{$tail} eq '' ) {
                $head1{$tail} = $j - 1;
            }
            else {
                $head2{$tail} = $j - 1;
            }

        }
    }

    # join
## smooth

    #print "smooth\n";
    for ( $l = 0 ; $l < $j + 1 ; $l++ ) {

        #print "$l\n";
        if ( $elex[$l] ne '' ) {

            $loppu = 0;

            while ( $loppu == 0 ) {

                # loytyyka vastinparia.

                if (   $head1{ $head[$l] } ne ''
                    && $head1{ $head[$l] } ne $l
                    && $elex[ $head1{ $head[$l] } ] ne '' )
                {
                    $tojoin = $head1{ $head[$l] };
                }
                else {
                    if (   $head2{ $head[$l] } ne ''
                        && $head2{ $head[$l] } ne $l
                        && $elex[ $head2{ $head[$l] } ] ne '' )
                    {
                        $tojoin = $head2{ $head[$l] };
                    }
                    else {
                        if (   $head2{ $tail[$l] } ne ''
                            && $head2{ $tail[$l] } ne $l
                            && $elex[ $head2{ $tail[$l] } ] ne '' )
                        {
                            $tojoin = $head2{ $tail[$l] };
                        }
                        else {
                            if (   $head1{ $tail[$l] } ne ''
                                && $head1{ $tail[$l] } ne $l
                                && $elex[ $head1{ $tail[$l] } ] ne '' )
                            {
                                $tojoin = $head1{ $tail[$l] };
                            }
                            else {

                                $loppu = 1;
                            }

                        }

                    }

                }

                if ( $loppu == 0 ) {

                    # print "join $l + $tojoin \n";

                    $joined++;
## joinataan
## mika paa joinataan

                    if ( $tail[$l] eq $head[$tojoin] ) {
                        $head2{ $tail[$l] } = '';
                        $head1{ $tail[$l] } = '';
                        $elex[$l] .= '|' . $elex[$tojoin];
                        $eley[$l] .= '|' . $eley[$tojoin];
                        $tail[$l]      = $tail[$tojoin];
                        $elex[$tojoin] = '';
                    }
                    else {

                        if ( $tail[$l] eq $tail[$tojoin] ) {
                            $head2{ $tail[$l] } = '';
                            $head1{ $tail[$l] } = '';
                            $elex[$l] .= '|'
                              . join( '|',
                                reverse( split( /\|/, $elex[$tojoin] ) ) );
                            $eley[$l] .= '|'
                              . join( '|',
                                reverse( split( /\|/, $eley[$tojoin] ) ) );
                            $tail[$l]      = $head[$tojoin];
                            $elex[$tojoin] = '';
                        }
                        else {

                            if ( $head[$l] eq $tail[$tojoin] ) {
                                $head2{ $head[$l] } = '';
                                $head1{ $head[$l] } = '';
                                $elex[$l] = $elex[$tojoin] . '|' . $elex[$l];
                                $eley[$l] = $eley[$tojoin] . '|' . $eley[$l];
                                $head[$l] = $head[$tojoin];
                                $elex[$tojoin] = '';
                            }
                            else {

                                if ( $head[$l] eq $head[$tojoin] ) {
                                    $head2{ $head[$l] } = '';
                                    $head1{ $head[$l] } = '';
                                    $elex[$l]           = join(
                                        '|',
                                        reverse(
                                            split( /\|/, $elex[$tojoin] )
                                        )
                                      )
                                      . '|'
                                      . $elex[$l];
                                    $eley[$l] = join(
                                        '|',
                                        reverse(
                                            split( /\|/, $eley[$tojoin] )
                                        )
                                      )
                                      . '|'
                                      . $eley[$l];
                                    $head[$l]      = $tail[$tojoin];
                                    $elex[$tojoin] = '';
                                }

                            }

                        }
                    }
                }

            }

        }

    }

    for ( $l = 0 ; $l < $j + 1 ; $l++ ) {

        if ( $elex[$l] ne '' ) {

            #print "#$l#\n";

            @x = split( /\|/, $elex[$l] );
            @y = split( /\|/, $eley[$l] );

            #if(abs($x[0]- 372892.88)<5 && abs($y[0]-6689703.11)<5){

            #print "-- $x[0] $y[0] $l ---";
            #exit;

            #}
            $skip       = 0;
            $depression = 1;

            if ( $#x < 2 ) {
                $elex[$l] = '';
                $skip = 1;

            }

            if ( $skip == 0 ) {

                # kayran tason laskenta

                $m = floor( $#x / 3 ) - 1;
                if ( $m < 0 ) { $m = 0; }
                while ( $m < $#x + 1 ) {

                    # lasketaan kayran taso
                    if ( ( $x[$m] - $xstart ) / $size ==
                        floor( ( $x[$m] - $xstart ) / $size ) )
                    {
                        $h1 =
                          $xyz[ floor( ( $x[$m] - $xstart ) / $size ) ]
                          [ floor( ( $y[$m] - $ystart ) / $size ) ];
                        $h2 =
                          $xyz[ floor( ( $x[$m] - $xstart ) / $size ) ]
                          [ floor( ( $y[$m] - $ystart ) / $size ) + 1 ];
                        $h = (
                            $h1 * (
                                floor( ( $y[$m] - $ystart ) / $size ) + 1 -
                                  ( ( $y[$m] - $ystart ) / $size )
                            ) + $h2 * (
                                ( ( $y[$m] - $ystart ) / $size ) -
                                  floor( ( $y[$m] - $ystart ) / $size )
                            )
                        );

                        $h = ( floor( $h / $interval + 0.5 ) * $interval );
                        $m = $#x + 1;
                    }
                    if ( $m < $#x - 2
                        && ( $y[$m] - $ystart ) / $size ==
                        floor( ( $y[$m] - $ystart ) / $size )
                        && ( $x[$m] - $xstart ) / $size !=
                        floor( ( $x[$m] - $xstart ) / $size ) )
                    {
                        $h1 =
                          $xyz[ floor( ( $x[$m] - $xstart ) / $size ) ]
                          [ floor( ( $y[$m] - $ystart ) / $size ) ];
                        $h2 =
                          $xyz[ floor( ( $x[$m] - $xstart ) / $size ) + 1 ]
                          [ floor( ( $y[$m] - $ystart ) / $size ) ];
                        $h = (
                            $h1 * (
                                floor( ( $x[$m] - $xstart ) / $size ) + 1 -
                                  ( ( $x[$m] - $xstart ) / $size )
                            ) + $h2 * (
                                ( ( $x[$m] - $xstart ) / $size ) -
                                  floor( ( $x[$m] - $xstart ) / $size )
                            )
                        );
                        $h = ( floor( $h / $interval + 0.5 ) * $interval );

                        $m = $#x + 1;

                        #  . ( floor( $h / $interval + 0.5 ) * $interval )
                        #  . "\n";
                        $m = $#x + 1;

                    }

                    $m++;
                }
            }

            if (   $skip == 0
                && $#x < 180
                && $x[0] == $x[$#x]
                && $y[0] == $y[$#y] )
            {

                $m = floor( $#x / 3 ) - 1;
                if ( $m < 0 ) { $m = 0; }
                $xave = $x[$m];
                $yave = $y[$m];
                while ( $m < $#x + 1 ) {

                    if (
                        $m < $#x - 2
                        && ( $y[$m] - $ystart ) / $size ==
                        floor( ( $y[$m] - $ystart ) / $size )
                        && abs(
                            ( $x[$m] - $xstart ) / $size -
                              floor( ( $x[$m] - $xstart ) / $size )
                        ) > 0.5
                        && floor( ( $y[$m] - $ystart ) / $size ) !=
                        floor( ( $y[0] - $ystart ) / $size )
                        && floor( ( $x[$m] - $xstart ) / $size ) !=
                        floor( ( $x[0] - $xstart ) / $size )
                      )
                    {

                        $xave =
                          floor( ( $x[$m] - $xstart ) / $size ) * $size +
                          $xstart;
                        $yave = floor( $y[$m] );
                        $m    = $#x + 1;
                    }
                    $m++;
                }
                $foox = floor( ( $xave - $xstart ) / $size );
                $fooy = floor( ( $yave - $ystart ) / $size );

                $h_center =
                  $xyz[ floor( ( $xave - $xstart ) / $size ) ]
                  [ floor( ( $yave - $ystart ) / $size ) ];

                $hit = 0;

                $xtest = floor( ( $xave - $xstart ) / $size ) * $size + $xstart;

                $ytest = floor( ( $yave - $ystart ) / $size ) * $size + $ystart;

                $n = -1;

                while ( $n < $#x ) {    #+1
                    $n++;

                    ( $x1, $y1 ) = ( $x[$n], $y[$n] );

                    if ( $n > 0 ) {
                        if (
                            (
                                   ( ( $y0 <= $ytest ) and ( $ytest < $y1 ) )
                                or ( ( $y1 <= $ytest ) and ( $ytest < $y0 ) )
                            )
                            and ( $xtest < ( $x1 - $x0 ) *
                                ( $ytest - $y0 ) /
                                ( $y1 - $y0 ) + $x0 )
                          )
                        {
                            $hit++;
                        }
                    }
                    $x0 = $x1;
                    $y0 = $y1;

                }

                # if ( $hit % 2 == 1 ) {

                #}
                #else {

                #}

                # hylkaa kuopat?
                $depression = 1;
                if (   ( $h_center < $h && $hit % 2 == 1 )
                    || ( $h_center > $h && $hit % 2 != 1 ) )
                {

                    #print " SKIP $h $h_center\n";

                    #suppaversio# $skip=1;
                    $depression = -1;
                    print DEPR "$x[0],$y[0]";
                    for ( $k = 1 ; $k < $#x + 1 ; $k++ ) {
                        print DEPR "|$x[$k],$y[$k]";
                    }
                    print DEPR "\n";
                }

                if ( $skip == 0 ) {    # is knoll distinct enoug
                    $steepcounter = 0;
                    $minele       = 9999999;
                    $maxele       = -9999999;
                    for ( $k = 0 ; $k < $#x ; $k++ ) {
                        if (
                            $minele > $h - 0.5 * $steepness[
                            floor( ( $x[$k] - $xstart ) / $size + 0.5 )
                            ][ floor( ( $y[$k] - $ystart ) / $size + 0.5 ) ]
                          )
                        {
                            $minele =
                              $h -
                              0.5 * $steepness[ floor(
                                  ( $x[$k] - $xstart ) / $size + 0.5 ) ]
                              [ floor( ( $y[$k] - $ystart ) / $size + 0.5 ) ];
                        }

                        if (
                            $maxele < $h + 0.5 * $steepness[
                            floor( ( $x[$k] - $xstart ) / $size + 0.5 )
                            ][ floor( ( $y[$k] - $ystart ) / $size + 0.5 ) ]
                          )
                        {
                            $maxele =
                              $h +
                              0.5 * $steepness[ floor(
                                  ( $x[$k] - $xstart ) / $size + 0.5 ) ]
                              [ floor( ( $y[$k] - $ystart ) / $size + 0.5 ) ];
                        }

                        if (
                            $steepness[
                            floor( ( $x[$k] - $xstart ) / $size + 0.5 )
                            ][ floor( ( $y[$k] - $ystart ) / $size + 0.5 ) ] >
                            1
                          )
                        {
                            $steepcounter++;
                        }
                        else {

                            # $steepcounter = $steepcounter - 1;
                        }
                    }

                    if ( $steepcounter < 0.4 * $#x && $x < 40 )
                    {    # is most of the contour really steep
                        if ( $depression * $h_center - 1.9 < $minele )
                        {    # is center a lot above lowest point around?

                            if ( $maxele - 0.45 * $scalefactor * $inidotknolls <
                                $minele )
                            {    # is max-min how high?
                                $skip = 1;
                            }
                            if (   $#x < 32
                                && $maxele -
                                0.75 * $scalefactor * $inidotknolls < $minele )
                            {    # is max-min how high?
                                $skip = 1;
                            }
                            if (   $#x < 18
                                && $maxele -
                                0.9 * $scalefactor * $inidotknolls < $minele )
                            {    # is max-min how high?
                                $skip = 1;
                            }
                        }

                    }
                    if ( $steepcounter < $inidotknolls * $#x && $#x < 14 ) {
                        $skip = 1;
                    }
                }
            }

            if ( $#x < 4 ) {
                $skip = 1;

            }

            if ( $skip == 0 && $#x < 14 ) {    # dot knoll

                $xave = 0;
                $yave = 0;
                for ( $k = 0 ; $k < $#x ; $k++ ) {
                    $xave += $x[$k];
                    $yave += $y[$k];
                }

                $xave = $xave / $#x;
                $yave = $yave / $#x;

                print DOTKNOLL "$depression $xave $yave\n";

                #print ULOS "POINT
                #  8
                #dotknoll
                # 10
                #$xave
                # 20
                #$yave
                # 50
                #0
                #  0\n";

                #print KNOLL "$x[0] $y[$0]\n";

                $skip = 1;
            }

            # skip
            if ( $skip == 0 ) {
## not skipped, lets save first coordinate pair for later form line knoll PIP analysis
                #if($#x<400){
                print KNOLL "$x[0] $y[$0]\n";

                #}

                # adaptive generalizarion

                if ( $#x > 100 ) {    # let's not do this to smallest knolls
                    $dist = 0;

                    $newx = '' . $x[0];
                    $newy = '' . $y[0];
                    $xpre = $x[0];
                    $ypre = $y[0];
                    for ( $k = 1 ; $k < $#x ; $k++ ) {
                        if (
                            $steepness[
                            floor( ( $x[$k] - $xstart ) / $size + 0.5 )
                            ][ floor( ( $y[$k] - $ystart ) / $size + 0.5 ) ] <
                            0.5
                          )
                        {    # && $k>4 && $k<$#x-4
                            if (
                                sqrt(
                                    ( $xpre - $x[$k] ) * ( $xpre - $x[$k] ) +
                                      ( $ypre - $y[$k] ) * ( $ypre - $y[$k] )
                                ) < 4
                              )
                            {

                                # skip
                            }
                            else {
                                $newx .= ',' . $x[$k];
                                $newy .= ',' . $y[$k];

#$dist=$dist+sqrt(($xpre-$x[$k])*($xpre-$x[$k]) + ($ypre-$y[$k])*($ypre-$y[$k]));

                                $xpre = $x[$k];
                                $ypre = $y[$k];
                            }

                        }
                        else {
                            $newx .= ',' . $x[$k];
                            $newy .= ',' . $y[$k];

#$dist=$dist+sqrt(($xpre-$x[$k])*($xpre-$x[$k]) + ($ypre-$y[$k])*($ypre-$y[$k]));

                            $xpre = $x[$k];
                            $ypre = $y[$k];
                        }
                    }

                    $newx .= ',' . $x[$#x];
                    $newy .= ',' . $y[$#x];

                    @x = split( /\,/, $newx );
                    @y = split( /\,/, $newy );
                }

## smoothing

                for ( $k = 2 ; $k < $#x - 2 ; $k++ ) {
                    $dx[$k] =
                      ( $x[ $k - 2 ] +
                          $x[ $k - 1 ] +
                          $x[$k] +
                          $x[ $k + 1 ] +
                          $x[ $k + 2 ] +
                          $x[ $k + 3 ] ) / 6;
                    $dy[$k] =
                      ( $y[ $k - 2 ] +
                          $y[ $k - 1 ] +
                          $y[$k] +
                          $y[ $k + 1 ] +
                          $y[ $k + 2 ] +
                          $y[ $k + 3 ] ) / 6;
                }

                for ( $k = 1 ; $k < $#x ; $k++ ) {
                    $xa[$k] =
                      ( $x[ $k - 1 ] +
                          $x[$k] / ( 0.01 + $smoothing ) +
                          $x[ $k + 1 ] ) /
                      ( 2 + 1 / ( 0.01 + $smoothing ) );
                    $ya[$k] =
                      ( $y[ $k - 1 ] +
                          $y[$k] / ( 0.01 + $smoothing ) +
                          $y[ $k + 1 ] ) /
                      ( 2 + 1 / ( 0.01 + $smoothing ) );
                }
                if ( $x[0] == $x[$#x] && $y[0] == $y[$#x] ) {
                    $xa[0] =
                      ( $x[1] + $x[0] / ( 0.01 + $smoothing ) + $x[ $#x - 1 ] )
                      / ( 2 + 1 / ( 0.01 + $smoothing ) );
                    $ya[0] =
                      ( $y[1] + $y[0] / ( 0.01 + $smoothing ) + $y[ $#x - 1 ] )
                      / ( 2 + 1 / ( 0.01 + $smoothing ) );
                    $xa[$#x] = $xa[0];
                    $ya[$#x] = $ya[0];
                }
                else {
                    $xa[$#x] = $x[$#x];
                    $ya[$#x] = $y[$#x];
                    $xa[0]   = $x[0];
                    $ya[0]   = $y[0];
                }

                for ( $k = 1 ; $k < $#x ; $k++ ) {
                    $x[$k] =
                      ( $xa[ $k - 1 ] +
                          $xa[$k] / ( 0.01 + $smoothing ) +
                          $xa[ $k + 1 ] ) /
                      ( 2 + 1 / ( 0.01 + $smoothing ) );
                    $y[$k] =
                      ( $ya[ $k - 1 ] +
                          $ya[$k] / ( 0.01 + $smoothing ) +
                          $ya[ $k + 1 ] ) /
                      ( 2 + 1 / ( 0.01 + $smoothing ) );
                }
                if ( $xa[0] == $xa[$#x] && $ya[0] == $ya[$#x] ) {
                    $x[0] =
                      ( $xa[1] +
                          $xa[0] / ( 0.01 + $smoothing ) +
                          $xa[ $#x - 1 ] ) /
                      ( 2 + 1 / ( 0.01 + $smoothing ) );
                    $y[0] =
                      ( $ya[1] +
                          $ya[0] / ( 0.01 + $smoothing ) +
                          $ya[ $#x - 1 ] ) /
                      ( 2 + 1 / ( 0.01 + $smoothing ) );
                    $x[$#x] = $x[0];
                    $y[$#x] = $y[0];
                }
                else {
                    $x[$#x] = $xa[$#x];
                    $y[$#x] = $ya[$#x];
                    $x[0]   = $xa[0];
                    $y[0]   = $ya[0];
                }

                for ( $k = 1 ; $k < $#x ; $k++ ) {
                    $xa[$k] =
                      ( $x[ $k - 1 ] +
                          $x[$k] / ( 0.01 + $smoothing ) +
                          $x[ $k + 1 ] ) /
                      ( 2 + 1 / ( 0.01 + $smoothing ) );
                    $ya[$k] =
                      ( $y[ $k - 1 ] +
                          $y[$k] / ( 0.01 + $smoothing ) +
                          $y[ $k + 1 ] ) /
                      ( 2 + 1 / ( 0.01 + $smoothing ) );
                }
                if ( $x[0] == $x[$#x] && $y[0] == $y[$#x] ) {
                    $xa[0] =
                      ( $x[1] + $x[0] / ( 0.01 + $smoothing ) + $x[ $#x - 1 ] )
                      / ( 2 + 1 / ( 0.01 + $smoothing ) );
                    $ya[0] =
                      ( $y[1] + $y[0] / ( 0.01 + $smoothing ) + $y[ $#x - 1 ] )
                      / ( 2 + 1 / ( 0.01 + $smoothing ) );
                    $xa[$#x] = $xa[0];
                    $ya[$#x] = $ya[0];
                }
                else {
                    $xa[$#x] = $x[$#x];
                    $ya[$#x] = $y[$#x];
                    $xa[0]   = $x[0];
                    $ya[0]   = $y[0];
                }
###
                for ( $k = 0 ; $k < $#x + 1 ; $k++ ) {
                    $x[$k] = $xa[$k];
                    $y[$k] = $ya[$k];
                }
                for ( $k = 2 ; $k < $#x - 2 ; $k++ ) {
                    $dx2[$k] =
                      ( $x[ $k - 2 ] +
                          $x[ $k - 1 ] +
                          $x[$k] +
                          $x[ $k + 1 ] +
                          $x[ $k + 2 ] +
                          $x[ $k + 3 ] ) / 6;
                    $dy2[$k] =
                      ( $y[ $k - 2 ] +
                          $y[ $k - 1 ] +
                          $y[$k] +
                          $y[ $k + 1 ] +
                          $y[ $k + 2 ] +
                          $y[ $k + 3 ] ) / 6;
                }

                for ( $k = 3 ; $k < $#x - 2 ; $k++ ) {
                    $x[$k] = $x[$k] + ( $dx[$k] - $dx2[$k] ) * $curviness;
                    $y[$k] = $y[$k] + ( $dy[$k] - $dy2[$k] ) * $curviness;
                }

###

                $layer = 'contour';
                if ( $depression == -1 ) {
                    $layer = 'depression';
                }

                if ( $indexcontours != 0 ) {

                    if (
                        (
                            floor(
                                ( floor( $h / $interval + 0.5 ) * $interval ) /
                                  $indexcontours
                            ) -
                            ( floor( $h / $interval + 0.5 ) * $interval ) /
                            $indexcontours
                        ) * $indexcontours == 0
                      )
                    {
                        $layer .= '_index';
                    }
                }
                if ( $formline > 0 ) {
                    if (

                        floor(
                            ( floor( $h / $interval + 0.5 ) * $interval ) /
                              ( 2 * $interval )
                        ) -
                        ( floor( $h / $interval + 0.5 ) * $interval ) /
                        ( 2 * $interval ) != 0
                      )
                    {
                        $layer .= '_intermed';
                    }
                }
                print ULOS "POLYLINE
 66
1
  8
$layer
  0
";

                #print "$#x\n";
                for ( $k = 0 ; $k < $#x + 1 ; $k++ ) {
                    print ULOS "VERTEX
  8
$layer
 10
" . ( 1 * $x[$k] ) . "
 20
" . ( 1 * $y[$k] ) . "
  0
";

                }
                print ULOS "SEQEND
  0
";
            }    #if not dotkoll

        }

    }

####
    print ULOS "ENDSEC
  0
EOF
";

    # print "Joincount $joined ";
    print ".................... done.";
}

#######################################

if ( $command eq 'dotknolls' ) {

    #print "grid\n";

    $interval = 2.5 * $scalefactor;

    open( SISAAN, "<" . $tempfolder . "xyz_knolls.xyz" );
    @d = <SISAAN>;
    close SISAAN;

    @r1     = split( / /, $d[0] );
    @r2     = split( / /, $d[1] );
    $size   = $r2[1] - $r1[1];
    $xstart = $r1[0];
    $ystart = $r1[1];

    $xmax = 0;
    $ymax = 0;
    foreach $rec (@d) {
        @r = split( / /, $rec );

        if ( $xmax < floor( ( $r[0] - $xstart ) / $size ) ) {
            $xmax = floor( ( $r[0] - $xstart ) / $size );
        }
        if ( $ymax < floor( ( $r[1] - $ystart ) / $size ) ) {
            $ymax = floor( ( $r[1] - $ystart ) / $size );
        }
        $c++;
    }

    #print " $c points \n";

    $im = new GD::Image( $xmax * $size / $scalefactor,
        $ymax * $size / $scalefactor );
    $white = $im->colorAllocate( 255, 255, 255 );
    $black = $im->colorAllocate( 0,   0,   0 );

    #print "reading dxf \n";
    open( ULOS, ">" . $tempfolder . "dotknolls.dxf" );

    open( SISAAN, "<" . $tempfolder . "out2.dxf" );
    @d = <SISAAN>;
    close SISAAN;

    open( SISAAN, "<" . $tempfolder . "dotknolls.txt" );
    @dotknolls = <SISAAN>;
    close SISAAN;

    print ULOS "  0
SECTION
  2
HEADER
  9
\$EXTMIN
 10
$xstart
 20
$ystart
  9
\$EXTMAX
 10
" . ( $xstart + $xmax * $size ) . "
 20
" . ( $ystart + $ymax * $size ) . "
  0
ENDSEC
  0
SECTION
  2
ENTITIES
  0
";

    $d = join( '', @d );

    @d = split( /POLYLINE/, $d );

    $j = 0;
    foreach $rec (@d) {
        $temp1 = '';
        $temp2 = '';
        $j++;
        if ( $j > 1 ) {
            @r = split( /VERTEX/, $rec );

########
            $apu = $r[1];
            @val = split( /\n/, $apu );
            $i   = 0;
            foreach $v (@val) {
                chomp($v);
                if ( $v eq ' 10' ) {
                    $xline = $i + 1;
                }
                if ( $v eq ' 20' ) {
                    $yline = $i + 1;
                }
                $i++;
            }
##########

            $i = 0;

            #print "$j\n";
            foreach $v (@r) {
                $i++;
                if ( $i > 1 ) {
                    @val = split( /\n/, $v );
                    $temp1 .= ( 1 * $val[$xline] ) . '|';
                    $temp2 .= ( 1 * $val[$yline] ) . '|';

                }
            }
        }

        #print "#".$temp;
        chop($temp1);
        chop($temp2);
        @x = split( /\|/, $temp1 );
        @y = split( /\|/, $temp2 );

        for ( $i = 1 ; $i < $#x + 1 ; $i++ ) {
            $im->line(
                ( $x[ $i - 1 ] - $xstart ) / $scalefactor,
                ( $y[ $i - 1 ] - $ystart ) / $scalefactor,
                ( $x[$i] - $xstart ) / $scalefactor,
                ( $y[$i] - $ystart ) / $scalefactor,
                $black
            );
        }

    }
####
    open( ULOS2, ">" . $tempfolder . "dotknolls2.txt" );
    foreach $rec (@dotknolls) {
        chomp($rec);
        ( $depression, $x, $y ) = split( / /, $rec );
        $ok = 1;
        for (
            $i = ( $x - $xstart ) / $scalefactor - 3 ;
            $i < ( $x - $xstart ) / $scalefactor + 4 ;
            $i++
          )
        {
            for (
                $j = ( $y - $ystart ) / $scalefactor - 3 ;
                $j < ( $y - $ystart ) / $scalefactor + 4 ;
                $j++
              )
            {
                ( $r, $g, $b ) =
                  $im->rgb( $im->getPixel( $i, $j ) );
                if ( $r == 0 ) { $ok = 0; }
            }
        }
        $layer = '';
        if ( $ok == 0 ) {
            $layer = 'ugly';
        }
        print ULOS2 "$rec\n";

        if ( $depression == 1 ) {
            $layer = $layer . 'dotknoll';
        }
        else {
            $layer = $layer . 'udepression';
        }

        print ULOS "POINT
  8
$layer
 10
$x
 20
$y
 50
0
  0\n";

    }
    print ULOS "ENDSEC
  0
EOF
";
##
    #open(IMAGE,">".$tempfolder."map.png");
    # binmode IMAGE;

    #     Convert the image to PNG and print it on standard output
    #        print IMAGE $im->png;
    #    close IMAGE;

    print ".................... done.";
}    # dotknolls

if ( $command eq 'render' ) {

    $angle = $ARGV[1];
    $angle =~ s/\,/\./;
    $angle = -1 * $angle / 360 * 2 * 3.14159265358;

    $nwidth = 1 * $ARGV[2];

    $maptype = $ARGV[3];

    $formlinesteepness = $formlinesteepness * $scalefactor;

    if ( $maptype eq 'nodepressions' ) {
        $nodepressions = 1;
    }

    if ( $formline > 0 ) {
        open( SISAAN, "<" . $tempfolder . "xyz2.xyz" );
        @d = <SISAAN>;
        close SISAAN;

        @r1     = split( / /, $d[0] );
        @r2     = split( / /, $d[1] );
        $size   = $r2[1] - $r1[1];
        $xstart = $r1[0];
        $ystart = $r1[1];
        $sxmax  = -9999999999;
        $symax  = -9999999999;
        foreach $rec (@d) {
            @r = split( / /, $rec );

            $xyz[ floor( ( $r[0] - $xstart ) / $size ) ]
              [ floor( ( $r[1] - $ystart ) / $size ) ] = 1 * $r[2];
            if (   floor( ( $r[0] - $xstart ) / $size ) < 0
                || floor( ( $r[1] - $ystart ) / $size ) < 0 )
            {
                print "error";
                exit;
            }
            if ( $sxmax < floor( ( $r[0] - $xstart ) / $size ) ) {
                $sxmax = floor( ( $r[0] - $xstart ) / $size );
            }
            if ( $symax < floor( ( $r[1] - $ystart ) / $size ) ) {
                $symax = floor( ( $r[1] - $ystart ) / $size );
            }
            $c++;
        }
        print "..";

        # print "steepness\n";

        for ( $i = 6 ; $i < $sxmax - 7 ; $i++ ) {
            for ( $j = 6 ; $j < $symax - 7 ; $j++ ) {
                $det  = 0;
                $high = -999999999;

                $temp  = abs( $xyz[ $i - 4 ][$j] - $xyz[$i][$j] ) / 4;
                $temp2 = abs( $xyz[$i][$j] - $xyz[ $i + 4 ][$j] ) / 4;
                $det2 =
                  abs( $xyz[$i][$j] -
                      0.5 * ( $xyz[ $i - 4 ][$j] + $xyz[ $i + 4 ][$j] ) ) -
                  0.05 * abs( $xyz[ $i - 4 ][$j] - $xyz[ $i + 4 ][$j] );
                $porr = abs(
                    abs( ( $xyz[ $i - 6 ][$j] - $xyz[ $i + 6 ][$j] ) / 12 ) -
                      abs( ( $xyz[ $i - 3 ][$j] - $xyz[ $i + 3 ][$j] ) / 6 ) );

                if ( $det2 > $det )   { $det  = $det2; }
                if ( $temp2 < $temp ) { $temp = $temp2; }
                if ( $temp > $high )  { $high = $temp; }

                $temp  = abs( $xyz[$i][ $j - 4 ] - $xyz[$i][$j] ) / 4;
                $temp2 = abs( $xyz[$i][$j] - $xyz[$i][ $j - 4 ] ) / 4;
                $det2 =
                  abs( $xyz[$i][$j] -
                      0.5 * ( $xyz[$i][ $j - 4 ] + $xyz[$i][ $j + 4 ] ) ) -
                  0.05 * abs( $xyz[$i][ $j - 4 ] - $xyz[$i][ $j + 4 ] );
                $porr2 = abs(
                    abs( ( $xyz[$i][ $j - 6 ] - $xyz[$i][ $j + 6 ] ) / 12 ) -
                      abs( ( $xyz[$i][ $j - 3 ] - $xyz[$i][ $j + 3 ] ) ) / 6 );
                if ( $porr2 > $porr ) { $porr = $porr2; }
                if ( $det2 > $det )   { $det  = $det2; }
                if ( $temp2 < $temp ) { $temp = $temp2; }
                if ( $temp > $high )  { $high = $temp; }

                $temp  = abs( $xyz[ $i - 4 ][ $j - 4 ] - $xyz[$i][$j] ) / 5.6;
                $temp2 = abs( $xyz[$i][$j] - $xyz[ $i + 4 ][ $j + 4 ] ) / 5.6;
                $det2 =
                  abs( $xyz[$i][$j] - 0.5 *
                      ( $xyz[ $i - 4 ][ $j - 4 ] + $xyz[ $i + 4 ][ $j + 4 ] ) )
                  - 0.05 *
                  abs( $xyz[ $i - 4 ][ $j - 4 ] - $xyz[ $i + 4 ][ $j + 4 ] );
                $porr2 = abs(
                    abs(
                        ( $xyz[ $i - 6 ][ $j - 6 ] - $xyz[ $i + 6 ][ $j + 6 ] )
                        / 17
                    ) - abs(
                        ( $xyz[ $i - 3 ][ $j - 3 ] - $xyz[ $i + 3 ][ $j + 3 ] )
                        / 8.5
                    )
                );
                if ( $porr2 > $porr ) { $porr = $porr2; }

                if ( $det2 > $det )   { $det  = $det2; }
                if ( $temp2 < $temp ) { $temp = $temp2; }
                if ( $temp > $high )  { $high = $temp; }

                $temp  = abs( $xyz[ $i - 4 ][ $j + 4 ] - $xyz[$i][$j] ) / 5.6;
                $temp2 = abs( $xyz[$i][$j] - $xyz[ $i + 4 ][ $j - 4 ] ) / 5.6;
                $det2 =
                  abs( $xyz[$i][$j] - 0.5 *
                      ( $xyz[ $i + 4 ][ $j - 4 ] + $xyz[ $i - 4 ][ $j + 4 ] ) )
                  - 0.05 *
                  abs( $xyz[ $i + 4 ][ $j - 4 ] - $xyz[ $i - 4 ][ $j + 4 ] );
                $porr2 = abs(
                    abs(
                        ( $xyz[ $i + 6 ][ $j - 6 ] - $xyz[ $i - 6 ][ $j + 6 ] )
                        / 17
                    ) - abs(
                        ( $xyz[ $i + 3 ][ $j - 3 ] - $xyz[ $i - 3 ][ $j + 3 ] )
                        / 8.5
                    )
                );
                if ( $porr2 > $porr ) { $porr = $porr2; }

                if ( $det2 > $det )   { $det  = $det2; }
                if ( $temp2 < $temp ) { $temp = $temp2; }
                if ( $temp > $high )  { $high = $temp; }

                $steepness[$i][$j] = 12 * ($high) / ( 1 + 8 * $det );

                #print " $porr ";
                if ( $porr > 0.25 * (0.67) / ( 0.3 + $formlinesteepness ) ) {
                    $steepness[$i][$j] = 0.01;
                }
                if ( $high > $steepness[$i][$j] ) {
                    $steepness[$i][$j] = $high;
                }

                #if($high*.3 >$steepness[$i][$j]){$steepness[$i][$j]=$high*.3;}

            }

        }
        if ( 1 == 0 ) {
            for ( $i = 6 ; $i < $sxmax - 7 ; $i++ ) {
                for ( $j = 6 ; $j < $symax - 7 ; $j++ ) {
                    $low  = 999999999;
                    $high = -999999999;
                    for ( $ii = $i - 6 ; $ii < $i + 7 ; $ii = $ii + 3 ) {
                        for ( $jj = $j - 6 ; $jj < $j + 7 ; $jj = $jj + 3 ) {
                            if ( abs( $jj - $j ) + abs( $ii - $i ) < 11 ) {
                                if ( $xyz[$ii][$jj] < $low ) {
                                    $low = $xyz[$ii][$jj];
                                }
                                if ( $xyz[$ii][$jj] > $high ) {
                                    $high = $xyz[$ii][$jj];
                                }
                            }
                        }
                    }
                    $steepness[$i][$j] = ( $high - $low ) / 12;

                    $low  = 999999999;
                    $high = -999999999;
                    for ( $ii = $i - 3 ; $ii < $i + 4 ; $ii++ ) {
                        for ( $jj = $j - 3 ; $jj < $j + 4 ; $jj++ ) {
                            if ( abs( $jj - $j ) + abs( $ii - $i ) < 6 ) {
                                if ( $xyz[$ii][$jj] < $low ) {
                                    $low = $xyz[$ii][$jj];
                                }
                                if ( $xyz[$ii][$jj] > $high ) {
                                    $high = $xyz[$ii][$jj];
                                }

                            }
                        }
                    }
                    if ( ( $high - $low ) / 6 < $steepness[$i][$j] ) {
                        $steepness[$i][$j] = ( $high - $low ) / 6;
                    }
                    $low  = 999999999;
                    $high = -999999999;
                    for ( $ii = $i - 1 ; $ii < $i + 2 ; $ii++ ) {
                        for ( $jj = $j - 1 ; $jj < $j + 2 ; $jj++ ) {
                            if ( $xyz[$ii][$jj] < $low ) {
                                $low = $xyz[$ii][$jj];
                            }
                            if ( $xyz[$ii][$jj] > $high ) {
                                $high = $xyz[$ii][$jj];
                            }

                        }
                    }

                    if ( ( $high - $low ) / 2 < $steepness[$i][$j] ) {
                        $steepness[$i][$j] = ( $high - $low ) / 2;
                    }

                    $steepness[$i][$j] =
                      1 * $steepness[$i][$j] -
                      0.2 * abs( $steepness[$i][$j] - ( $high - $low ) / 2 );
                }
            }
        }
        print ".";
    }
    use GD;

    open( SISAAN, "<" . $tempfolder . "vegetation.pgw" );
    @tfw = <SISAAN>;
    close SISAAN;

    $x0      = 1 * $tfw[4];
    $y0      = 1 * $tfw[5];
    $resvege = 1 * $tfw[0];

    $img   = newFromPng GD::Image( $tempfolder . 'vegetation.png' );
    $imgug = newFromPng GD::Image( $tempfolder . 'undergrowth.png' );

    ( $w, $h ) = $img->getBounds();

    # offset for northlines
    $eastoff =
      ( $x0 - tan( -$angle ) * $y0 ) -
      floor( ( $x0 - tan( -$angle ) * $y0 ) / ( 250 / cos($angle) ) ) *
      ( 250 / cos($angle) );
    $eastoff = -$eastoff / 254 * 600;

    $img2 = new GD::Image( $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor );

    $white  = $img2->colorAllocate( 255, 255, 255 );
    $brown  = $img2->colorAllocate( 166, 85,  43 );
    $black  = $img2->colorAllocate( 0,   0,   0 );
    $purple = $img2->colorAllocate( 200, 0,   200 );
    $blue   = $img2->colorAllocate( 0,   0,   200 );

    $img2->copyResized(
        $img, 0, 0, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor,
        $w, $h
    );

    $img2->copy(
        $imgug, 0, 0, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor
    );

    if ( -e $tempfolder . 'low.png' ) {
        $low    = newFromPng GD::Image( $tempfolder . 'low.png' );
        $transp = $low->colorClosest( 255, 255, 255 );
        $low->transparent($transp);
        $img2->copy(
            $low, 0, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );
    }

## north lines

    if ( $angle != 999 ) {
        for (
            $i =
              $eastoff - 600 * 250 / 254 / cos($angle) * 100 / $scalefactor ;
            $i < 5 * $w * 600 / 254 / $scalefactor ;
            $i = $i + 600 * 250 / 254 / cos($angle) / $scalefactor
          )
        {
            for ( $m = 0 ; $m < $nwidth ; $m++ ) {
                $img2->line(
                    ( $i + $m ),
                    (0),
                    ( $i + tan($angle) * $h * 600 / 254 / $scalefactor + $m ),
                    ( $h * 600 / 254 / $scalefactor ),
                    $blue
                );
            }
        }
    }

    open( SISAAN, "<" . $tempfolder . "out2.dxf" );
    @d = <SISAAN>;
    close SISAAN;

    $d = join( '', @d );

    @d = split( /POLYLINE/, $d );

    if ( $formline == 2 && $nodepressions != 1 ) {
        open( FORMLINE, ">" . $tempfolder . "formlines.dxf" );
        print FORMLINE $d[0];
    }

    $j = 0;
    foreach $rec (@d) {
        $temp1 = '';
        $temp2 = '';

        $j++;
        if ( $j > 1 ) {
            @r = split( /VERTEX/, $rec );

########
            $apu = $r[1];
            @val = split( /\n/, $apu );

            $layer = $val[2];
            chomp($layer);
            $i = 0;
            foreach $v (@val) {
                chomp($v);
                if ( $v eq ' 10' ) {
                    $xline = $i + 1;
                }
                if ( $v eq ' 20' ) {
                    $yline = $i + 1;
                }
                $i++;
            }
##########

            $i = 0;

            #print "$j\n";

            foreach $v (@r) {
                $i++;
                if ( $i > 1 ) {
                    @val = split( /\n/, $v );

                    $temp1 .=
                      ( ( 1 * $val[$xline] - $x0 ) * 600 / 254 / $scalefactor )
                      . '|';
                    $temp2 .=
                      ( ( $y0 - 1 * $val[$yline] ) * 600 / 254 / $scalefactor )
                      . '|';

                }
            }

        }

        #print "#".$temp;
        chop($temp1);
        chop($temp2);
        @x   = split( /\|/, $temp1 );
        @y   = split( /\|/, $temp2 );
        $col = $purple;
        if ( $layer =~ /contour/ ) { $col = $brown; }
        if ( $nodepressions != 1 || $layer =~ /contour/ ) {
            $curvew = 2;
            if ( $layer =~ /index/ ) {
                $curvew = 3;
            }
            if ( $formline > 0 ) {

                if ( $formline == 1 ) {
                    $curvew = 2.5;
                }
                if ( $layer =~ /intermed/ ) {
                    $curvew = 1.5;
                }
                if ( $layer =~ /index/ ) {
                    $curvew = 3.5;
                }
            }
            if ( $curvew == 1.5 ) {
                undef @help;
                undef @help2;

                for ( $i = 0 ; $i < $#x + 1 ; $i++ ) {
                    $help[$i]  = 0;
                    $help2[$i] = 1;
                    if (
                           $curvew != 1.5
                        || $formline == 0
                        || $steepness[
                        floor(
                            (
                                ( $x[$i] / 600 * 254 * $scalefactor + $x0 ) -
                                  $xstart
                            ) / $size
                        )
                        ][
                        floor(
                            (
                                ( -$y[$i] / 600 * 254 * $scalefactor + $y0 ) -
                                  $ystart
                            ) / $size
                        )
                        ] < $formlinesteepness
                        || $steepness[
                        floor(
                            (
                                ( $x[$i] / 600 * 254 * $scalefactor + $x0 ) -
                                  $xstart
                            ) / $size
                        )
                        ][
                        floor(
                            (
                                ( -$y[$i] / 600 * 254 * $scalefactor + $y0 ) -
                                  $ystart
                            ) / $size
                        ) + 1
                        ] < $formlinesteepness
                        || $steepness[
                        floor(
                            (
                                ( $x[$i] / 600 * 254 * $scalefactor + $x0 ) -
                                  $xstart
                            ) / $size
                        ) + 1
                        ][
                        floor(
                            (
                                ( -$y[$i] / 600 * 254 * $scalefactor + $y0 ) -
                                  $ystart
                            ) / $size
                        )
                        ] < $formlinesteepness
                        || $steepness[
                        floor(
                            (
                                ( $x[$i] / 600 * 254 * $scalefactor + $x0 ) -
                                  $xstart
                            ) / $size
                        ) + 1
                        ][
                        floor(
                            (
                                ( -$y[$i] / 600 * 254 * $scalefactor + $y0 ) -
                                  $ystart
                            ) / $size
                        ) + 1
                        ] < $formlinesteepness
                      )
                    {
                        $help[$i] = 1;
                    }
                }

                for ( $i = 5 ; $i < $#x - 5 ; $i++ ) {
                    $apu = 0;
                    for ( $j = $i - 5 ; $j < $i + 4 ; $j++ ) {
                        $apu = $apu + $help[$j];
                    }
                    if ( $apu < 5 ) { $help2[$i] = 0; }
                }
                for ( $i = 0 ; $i < 5 + 1 ; $i++ ) {
                    $help2[$i] = $help2[6];
                }
                for ( $i = $#x - 5 ; $i < $#x + 1 ; $i++ ) {
                    $help2[$i] = $help2[ $#x - 6 ];
                }

                $on = 0;
                for ( $i = 0 ; $i < $#x + 1 ; $i++ ) {
                    if ( $help2[$i] == 1 ) { $on = $formlineaddition; }
                    if ( $on > 0 ) { $help2[$i] = 1; $on = $on - 1; }
                }
                if ( $x[0] == $x[$#x] && $y[0] == $y[$#y] && $on > 0 ) {
                    for ( $i = 0 ; $i < $#x + 1 && $on > 0 ; $i++ ) {
                        $help2[$i] = 1;
                        $on = $on - 1;
                    }
                }
                $on = 0;
                for ( $i = $#x ; $i > -1 ; $i = $i - 1 ) {
                    if ( $help2[$i] == 1 ) { $on = $formlineaddition; }
                    if ( $on > 0 ) { $help2[$i] = 1; $on = $on - 1; }
                }
                if ( $x[0] == $x[$#x] && $y[0] == $y[$#y] && $on > 0 ) {
                    for ( $i = $#x ; $i > -1 && $on > 0 ; $i = $i - 1 ) {
                        $help2[$i] = 1;
                        $on = $on - 1;
                    }
                }

                ## lets not break small form line rigs
                $smallringtest = 0;
                if ( $x[0] == $x[$#x] && $y[0] == $y[$#y] && $#x < 121 ) {
                    for ( $i = 1 ; $i < $#x + 1 ; $i++ ) {
                        if ( $help2[$i] == 1 ) {
                            $smallringtest = 1;
                        }
                    }
                }

                ## lets draw short gaps together
                if ( $smallringtest == 0 ) {
                    $testeri = 1;
                    for ( $i = 1 ; $i < $#x + 1 ; $i++ ) {

                        if ( $help2[$i] == 1 ) {
                            if ( $testeri < $i && $i - $testeri < $minimumgap )
                            {

                                for ( $j = $testeri ; $j < $i + 1 ; $j++ ) {
                                    $help2[$j] = 1;
                                }
                            }
                            $testeri = $i;
                        }
                    }

                    # ring  handling
                    if ( $x[0] == $x[$#x] && $y[0] == $y[$#y] && $#x > 1 ) {
                        for ( $i = 1 ; $i < $#x + 1 && $help2[$i] != 1 ; $i++ )
                        {
                        }
                        for (
                            $j = $#x ;
                            $j > 1 && $help2[$j] != 1 ;
                            $j = $j - 1
                          )
                        {
                        }
                        if ( $#x - $j + $i < $minimumgap && $j > $i ) {
                            for ( $k = 0 ; $k < $i + 1 ; $k++ ) {
                                $help2[$k] = 1;
                            }
                            for ( $k = $j ; $k < $#x + 1 ; $k++ ) {
                                $help2[$k] = 1;
                            }
                        }

                    }
                }
            }    # formlines only
                 #			if($curvew == 1.5 && $formline==2){
                 #&dashedcontourstyle;
                 # $img2->setThickness(5);
                 # }
            $linedist   = 0;
            $onegapdone = 0;
            $gap        = 0;

            $formlinestart = 0;
            for ( $i = 1 ; $i < $#x + 1 ; $i++ ) {
                if (   $curvew != 1.5
                    || $formline == 0
                    || $help2[$i] == 1
                    || $smallringtest == 1 )
                {
                    if (   $formline == 2
                        && $nodepressions != 1
                        && $curvew == 1.5 )
                    {
                        if ( $formlinestart == 0 ) {
                            print FORMLINE "POLYLINE
 66
1
  8
formline
  0\n";
                            $formlinestart = 1;
                        }
                        print FORMLINE "VERTEX
  8
formline
 10
" . ( $x[$i] / 600 * 254 * $scalefactor + $x0 ) . "
 20
" . ( -$y[$i] / 600 * 254 * $scalefactor + $y0 ) . "
  0\n";
                    }

                    #print " ($x[$i]  $y[$i] ) ";
                    if ( $curvew == 1.5 && $formline == 2 ) {
                        $step =
                          sqrt( ( $x[ $i - 1 ] - $x[$i] ) *
                              ( $x[ $i - 1 ] - $x[$i] ) +
                              ( $y[ $i - 1 ] - $y[$i] ) *
                              ( $y[ $i - 1 ] - $y[$i] ) );

                        #if($i%12==0){
                        #$gap=6.9;
                        #}
                        if ( $i < 4 ) { $linedist = 0; }
                        $linedist = $linedist + $step;
                        if (   $linedist > $dashlength
                            && $i > 10
                            && $i < $#x - 10 )
                        {
                            $sum = 0;
                            for ( $k = $i - 4 ; $k < $i + 6 ; $k++ ) {
                                $sum =
                                  $sum +
                                  sqrt( ( $x[ $k - 1 ] - $x[$k] ) *
                                      ( $x[ $k - 1 ] - $x[$k] ) +
                                      ( $y[ $k - 1 ] - $y[$k] ) *
                                      ( $y[ $k - 1 ] - $y[$k] ) );
                            }
                            $toonearend = 0;
                            for ( $k = $i - 10 ; $k < $i + 10 ; $k++ ) {
                                if ( $help2[$k] != 1 ) { $toonearend = 1; }
                            }
                            if (
                                $toonearend == 0
                                && sqrt(
                                    ( $x[ $i - 5 ] - $x[ $i + 5 ] ) *
                                      ( $x[ $i - 5 ] - $x[ $i + 5 ] ) +
                                      ( $y[ $i - 5 ] - $y[ $i + 5 ] ) *
                                      ( $y[ $i - 5 ] - $y[ $i + 5 ] )
                                ) * 1.138 > $sum
                              )
                            {

                                $linedist   = 0;
                                $gap        = $gaplength;
                                $onegapdone = 1;
                            }
                        }
                        if ( $onegapdone == 0 && $i < $#x - 8 && $i > 6 ) {
                            $gap        = $gaplength * 0.82;
                            $onegapdone = 1;
                            $linedist   = 0;
                        }

                        if ( ( $gap > 0 ) ) {

                            $gap = $gap - $step;
                            if ( $gap < 0 && $onegapdone == 1 && $step > 0 ) {
                                for (
                                    $n = -$curvew - .5 ;
                                    $n < $curvew + .5 ;
                                    $n++
                                  )
                                {
                                    for (
                                        $m = -$curvew - .5 ;
                                        $m < $curvew + .5 ;
                                        $m++
                                      )
                                    {

                                        $img2->line(
                                            (
                                                (
                                                    $x[ $i - 1 ] * ( -$gap ) +
                                                      ( $step + $gap ) * $x[$i]
                                                ) / ($step) + $n
                                            ),
                                            (
                                                (
                                                    $y[ $i - 1 ] * ( -$gap ) +
                                                      ( $step + $gap ) * $y[$i]
                                                ) / ($step) + $m
                                            ),
                                            ( $x[$i] + $n ),
                                            ( $y[$i] + $m ),
                                            $col
                                        );
                                    }
                                }

#print " ( (".$x[$i-1]."*(-$gap) + ($step+$gap)*".$x[$i].")/($step-$gap)+ $n )\n";
                                $gap = 0;
                            }

                        }
                        else {
                            for (
                                $n = -$curvew - .5 ;
                                $n < $curvew + .5 ;
                                $n++
                              )
                            {
                                for (
                                    $m = -$curvew - .5 ;
                                    $m < $curvew + .5 ;
                                    $m++
                                  )
                                {

                                    $img2->line(
                                        ( $x[ $i - 1 ] + $n ),
                                        ( $y[ $i - 1 ] + $m ),
                                        ( $x[$i] + $n ),
                                        ( $y[$i] + $m ),
                                        $col
                                    );
                                }
                            }
                        }

                        #      $img2->line(
                        #           ( $x[ $i - 1 ]  ),
                        #           ( $y[ $i - 1 ] ),
                        #           ( $x[$i]  ),
                        #           ( $y[$i] ), gdStyled
                        #       );

                    }
                    else {
                        for ( $n = -$curvew ; $n < $curvew ; $n++ ) {
                            for ( $m = -$curvew ; $m < $curvew ; $m++ ) {

                                $img2->line(
                                    ( $x[ $i - 1 ] + $n ),
                                    ( $y[ $i - 1 ] + $m ),
                                    ( $x[$i] + $n ),
                                    ( $y[$i] + $m ),
                                    $col
                                );
                            }
                        }

                    }
                }
                else {
                    if (   $formline == 2
                        && $formlinestart == 1
                        && $nodepressions != 1 )
                    {
                        print FORMLINE "SEQEND
  0\n";
                        $formlinestart = 0;
                    }
                }
            }

            if ( $formline == 2 && $formlinestart == 1 && $nodepressions != 1 )
            {
                print FORMLINE "SEQEND
  0\n";
                $formlinestart = 0;
            }

            $img2->setThickness(1);
        }
    }
####
    if ( $formline == 2 && $nodepressions != 1 ) {
        print FORMLINE "ENDSEC
  0
EOF";
    }
##################

    open( SISAAN, "<" . $tempfolder . "dotknolls.dxf" );
    @d = <SISAAN>;
    close SISAAN;

    $d = join( '', @d );

    @d = split( /POINT/, $d );

    $j = 0;
    foreach $rec (@d) {
        $temp1 = '';
        $temp2 = '';

        $j++;
        if ( $j > 1 ) {

            @val = split( /\n/, $rec );

            $layer = $val[2];
            chomp($layer);
            $i = 0;
            foreach $v (@val) {
                chomp($v);
                if ( $v eq ' 10' ) {
                    $x = ( ( 1 * $val[ $i + 1 ] - $x0 ) * 600 / 254 /
                          $scalefactor );
                }
                if ( $v eq ' 20' ) {
                    $y = ( ( $y0 - 1 * $val[ $i + 1 ] ) * 600 / 254 /
                          $scalefactor );
                }
                $i++;
            }

            #print "($x,$y)";

            if ( $layer eq 'dotknoll' ) {
                $col = $brown;
                $img2->filledArc( $x, $y, 15, 15, 0, 360, $col );
            }

        }

    }
###

    if ( -e $tempfolder . 'blocks.png' ) {

        #$blocks = new GD::Image( $w * 600 / 254, $h * 600 / 254 );
        $blocks      = newFromPng GD::Image( $tempfolder . 'blocks.png' );
        $blockpurple = new GD::Image( $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor );

# $bpurple  = $blockpurple->colorAllocate( 0, 0, 120 );
#      $blockpurple->filledRectangle( 0,0, $w * 600 / 254+1, $h * 600 / 254+1, bpurple );
#	$transp = $blocks->colorClosest( 0,0, 0  );
#       $blocks->transparent($transp);
        $blockpurple->copyResized(
            $blocks, 0, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor,
            $w, $h
        );

        $transp = $blockpurple->colorClosest( 255, 255, 255 );
        $blockpurple->transparent($transp);
        $img2->copy(
            $blockpurple, -2, -2, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );
        $img2->copy(
            $blockpurple, -2, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );
        $img2->copy(
            $blockpurple, -2, 2, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );
        $img2->copy(
            $blockpurple, 0, -2, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );
        $img2->copy(
            $blockpurple, 0, 0, 0, 0,
            $w * 600 / 254,
            $h * 600 / 254 / $scalefactor
        );
        $img2->copy(
            $blockpurple, 0, 2, 0, 0,
            $w * 600 / 254,
            $h * 600 / 254 / $scalefactor
        );
        $img2->copy(
            $blockpurple, 2, -2, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );
        $img2->copy(
            $blockpurple, 2, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );
        $img2->copy(
            $blockpurple, 2, 2, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );

        $blockpurple = new GD::Image( $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor );

        $bpurple = $blockpurple->colorAllocate( 255, 110, 255 );
        $blockpurple->filledRectangle(
            0, 0,
            $w * 600 / 254 / $scalefactor + 1,
            $h * 600 / 254 / $scalefactor + 1, bpurple
        );
        $transp = $blocks->colorClosest( 0, 0, 0 );
        $blocks->transparent($transp);
        $blockpurple->copyResized(
            $blocks, 0, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor,
            $w, $h
        );

        $transp = $blockpurple->colorClosest( 255, 255, 255 );
        $blockpurple->transparent($transp);
        $img2->copy(
            $blockpurple, 0, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );
        undef $blocks;
        undef $blockpurple;
    }

    if ( -e $tempfolder . 'blueblack.png' ) {

        $blueb = new GD::Image( $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor );

        $bbwhite = $blueb->colorAllocate( 255, 255, 255 );
        $bbblue  = $blueb->colorAllocate( 0,   0,   200 );
        $imgbb   = newFromPng GD::Image( $tempfolder . 'blueblack.png' );

        $blueb->copyResized(
            $imgbb, 0, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor,
            $w, $h
        );

        if ( $angle != 999 ) {
            for (
                $i =
                  $eastoff -
                  600 * 250 / 254 / $scalefactor / cos($angle) * 100 ;
                $i < 5 * $w * 600 / 254 / $scalefactor ;
                $i = $i +
                  600 * 250 / 254 / $scalefactor / cos($angle)
              )
            {
                for ( $m = 0 ; $m < $nwidth ; $m++ ) {
                    $blueb->line(
                        ( $i + $m ),
                        (0),
                        (
                            $i +
                              tan($angle) * $h * 600 / 254 / $scalefactor +
                              $m
                        ),
                        ( $h * 600 / 254 / $scalefactor ),
                        $bbblue
                    );
                }
            }
        }

        $transp = $imgbb->colorClosest( 29, 190, 255 );
        $imgbb->transparent($transp);
        $blueb->copyResized(
            $imgbb, 0, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor,
            $w, $h
        );
        $transp = $blueb->colorClosest( 255, 255, 255 );
        $blueb->transparent($transp);
        $img2->copy(
            $blueb, 0, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );
    }

    ################
    $splitter = $/;
    $/        = 'POLYLINE';

##################

    $cliffdebug = $Config->{_}->{cliffdebug};

    if ( $cliffdebug == 1 ) {
        $cliffcolor{'cliff2'} = $img2->colorAllocate( 100, 0,   100 );
        $cliffcolor{'cliff3'} = $img2->colorAllocate( 0,   100, 100 );
        $cliffcolor{'cliff4'} = $img2->colorAllocate( 100, 100, 0 );

    }
    else {

        $cliffcolor{'cliff2'} = $black;
        $cliffcolor{'cliff3'} = $black;
        $cliffcolor{'cliff4'} = $black;
    }

    open( SISAAN, "<" . $tempfolder . "c2g.dxf" );
    $j = 0;
    while ( $rec = <SISAAN> ) {
        $temp1 = '';
        $temp2 = '';

        $j++;
        if ( $j > 1 ) {
            @r = split( /VERTEX/, $rec );

########
            $apu = $r[1];
            @val = split( /\n/, $apu );

            $layer = $val[2];
            chomp($layer);
            $i = 0;
            foreach $v (@val) {
                chomp($v);
                if ( $v eq ' 10' ) {
                    $xline = $i + 1;
                }
                if ( $v eq ' 20' ) {
                    $yline = $i + 1;
                }
                $i++;
            }
##########

            $i = 0;

            #print "$j\n";

            foreach $v (@r) {
                $i++;
                if ( $i > 1 ) {
                    @val = split( /\n/, $v );

                    $temp1 .=
                      ( ( 1 * $val[$xline] - $x0 ) * 600 / 254 / $scalefactor )
                      . '|';
                    $temp2 .=
                      ( ( $y0 - 1 * $val[$yline] ) * 600 / 254 / $scalefactor )
                      . '|';

                }
            }

        }

        #print "#".$temp;
        chop($temp1);
        chop($temp2);
        @x = split( /\|/, $temp1 );
        @y = split( /\|/, $temp2 );
        if ( $x[0] . '_' . $y[0] ne $x[$#x] . '_' . $y[$#y] ) {

            $dist =
              sqrt( ( $x[0] - $x[$#x] ) * ( $x[0] - $x[$#x] ) +
                  ( $y[0] - $y[$#y] ) * ( $y[0] - $y[$#y] ) );

            if ( $dist > 0 ) {
                $dx     = $x[0] - $x[$#x];
                $dy     = $y[0] - $y[$#y];
                $x[0]   = $x[0] + $dx / $dist * 1.5;
                $y[0]   = $y[0] + $dy / $dist * 1.5;
                $x[$#y] = $x[$#y] - $dx / $dist * 1.5;
                $y[$#y] = $y[$#y] - $dy / $dist * 1.5;

                $img2->filledArc( $x[0], $y[0], 8, 8, 0, 360,
                    $cliffcolor{$layer} );
                $img2->filledArc( $x[$#x], $y[$#y], 8, 8, 0, 360,
                    $cliffcolor{$layer} );
            }
        }

        for ( $i = 1 ; $i < $#x + 1 ; $i++ ) {

            #print " ($x[$i]  $y[$i] ) ";
            for ( $n = -3 ; $n < 3 ; $n++ ) {
                for ( $m = -3 ; $m < 3 ; $m++ ) {
                    $img2->line(
                        ( $x[ $i - 1 ] + $n ),
                        ( $y[ $i - 1 ] + $m ),
                        ( $x[$i] + $n ),
                        ( $y[$i] + $m ),
                        $cliffcolor{$layer}
                    );
                }
            }

        }

    }
    close(SISAAN);
##################

    open( SISAAN, "<" . $tempfolder . "c3g.dxf" );
    $j = 0;
    while ( $rec = <SISAAN> ) {
        $temp1 = '';
        $temp2 = '';

        $j++;
        if ( $j > 1 ) {
            @r = split( /VERTEX/, $rec );

########
            $apu = $r[1];
            @val = split( /\n/, $apu );

            $layer = $val[2];
            chomp($layer);
            $i = 0;
            foreach $v (@val) {
                chomp($v);
                if ( $v eq ' 10' ) {
                    $xline = $i + 1;
                }
                if ( $v eq ' 20' ) {
                    $yline = $i + 1;
                }
                $i++;
            }
##########

            $i = 0;

            #print "$j\n";

            foreach $v (@r) {
                $i++;
                if ( $i > 1 ) {
                    @val = split( /\n/, $v );

                    $temp1 .=
                      ( ( 1 * $val[$xline] - $x0 ) * 600 / 254 / $scalefactor )
                      . '|';
                    $temp2 .=
                      ( ( $y0 - 1 * $val[$yline] ) * 600 / 254 / $scalefactor )
                      . '|';

                }
            }

        }

        #print "#".$temp;
        chop($temp1);
        chop($temp2);
        @x = split( /\|/, $temp1 );
        @y = split( /\|/, $temp2 );
        if ( $x[0] . '_' . $y[0] ne $x[$#x] . '_' . $y[$#y] ) {

            $dist =
              sqrt( ( $x[0] - $x[$#x] ) * ( $x[0] - $x[$#x] ) +
                  ( $y[0] - $y[$#y] ) * ( $y[0] - $y[$#y] ) );

            if ( $dist > 0 ) {
                $dx     = $x[0] - $x[$#x];
                $dy     = $y[0] - $y[$#y];
                $x[0]   = $x[0] + $dx / $dist * 1.5;
                $y[0]   = $y[0] + $dy / $dist * 1.5;
                $x[$#y] = $x[$#y] - $dx / $dist * 1.5;
                $y[$#y] = $y[$#y] - $dy / $dist * 1.5;

                $img2->filledArc( $x[0], $y[0], 8, 8, 0, 360,
                    $cliffcolor{$layer} );
                $img2->filledArc( $x[$#x], $y[$#y], 8, 8, 0, 360,
                    $cliffcolor{$layer} );
            }
        }
        for ( $i = 1 ; $i < $#x + 1 ; $i++ ) {

            #print " ($x[$i]  $y[$i] ) ";
            for ( $n = -3 ; $n < 3 ; $n++ ) {
                for ( $m = -3 ; $m < 3 ; $m++ ) {
                    $img2->line(
                        ( $x[ $i - 1 ] + $n ),
                        ( $y[ $i - 1 ] + $m ),
                        ( $x[$i] + $n ),
                        ( $y[$i] + $m ),
                        $cliffcolor{$layer}
                    );
                }
            }

        }

    }
    close(SISAAN);
    $/ = $splitter;

###########

    open( SISAAN, "<" . $tempfolder . "vegetation.pgw" );
    @tfw = <SISAAN>;
    close SISAAN;

    $tfw[0] = '' . ( $tfw[0] / 600 * 254 * $scalefactor ) . "\n";
    $tfw[3] = '' . ( $tfw[3] / 600 * 254 * $scalefactor ) . "\n";

    if ( -e $tempfolder . 'high.png' ) {

        $imgtemp = new GD::Image( $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor );
        $high = newFromPng GD::Image( $tempfolder . 'high.png' );
        $imgtemp->copy(
            $high, 0, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );

        $northblue = $high->colorAllocate( 0, 0, 200 );

## north lines, for lakes

        if ( $angle != 999 ) {
            for (
                $i =
                  $eastoff -
                  600 * 250 / 254 / $scalefactor / cos($angle) * 100 ;
                $i < 5 * $w * 600 / 254 / $scalefactor ;
                $i = $i +
                  600 * 250 / 254 / $scalefactor / cos($angle)
              )
            {
                for ( $m = 0 ; $m < $nwidth ; $m++ ) {
                    $high->line(
                        ( $i + $m ),
                        (0),
                        (
                            $i +
                              tan($angle) * $h * 600 / 254 / $scalefactor +
                              $m
                        ),
                        ( $h * 600 / 254 / $scalefactor ),
                        $northblue
                    );
                }
            }
        }

        $transp = $imgtemp->colorClosest( 29, 190, 255 );
        $imgtemp->transparent($transp);
        $high->copy(
            $imgtemp, 0, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );

        $transp = $high->colorClosest( 255, 255, 255 );

        $high->transparent($transp);

        $img2->copy(
            $high, 0, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );
    }

##################
    if ( $nodepressions != 1 ) {

        open( ULOS, ">pullautus_depr$thread.pgw" );
        print ULOS @tfw;
        close ULOS;

        open( IMAGE, ">pullautus_depr$thread.png" );

    }
    else {

        open( ULOS, ">pullautus$thread.pgw" );
        print ULOS @tfw;
        close ULOS;

        open( IMAGE, ">pullautus$thread.png" );

    }
    binmode IMAGE;

    #      Convert the image to PNG and print it on standard output
    print IMAGE $img2->png;
    close IMAGE;

    print ".................... done.";
}

if ( $command eq 'unzipmtk' ) {

    use Archive::Zip qw(:ERROR_CODES);

    unlink "temp$thread/low.png";
    unlink "temp$thread/high.png";

    $i = 0;
    foreach $zipName (@ARGV) {

        if ( $i > 0 ) {
            $zip = Archive::Zip->new();
            print "$zipName  ...";

            my $status = $zip->read($zipName);
            die "Read of $zipName failed\n" if $status != AZ_OK;

            $zip->extractTree( '', "temp$thread/" );

            system("pullauta $thread mtkshaperender");
            print " ............. done\n";
        }
        $i++;
    }
}

if ( $command eq 'mtkshaperender' ) {
## render mml maastotietokanta shapes already in temp folder
    use Geo::ShapeFile;
    use GD::Polyline;

## pellot
    open( SISAAN, "<" . $tempfolder . "vegetation.pgw" );
    @tfw = <SISAAN>;
    close SISAAN;

    $x0      = 1 * $tfw[4];
    $y0      = 1 * $tfw[5];
    $resvege = 1 * $tfw[0];

    $img = newFromPng GD::Image( $tempfolder . 'vegetation.png' );

    ( $w, $h ) = $img->getBounds();

    $img2 = new GD::Image( $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor );
    $white = $img2->colorAllocate( 255, 255, 255 );

    $imgbrown = new GD::Image( $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor );
    $imgbrowntop = new GD::Image( $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor );
    $imgblack = new GD::Image( $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor );
    $imgblacktop = new GD::Image( $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor );
    $imgyellow = new GD::Image( $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor );
    $imgblue = new GD::Image( $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor );
    $imgmarsh = new GD::Image( $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor );
    $imgtempblack = new GD::Image( $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor );
    $imgtempblacktop = new GD::Image( $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor );
    $tempwhite = $imgtempblacktop->colorAllocate( 255, 255, 255 );
    $tempblack = $imgtempblacktop->colorAllocate( 0,   0,   0 );
    $tempwhite = $imgtempblack->colorAllocate( 255, 255, 255 );
    $tempblack = $imgtempblack->colorAllocate( 0,   0,   0 );

    $white = $imgbrown->colorAllocate( 255, 255, 255 );
    $white = $imgblack->colorAllocate( 255, 255, 255 );
    $white = $imgyellow->colorAllocate( 255, 255, 255 );
    $white = $imgblue->colorAllocate( 255, 255, 255 );
    $white = $imgmarsh->colorAllocate( 255, 255, 255 );
    $white = $imgblacktop->colorAllocate( 255, 255, 255 );
    $white = $imgbrowntop->colorAllocate( 255, 255, 255 );

    $black = $imgblacktop->colorAllocate( 0, 0, 0 );
    $black = $imgbrown->colorAllocate( 0, 0, 0 );
    $black = $imgblack->colorAllocate( 0, 0, 0 );
    $black = $imgbrowntop->colorAllocate( 0,   0,   0 );
    $brown = $imgblacktop->colorAllocate( 255, 150, 80 );
    $brown = $imgbrown->colorAllocate( 255, 150, 80 );
    $brown = $imgbrowntop->colorAllocate( 255, 150, 80 );

    ( $buildingr, $buildingg, $buildingb ) = split( /\,/, $buildingcolor );
    $purple = $imgblack->colorAllocate( 1 * $buildingr, 1 * $buildingg,
        1 * $buildingb );

    $yellow = $imgyellow->colorAllocate( 255, 184, 83 );
    $browny = $imgyellow->colorAllocate( 255, 150, 80 );
    $blue   = $imgblue->colorAllocate( 29, 190, 255 );
    $blue   = $imgmarsh->colorAllocate( 29, 190, 255 );
    $marsh  = $imgblue->colorAllocate( 0, 10, 220 );
    $marsh  = $imgmarsh->colorAllocate( 0, 10, 220 );

    $olive    = $imgyellow->colorAllocate( 194, 176, 33 );
    $imgblue2 = new GD::Image( $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor );

    opendir( DIR, "temp$thread" );
    @d = grep { /.*?.shp$/i } readdir(DIR);
    closedir DIR;

    foreach $file (@d) {
        chomp($file);
        $file   = "temp$thread/$file";
        $delshp = $file;                 # $delshp = "temp$thread/" . $file;
        $file =~ s/\.shp$//;

        # $file = "temp$thread/" . $file;

        #print "$file \n";
        if ( $file =~ /\_\_MACOSX/i ) {

            # macosx crap
        }
        else {
            $esfile = Geo::ShapeFile->new($file);

            #print "$file\n";
            &drawshape;
        }
        undef $esfile;
        unlink $delshp;
        $delshp =~ s/\.shp$/\.dbf/i;
        unlink $delshp;
        $delshp =~ s/\.dbf$/\.sbx/i;
        unlink $delshp;
        $delshp =~ s/\.sbx$/\.prj/i;
        unlink $delshp;
        $delshp =~ s/\.prj$/\.shx/i;
        unlink $delshp;
        $delshp =~ s/\.shx$/\.sbn/i;
        unlink $delshp;
    }

    ## erase lake jumpline artifacts

    $white = $imgblue2->colorAllocate( 255, 255, 255 );
    $imgblue2->copy(
        $imgblue, 0, 0, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor
    );

    $imgblue->transparent($blue);
    $imgblue2->copy(
        $imgblue, 1, 0, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor
    );
    $imgblue2->copy(
        $imgblue, 0, 1, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor
    );
    $imgblue->copy(
        $imgblue2, 0, 0, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor
    );
    $imgblue->transparent(-1);

## marsh stripes
    for ( $i = 0 ; $i < $h * 600 / 254 / $scalefactor + 500 ; $i = $i + 14 ) {
        $imgmarsh->filledRectangle( -1, $i, $w * 600 / 254 / $scalefactor + 2,
            $i + 10, $white );
    }

    $imgmarsh->transparent($white);

    #$imgyellow->transparent($white);
    #$imgblue->transparent($white);
    $imgblack->transparent($white);
    $imgbrown->transparent($white);

    $transp = $imgtempblacktop->colorClosest( 255, 255, 255 );
    $imgtempblacktop->transparent($transp);
    $imgblacktop->copy(
        $imgtempblacktop, 0, 0, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor
    );

    $transp = $imgtempblack->colorClosest( 255, 255, 255 );
    $imgtempblack->transparent($transp);
    $imgblack->copy(
        $imgtempblack, 0, 0, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor
    );

    $imgblacktop->transparent($white);
    $imgbrowntop->transparent($white);

    #$img2->copy($imgyellow,0,0,0,0,$w * 600 / 254, $h * 600 / 254);
    $imgyellow->copy(
        $imgmarsh, 0, 0, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor
    );

    #$img2->copy($imgblue,0,0,0,0,$w * 600 / 254, $h * 600 / 254);
    $imgblue->copy(
        $imgblack, 0, 0, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor
    );
    $imgblue->copy(
        $imgbrown, 0, 0, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor
    );
    $imgblue->copy(
        $imgblacktop, 0, 0, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor
    );
    $imgblue->copy(
        $imgbrowntop, 0, 0, 0, 0,
        $w * 600 / 254 / $scalefactor,
        $h * 600 / 254 / $scalefactor
    );

    if ( -e $tempfolder . 'low.png' ) {
        $low    = newFromPng GD::Image( $tempfolder . 'low.png' );
        $transp = $low->colorClosest( 255, 255, 255 );
        $low->transparent($transp);
        $imgyellow->copy(
            $low, 0, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );

        $high   = newFromPng GD::Image( $tempfolder . 'high.png' );
        $transp = $high->colorClosest( 255, 255, 255 );
        $high->transparent($transp);
        $imgblue->copy(
            $high, 0, 0, 0, 0,
            $w * 600 / 254 / $scalefactor,
            $h * 600 / 254 / $scalefactor
        );
    }

    open( IMAGE, ">" . $tempfolder . 'low.png' );

    binmode IMAGE;

    #      Convert the image to PNG and print it on standard output
    print IMAGE $imgyellow->png;
    close IMAGE;

    open( IMAGE, ">" . $tempfolder . 'high.png' );

    binmode IMAGE;

    #      Convert the image to PNG and print it on standard output
    print IMAGE $imgblue->png;
    close IMAGE;

## tiet polut

}

sub drawshape {

    if ( $vectorconf ne '' ) {

        open( SISAAN, "<$vectorconf" );
        @vectorconf = <SISAAN>;
        close(SISAAN);
    }

    for ( 1 .. $esfile->shapes() ) {
        $shprec     = $esfile->get_shp_record($_);
        %dbfrec_org = $esfile->get_dbf_record($_);
        undef %dbfrec;

        for ( keys %dbfrec_org ) {
            $dbfrec{ trim($_) } = $dbfrec_org{$_};
        }

        #print "#$_#$dbfrec{$_}#\n" for (keys %dbfrec);
##
        $roadedge  = 0;
        $vari      = '';
        $edgeimage = 'black';
        $thickness = 1;

        $dashedline = 0;
        if ( $vectorconf eq '' ) {

            # oja
            if ( $dbfrec{'LUOKKA'} eq '36311' || $dbfrec{'LUOKKA'} eq '36312' )
            {
                $imgblue->setThickness(5);
                $thickness = 4;
                $vari      = $marsh;
                $image     = 'blue';
            }

            if ( $dbfrec{'LUOKKA'} eq '12316' && $dbfrec{'VERSUH'} != -11 ) {
                $thickness  = 12;
                $vari       = gdStyled;
                $dashedline = 1;
                $image      = 'black';
                if ( $dbfrec{'VERSUH'} > 0 ) {
                    $image = 'blacktop';
                }
            }

            if (
                (
                       $dbfrec{'LUOKKA'} eq '12141'
                    || $dbfrec{'LUOKKA'} eq '12314'
                )
                && $dbfrec{'VERSUH'} != -11
              )
            {
                $imgblack->setThickness(12);
                $thickness = 12;
                $vari      = $black;
                $image     = 'black';
                if ( $dbfrec{'VERSUH'} > 0 ) {
                    $image = 'blacktop';
                }
            }

            if (
                (
                       $dbfrec{'LUOKKA'} eq '12111'
                    || $dbfrec{'LUOKKA'} eq '12112'
                    || $dbfrec{'LUOKKA'} eq '12121'
                    || $dbfrec{'LUOKKA'} eq '12122'
                    || $dbfrec{'LUOKKA'} eq '12131'
                    || $dbfrec{'LUOKKA'} eq '12132'
                )
                && $dbfrec{'VERSUH'} != -11
              )
            {

                $imgbrown->setThickness(20);
                $imgbrowntop->setThickness(20);
                $vari      = $brown;
                $image     = 'brown';
                $roadedge  = 26;
                $thickness = 20;
                $imgblack->setThickness(26);

                if ( $dbfrec{'VERSUH'} > 0 ) {
                    $edgeimage = 'blacktop';
                    $imgbrown->setThickness(14);
                    $imgbrowntop->setThickness(14);
                    $vari      = $brown;
                    $image     = 'brown';
                    $roadedge  = 26;
                    $thickness = 14;
                    $imgblack->setThickness(26);
                }

            }

            # railroad
            $options = " 14110 14111 14112 14121 14131 ";
            $search  = ' ' . $dbfrec{'LUOKKA'} . ' ';
            if ( $options =~ /$search/ && $dbfrec{'VERSUH'} != -11 ) {
                $vari      = $white;
                $image     = 'black';
                $roadedge  = 18;
                $thickness = 3;
                if ( $dbfrec{'VERSUH'} > 0 ) {
                    $image     = 'blacktop';
                    $edgeimage = 'blacktop';
                }

            }

            if ( $dbfrec{'LUOKKA'} eq '12312' && $dbfrec{'VERSUH'} != -11 ) {
                $dashedline = 1;
                $imgblack->setThickness(6);
                $thickness = 6;
                $thickness = 6;
                $vari      = gdStyled;
                if ( $dbfrec{'VERSUH'} > 0 ) {
                    $image = 'blacktop';

                }
                $image = 'black';
            }
            if ( $dbfrec{'LUOKKA'} eq '12313' && $dbfrec{'VERSUH'} != -11 ) {
                $dashedline = 1;
                $thickness  = 6;
                $imgblack->setThickness(6);
                $thickness = 5;
                $vari      = gdStyled;
                $image     = 'black';
                if ( $dbfrec{'VERSUH'} > 0 ) {
                    $image = 'blacktop';
                }
            }

            $border  = 0;
            $area    = 0;
            $stripes = 0;
            if ( $dbfrec{'LUOKKA'} eq '32611' ) {
                $area   = 1;
                $vari   = $yellow;
                $border = 3;
                $image  = 'yellow';
            }

            #lake
            $options = " 36200 36211 36313 38700 44300 44300 45111 45112 ";
            $search  = ' ' . $dbfrec{'LUOKKA'} . ' ';
            if ( $options =~ /$search/ ) {
                $area   = 1;
                $vari   = $blue;
                $border = 5;
                $image  = 'blue';
            }

            #impassable marsh
            $options = " 35421 38300";
            $search  = ' ' . $dbfrec{'LUOKKA'} . ' ';
            if ( $options =~ /$search/ ) {
                $area    = 1;
                $vari    = $marsh;
                $border  = 0;
                $stripes = 1;
                $image   = 'marsh';
            }

            #regular marsh
            $options = " 35400 35411 35422 ";
            $search  = ' ' . $dbfrec{'LUOKKA'} . ' ';
            if ( $options =~ /$search/ ) {
                $area    = 1;
                $vari    = $marsh;
                $border  = 0;
                $stripes = 1;
                $image   = 'marsh';
            }

            #marshish
            $options = " 35300 35412 35422 ";
            $search  = ' ' . $dbfrec{'LUOKKA'} . ' ';
            if ( $options =~ /$search/ ) {
                $area    = 1;
                $vari    = $marsh;
                $border  = 0;
                $stripes = 1;
                $image   = 'marsh';
            }

            #building
            $options =
" 42210 42211 42212 42220 42221 42222 42230 42231 42232 42240 42241 42242 42270 42250 42251 42252 42260 42261 42262 ";
            $search = ' ' . $dbfrec{'LUOKKA'} . ' ';
            if ( $options =~ /$search/ ) {
                $area   = 1;
                $vari   = $purple;
                $border = 0;
                $image  = 'black';
            }

            #power line
            $options = " 22300 22312 44500 22311 ";
            $search  = ' ' . $dbfrec{'LUOKKA'} . ' ';
            if ( $options =~ /$search/ ) {
                $imgblacktop->setThickness(5);
                $thickness = 5;
                $area      = 0;
                $vari      = $black;
                $border    = 0;
                $image     = 'blacktop';
            }

            # fence
            $options = " 44211 44213 ";
            $search  = ' ' . $dbfrec{'LUOKKA'} . ' ';
            if ( $options =~ /$search/ ) {
                $imgblacktop->setThickness(7);
                $thickness = 7;
                $area      = 0;
                $vari      = $black;
                $border    = 0;
                $image     = 'blacktop';
            }

            # settlement
            $options =
" 32000 hautausmaa, 40200 taajaan rakennettu alue, 62100 ampuma-alueen reunaviiva alaluokkiin) 32410  32411 32412 32413 32414 32415 32416 32417 32418";
            $search = ' ' . $dbfrec{'LUOKKA'} . ' ';
            if ( $options =~ /$search/ ) {
                $area   = 1;
                $vari   = $olive;
                $border = 0;
                $image  = 'yellow';
            }

            # airport runway, car parking area
            $options = " 32411 32412 32415 32417 32421 ";
            $search  = ' ' . $dbfrec{'LUOKKA'} . ' ';
            if ( $options =~ /$search/ ) {
                $area   = 1;
                $vari   = $browny;
                $border = 0;
                $image  = 'yellow';
            }
            $search = ',' . $dbfrec{'LUOKKA'} . ',';
            $search =~ s/ //g;

            if ( $mtkskip =~ /$search/ ) {
                $vari = '';
            }

        }
        else {
            ## configuration based rendering

            for $confrow (@vectorconf) {
                chomp($confrow);
                ( $comment, $ISOMcode, $cond ) = split( /\|/, $confrow );
                $ISOMcode = &trim($ISOMcode);
                @ehdot    = split( /\&/, $cond );

                foreach $ehto (@ehdot) {

                    $ehtoname  = '';
                    $ehtovalue = '';

                    if ( $ehto =~ /\!\=/ ) {
                        ( $ehtoname, $ehtovalue ) = split( /\!\=/, $ehto, 2 );
                        $operator = '!=';
                    }
                    else {
                        ( $ehtoname, $ehtovalue ) = split( /\=/, $ehto, 2 );
                        $operator = '=';
                    }
                    $ehtoname  = &trim($ehtoname);
                    $ehtovalue = &trim($ehtovalue);
                    $ehto      = $operator . '|' . $ehtoname . '|' . $ehtovalue;
                }

                if ( $vari eq '' ) {

                    # oja
                    if ( $ISOMcode eq '306' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $imgblue->setThickness(5);
                            $thickness = 4;
                            $vari      = $marsh;
                            $image     = 'blue';
                        }
                    }

                    # karrypolku
                    if ( $ISOMcode eq '505' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $dashedline = 1;
                            $thickness  = 12;
                            $vari       = gdStyled;
                            $image      = 'black';
                        }
                    }

                    # karrypolku top
                    if ( $ISOMcode eq '505T' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $dashedline = 1;
                            $thickness  = 12;
                            $vari       = gdStyled;
                            $image      = 'black';

                            $image = 'blacktop';

                        }
                    }

                    # mustatie
                    if ( $ISOMcode eq '504' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $imgblack->setThickness(12);
                            $thickness = 12;
                            $vari      = $black;
                            $image     = 'black';
                        }
                    }

                    # mustatie TOP
                    if ( $ISOMcode eq '504T' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $imgblack->setThickness(12);
                            $thickness = 12;
                            $vari      = $black;
                            $image     = 'black';

                            $image = 'blacktop';

                        }
                    }

                    # ruskea tie
                    if ( $ISOMcode eq '503' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {

                            $imgbrown->setThickness(20);
                            $imgbrowntop->setThickness(20);
                            $vari      = $brown;
                            $image     = 'brown';
                            $roadedge  = 26;
                            $thickness = 20;
                            $imgblack->setThickness(26);

                        }
                    }

                    # ruskea tie, silta
                    if ( $ISOMcode eq '503T' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {

                            $imgbrown->setThickness(20);
                            $imgbrowntop->setThickness(20);
                            $vari      = $brown;
                            $image     = 'brown';
                            $roadedge  = 26;
                            $thickness = 20;
                            $imgblack->setThickness(26);
                            $edgeimage = 'blacktop';
                            $imgbrown->setThickness(14);
                            $imgbrowntop->setThickness(14);
                            $vari      = $brown;
                            $image     = 'brown';
                            $roadedge  = 26;
                            $thickness = 14;
                            $imgblack->setThickness(26);

                        }
                    }

                    # rautatie

                    if ( $ISOMcode eq '515' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $vari      = $white;
                            $image     = 'black';
                            $roadedge  = 18;
                            $thickness = 3;

                        }
                    }

                    # rautatie TOP
                    if ( $ISOMcode eq '515T' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $vari      = $white;
                            $image     = 'black';
                            $roadedge  = 18;
                            $thickness = 3;
                            $image     = 'blacktop';
                            $edgeimage = 'blacktop';

                        }
                    }

                    # polku
                    if ( $ISOMcode eq '507' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $dashedline = 1;
                            $thickness  = 6;
                            $imgblack->setThickness(6);
                            $thickness = 6;
                            $vari      = gdStyled;
                            $image     = 'black';
                        }
                    }

                    # polku TOP
                    if ( $ISOMcode eq '507T' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $dashedline = 1;
                            $thickness  = 6;
                            $imgblack->setThickness(6);
                            $thickness = 6;
                            $vari      = gdStyled;
                            $image     = 'black';

                            $image = 'blacktop';

                        }
                    }

                    ## areas
                    $border  = 0;
                    $area    = 0;
                    $stripes = 0;

                    ## pelto
                    if ( $ISOMcode eq '401' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $area   = 1;
                            $vari   = $yellow;
                            $border = 3;
                            $image  = 'yellow';
                        }
                    }

## lake
                    if ( $ISOMcode eq '301' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {

                            $area   = 1;
                            $vari   = $blue;
                            $border = 5;
                            $image  = 'blue';
                        }
                    }

                    # marsh
                    if ( $ISOMcode eq '310' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $area    = 1;
                            $vari    = $marsh;
                            $border  = 0;
                            $stripes = 1;
                            $image   = 'marsh';
                        }
                    }

                    #building
                    if ( $ISOMcode eq '526' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $area   = 1;
                            $vari   = $purple;
                            $border = 0;
                            $image  = 'black';
                        }
                    }

                    #power line
                    if ( $ISOMcode eq '516' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $imgblacktop->setThickness(5);
                            $thickness = 5;
                            $area      = 0;
                            $vari      = $black;
                            $border    = 0;
                            $image     = 'blacktop';
                        }
                    }

                    # fence
                    if ( $ISOMcode eq '524' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $imgblacktop->setThickness(7);
                            $thickness = 7;
                            $area      = 0;
                            $vari      = $black;
                            $border    = 0;
                            $image     = 'black';
                        }
                    }

                    # black line
                    if ( $ISOMcode eq '414' ) {
                        $ok = 1;

                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {

                            $imgblacktop->setThickness(7);
                            $thickness = 4;
                            $area      = 0;
                            $vari      = $black;
                            $border    = 0;
                            $image     = 'black';
                        }
                    }

                    # settlement

                    if ( $ISOMcode eq '527' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $area   = 1;
                            $vari   = $olive;
                            $border = 0;
                            $image  = 'yellow';
                        }
                    }

                    # car parking area

                    if ( $ISOMcode eq '529.1' || $ISOMcode eq '301.1' ) {
                        $ok = 1;

                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {

                            $imgblacktop->setThickness(2);
                            $thickness = 2;
                            $area      = 0;
                            $vari      = $black;
                            $border    = 0;
                            $image     = 'black';
                        }
                    }

                    if ( $ISOMcode eq '529' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $area   = 1;
                            $vari   = $browny;
                            $border = 0;
                            $image  = 'yellow';

                        }

                    }

                    # car parking area TOP
                    if ( $ISOMcode eq '529T' ) {
                        $ok = 1;
                        foreach $ehto (@ehdot) {
                            ( $operator, $ehtoname, $ehtovalue ) =
                              split( /\|/, $ehto, 3 );
                            if ( $operator eq '=' ) {
                                if ( trim( $dbfrec{$ehtoname} ) ne $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                            else {
                                if ( trim( $dbfrec{$ehtoname} ) eq $ehtovalue )
                                {
                                    $ok = 0;
                                }
                            }
                        }
                        if ( $ok == 1 ) {
                            $area   = 1;
                            $vari   = $browny;
                            $border = 0;
                            $image  = 'brown';
                        }

                    }

                }
            }
            ## configuration based rendering end
        }

        if ( $vari ne '' ) {

            $rt = 0;
            if ( $area == 1 ) {
                $polyline = new GD::Polyline;
                undef @polylinejump;
                $jumpx = '';
                $jumpy = '';
            }

            for ( 1 .. $shprec->num_parts ) {

                $pisteet =
                  [ map( [ $_->X(), $_->Y() ], $shprec->get_part($_) ) ];
                if ( $area == 0 ) {
                    $polyline = new GD::Polyline;
                }
                $polylineborder = new GD::Polyline;

                # add some points

                $count = 0;
                foreach $pist (@$pisteet) {
                    ( $x, $y ) = @$pist;

                    if ( $jumpx eq '' && $area == 1 ) {
                        $jumpx = 600 / 254 / $scalefactor * ( $x - $x0 );
                        $jumpy = 600 / 254 / $scalefactor * ( $y0 - $y );
                    }
                    if ( $area == 1 && $count == 0 ) {

                        #$polyline->addPt( floor($jumpx), floor($jumpy) );
                        $startx = 600 / 254 / $scalefactor * ( $x - $x0 );
                        $starty = 600 / 254 / $scalefactor * ( $y0 - $y );
                    }

                    $polyline->addPt(
                        floor( 600 / 254 / $scalefactor * ( $x - $x0 ) ),
                        floor( 600 / 254 / $scalefactor * ( $y0 - $y ) )
                    );

                    if ( $area == 1 ) {
                        $polylineborder->addPt(
                            floor( 600 / 254 / $scalefactor * ( $x - $x0 ) ),
                            floor( 600 / 254 / $scalefactor * ( $y0 - $y ) )
                        );
                    }
                    $count++;
                }

                if ( $area == 1 ) {
                    $polyline->addPt( floor($startx), floor($starty) );
                    $polylinejump[ $#polylinejump + 1 ] =
                      '' . floor($startx) . ',' . floor($starty);
                }

                if ( $area == 0 ) {

                    if ( $roadedge > 0 ) {
                        if ( $edgeimage eq 'blacktop' ) {
                            $imgblacktop->setThickness($roadedge);
                            $imgblacktop->polyline( $polyline, $black );
                            $imgblacktop->setThickness($thickness);

   #undef $brush;
   #		$brush = new GD::Image($roadedge+1,$roadedge+1);
   #       $bbg = $brush->colorAllocate(255,255,255);
   #       $bbc = $brush->colorAllocate(0,0,0);
   #       $brush->transparent($bbg);
   #		$brush->filledArc($roadedge/2,$roadedge/2,$roadedge,$roadedge,0,360,$bbc);
   #		  $imgblacktop->setBrush($brush);
   #		  $imgblacktop->setThickness(1);
   #		  $imgblacktop->polyline( $polyline, gdBrushed );
   #$myImage->arc(500,500,700,300,0,360,gdBrushed);
   #$imgblacktop->setThickness(1);
   #$vertex_count =$polyline->length;
   #for($v=0;$v<$vertex_count;$v++){
   #  ($x,$y) = $polyline->getPt($v);
   #		$imgblacktop->filledArc($x,$y,$roadedge,$roadedge,0,360, $black);
   #print "$x,$y\n";
   #	}
   #   $imgblacktop->setThickness($thickness);

                        }
                        else {

                            #$imgblack->setThickness($roadedge);
                            #$imgblack->polyline( $polyline, $black );
                            #$imgblack->setThickness($thickness);
                            undef $brush;
                            $brush =
                              new GD::Image( $roadedge + 1, $roadedge + 1 );
                            $bbg = $brush->colorAllocate( 255, 255, 255 );
                            $bbc = $brush->colorAllocate( 0,   0,   0 );
                            $brush->transparent($bbg);
                            $brush->filledArc(
                                $roadedge / 2,
                                $roadedge / 2,
                                $roadedge - 2,
                                $roadedge - 2,
                                0, 360, $bbc
                            );
                            $imgblack->setBrush($brush);
                            $imgblack->setThickness(1);
                            $imgblack->polyline( $polyline, gdBrushed );

                            # $imgblack->setThickness(1);
                            # $vertex_count = $polyline->length;
                            # for ( $v = 0 ; $v < $vertex_count ; $v++ ) {
                            #     ( $x, $y ) = $polyline->getPt($v);
                            #     $imgblack->filledArc( $x, $y, $roadedge,
                            #         $roadedge, 0, 360, $black );

                            #print "$x,$y\n";
                            # }
                            # $imgblack->setThickness($thickness);

                        }

                    }

                    if ( $dashedline == 0 ) {
                        if ( $image eq 'blacktop' ) {
                            if ( $thickness < 9 ) {
                                $imgblacktop->setThickness($thickness);
                                $imgblacktop->polyline( $polyline, $black );
                            }
                            else {
                                undef $brush;
                                $brush = new GD::Image( $thickness + 1,
                                    $thickness + 1 );
                                $bbg = $brush->colorAllocate( 255, 255, 255 );
                                $bbc = $brush->colorAllocate( 0,   0,   0 );
                                $brush->transparent($bbg);
                                $brush->filledArc(
                                    $thickness / 2,
                                    $thickness / 2,
                                    $thickness - 2,
                                    $thickness - 2,
                                    0, 360, $bbc
                                );
                                $imgblacktop->setBrush($brush);
                                $imgblacktop->setThickness(1);
                                $imgblacktop->polyline( $polyline, gdBrushed );

                            }

                   #                     $imgblacktop->setThickness($thickness);

                        }

                        if ( $image eq 'black' ) {
                            if ( $thickness < 9 ) {
                                $imgblack->setThickness($thickness);
                                $imgblack->polyline( $polyline, $black );
                            }
                            else {

                                undef $brush;
                                $brush = new GD::Image( $thickness + 1,
                                    $thickness + 1 );
                                $bbg = $brush->colorAllocate( 255, 255, 255 );
                                $bbc = $brush->colorAllocate( 0,   0,   0 );
                                $brush->transparent($bbg);
                                $brush->filledArc(
                                    $thickness / 2,
                                    $thickness / 2,
                                    $thickness - 2,
                                    $thickness - 2,
                                    0, 360, $bbc
                                );
                                $imgblack->setBrush($brush);
                                $imgblack->setThickness(1);
                                $imgblack->polyline( $polyline, gdBrushed );

                            }
                        }
                    }
                    else {

                        if ( $image eq 'blacktop' ) {
                            $dashgap = 1 + $thickness * 8;

                            if ( $thickness < 9 ) {
                                $imgtempblacktop->setThickness($thickness);
                                $imgtempblacktop->polyline( $polyline, $black );
                            }
                            else {
                                undef $brush;
                                $brush = new GD::Image( $thickness + 1,
                                    $thickness + 1 );
                                $bbg = $brush->colorAllocate( 255, 255, 255 );
                                $bbc = $brush->colorAllocate( 0,   0,   0 );
                                $brush->transparent($bbg);
                                $brush->filledArc(
                                    $thickness / 2,
                                    $thickness / 2,
                                    $thickness - 2,
                                    $thickness - 2,
                                    0, 360, $bbc
                                );
                                $imgtempblacktop->setBrush($brush);
                                $imgtempblacktop->setThickness(1);
                                $imgtempblacktop->polyline( $polyline,
                                    gdBrushed );

                            }
                            $dist         = 0;
                            $stroke       = $dashgap;
                            $vertex_count = $polyline->length;
                            for ( $v = 0 ; $v < $vertex_count ; $v++ ) {
                                ( $x, $y ) = $polyline->getPt($v);

#if($v==0 || $v==$vertex_count-1){
#$imgtempblacktop->filledArc( $x, $y, $thickness*.7,$thickness*.7, 0, 360, $tempwhite );
#}
                                if ( $v > 0 ) {
                                    $dist =
                                      sqrt( ( $x - $prex ) * ( $x - $prex ) +
                                          ( $y - $prey ) * ( $y - $prey ) );
                                    while ( $dist > $stroke ) {
                                        $xb =
                                          ( $stroke * $x +
                                              ( $dist - $stroke ) * $prex ) /
                                          $dist;
                                        $yb =
                                          ( $stroke * $y +
                                              ( $dist - $stroke ) * $prey ) /
                                          $dist;
                                        if ( $yb == $prey ) {
                                            $yb = $yb + 0.01;
                                        }
                                        if ( $xb == $prex ) {
                                            $xb = $xb + 0.01;
                                        }

                                        $angle = atan(
                                            ( $yb - $prey ) / ( $xb - $prex ) )
                                          - 3.14159265358 / 2;
                                        if (   $v == $vertex_count - 1
                                            && $dist < $dashgap * 1.8 )
                                        {

                                            # skip
                                        }
                                        else {

                                            $imgtempblacktop->setThickness(
                                                4 + $thickness * 0.6 );
                                            $imgtempblacktop->line(
                                                $xb -
                                                  cos($angle) * $thickness * .8,
                                                $yb -
                                                  sin($angle) * $thickness * .8,
                                                $xb +
                                                  cos($angle) * $thickness * .8,
                                                $yb +
                                                  sin($angle) * $thickness * .8,
                                                $tempwhite
                                            );

                                        }

                                        ( $prex, $prey ) = ( $xb, $yb );

                                        #print "$xb, $yb \n";
                                        $dist   = $dist - $stroke;
                                        $stroke = $dashgap;
                                    }
                                    $stroke = $stroke - $dist;
                                }
                                ( $prex, $prey ) = ( $x, $y );
                            }
                            $imgtempblack->setThickness($thickness);
                        }
                        if ( $image eq 'black' ) {
                            $dashgap = 1 + $thickness * 8;
                            if ( $thickness < 9 ) {
                                $imgtempblack->setThickness($thickness);
                                $imgtempblack->polyline( $polyline, $black );
                            }
                            else {

                                undef $brush;
                                $brush = new GD::Image( $thickness + 1,
                                    $thickness + 1 );
                                $bbg = $brush->colorAllocate( 255, 255, 255 );
                                $bbc = $brush->colorAllocate( 0,   0,   0 );
                                $brush->transparent($bbg);
                                $brush->filledArc(
                                    $thickness / 2,
                                    $thickness / 2,
                                    $thickness - 2,
                                    $thickness - 2,
                                    0, 360, $bbc
                                );
                                $imgtempblack->setBrush($brush);
                                $imgtempblack->setThickness(1);
                                $imgtempblack->polyline( $polyline, gdBrushed );
                            }
                            $dist         = 0;
                            $stroke       = $dashgap;
                            $vertex_count = $polyline->length;
                            for ( $v = 0 ; $v < $vertex_count ; $v++ ) {
                                ( $x, $y ) = $polyline->getPt($v);

#if($v==0 || $v==$vertex_count-1){
#$imgtempblack->filledArc( $x, $y, $thickness*.7,$thickness*.7, 0, 360, $tempwhite );
#}
                                if ( $v > 0 ) {
                                    $dist =
                                      sqrt( ( $x - $prex ) * ( $x - $prex ) +
                                          ( $y - $prey ) * ( $y - $prey ) );
                                    while ( $dist > $stroke ) {
                                        $xb =
                                          ( $stroke * $x +
                                              ( $dist - $stroke ) * $prex ) /
                                          $dist;
                                        $yb =
                                          ( $stroke * $y +
                                              ( $dist - $stroke ) * $prey ) /
                                          $dist;
                                        if ( $yb == $prey ) {
                                            $yb = $yb + 0.01;
                                        }
                                        if ( $xb == $prex ) {
                                            $xb = $xb + 0.01;
                                        }

                                        $angle = atan(
                                            ( $yb - $prey ) / ( $xb - $prex ) )
                                          - 3.14159265358 / 2;
                                        if (   $v == $vertex_count - 1
                                            && $dist < $dashgap * 1.8 )
                                        {

                                            # skip
                                        }
                                        else {

                                            $imgtempblack->setThickness(
                                                4 + $thickness * 0.6 );
                                            $imgtempblack->line(
                                                $xb -
                                                  cos($angle) * $thickness * .8,
                                                $yb -
                                                  sin($angle) * $thickness * .8,
                                                $xb +
                                                  cos($angle) * $thickness * .8,
                                                $yb +
                                                  sin($angle) * $thickness * .8,
                                                $tempwhite
                                            );

                                        }

                                        ( $prex, $prey ) = ( $xb, $yb );

                                        #print "$xb, $yb \n";
                                        $dist   = $dist - $stroke;
                                        $stroke = $dashgap;
                                    }
                                    $stroke = $stroke - $dist;
                                }
                                ( $prex, $prey ) = ( $x, $y );
                            }
                            $imgtempblack->setThickness($thickness);
                        }

#					 if ( $image eq 'blacktop' ) {
#					        $transp = $imgtempblack->colorClosest( 255, 255, 255 );
#							$imgtempblack->transparent($transp);
#                            $imgblacktop->copy( $imgtempblack, 0, 0, 0, 0, $w * 600 / 254, $h * 600 / 254 );
#					 }
#					if ( $image eq 'black' ) {
#                            $transp = $imgtempblack->colorClosest( 255, 255, 255 );
#							$imgtempblack->transparent($transp);
#                            $imgblack->copy( $imgtempblack, 0, 0, 0, 0, $w * 600 / 254, $h * 600 / 254 );
#					 }

                    }
                    if ( $image eq 'blue' ) {
                        $imgblue->polyline( $polyline, $vari );

                    }
                    if ( $image eq 'brown' ) {
                        if ( $edgeimage eq 'blacktop' ) {

                            #$imgbrowntop->polyline( $polyline, $vari );
                            $brush =
                              new GD::Image( $thickness + 1, $thickness + 1 );
                            $bbg = $brush->colorAllocate( 255, 255, 255 );
                            $bbc = $brush->colorAllocate( 255, 150, 80 );
                            $brush->transparent($bbg);
                            $brush->filledArc(
                                $thickness / 2,
                                $thickness / 2,
                                $thickness - 2,
                                $thickness - 2,
                                0, 360, $bbc
                            );
                            $imgbrowntop->setBrush($brush);
                            $imgbrowntop->setThickness(1);
                            $imgbrowntop->polyline( $polyline, gdBrushed );

                            #$imgbrowntop->setThickness(1);

                            #$vertex_count = $polyline->length;
                            #for ( $v = 0 ; $v < $vertex_count ; $v++ ) {
                            #   ( $x, $y ) = $polyline->getPt($v);
                            #  $imgbrowntop->filledArc( $x, $y, $thickness,
                            #      $thickness, 0, 360, $vari );

                            #print "$x,$y\n";
                            #}

                            $imgbrowntop->setThickness($thickness);

                        }
                        else {

                            #$imgbrown->polyline( $polyline, $vari );
                            $brush =
                              new GD::Image( $thickness + 1, $thickness + 1 );
                            $bbg = $brush->colorAllocate( 255, 255, 255 );
                            $bbc = $brush->colorAllocate( 255, 150, 80 );
                            $brush->transparent($bbg);
                            $brush->filledArc(
                                $thickness / 2,
                                $thickness / 2,
                                $thickness - 2,
                                $thickness - 2,
                                0, 360, $bbc
                            );
                            $imgbrown->setBrush($brush);
                            $imgbrown->setThickness(1);
                            $imgbrown->polyline( $polyline, gdBrushed );

                            #    $imgbrown->setThickness(1);

                            #   $vertex_count = $polyline->length;
                            #  for ( $v = 0 ; $v < $vertex_count ; $v++ ) {
                            #      ( $x, $y ) = $polyline->getPt($v);
                            #      $imgbrown->filledArc( $x, $y, $thickness,
                            #          $thickness, 0, 360, $vari );

                            #print "$x,$y\n";
                            # }

                            $imgbrown->setThickness($thickness);

                        }
                    }
                }
                else {
                    if ( $border > 0 ) {
                        $imgblack->setThickness($border);
                        $imgblack->polyline( $polylineborder, $black );

                    }
                }

                $rt++;
            }

            if ( $area == 1 ) {

                for ( $l = $#polylinejump ; $l > 0 ; $l = $l - 1 ) {
                    ( $x, $y ) = split( /\,/, $polylinejump[$l] );
                    $polyline->addPt( $x, $y );
                }
                if ( $image eq 'black' ) {
                    $imgblack->setThickness(1);
                    $imgblack->filledPolygon( $polyline, $vari );
                }
                if ( $image eq 'blue' ) {
                    $imgblue->setThickness(1);
                    $imgblue->filledPolygon( $polyline, $vari );
                }
                if ( $image eq 'yellow' ) {
                    $imgyellow->setThickness(1);
                    $imgyellow->filledPolygon( $polyline, $vari );
                }
                if ( $image eq 'marsh' ) {
                    $imgmarsh->setThickness(1);
                    $imgmarsh->filledPolygon( $polyline, $vari );
                }
                if ( $image eq 'brown' ) {
                    $imgbrown->setThickness(1);
                    $imgbrown->filledPolygon( $polyline, $vari );
                }
            }
##

##

        }
    }

}

sub kaksataa() {

    $x1 = floor( $x1 * 100 ) / 100;
    $x2 = floor( $x2 * 100 ) / 100;
    $y1 = floor( $y1 * 100 ) / 100;
    $y2 = floor( $y2 * 100 ) / 100;
    if ( $x1 == $x2 && $y1 == $y2 ) {

        #ei mitaan
    }
    else {

        $ob++;
        if ( $kayra{ $x1 . "_" . $y1 . "_1" } eq "" ) {
            $kayra{ $x1 . "_" . $y1 . "_1" } = $x2 . "_" . $y2;
            $ka[$ob] = $x1 . "_" . $y1 . "_1";
        }
        else {
            $kayra{ $x1 . "_" . $y1 . "_2" } = $x2 . "_" . $y2;
            $ka[$ob] = $x1 . "_" . $y1 . "_2";
        }
        $ob++;
        if ( $kayra{ $x2 . "_" . $y2 . "_1" } eq "" ) {
            $kayra{ $x2 . "_" . $y2 . "_1" } = $x1 . "_" . $y1;
            $ka[$ob] = $x2 . "_" . $y2 . "_1";
        }
        else {
            $kayra{ $x2 . "_" . $y2 . "_2" } = $x1 . "_" . $y1;
            $ka[$ob] = $x2 . "_" . $y2 . "_2";
        }

    }
    $ob = $ob + 1;
}

sub polylinedxfcrop() {

    $out = '';

    $d = join( '', @d );

    @d = split( /POLYLINE/, $d );

    if ( $mydxfhead eq '' ) {
        $mydxfhead = $d[0];
    }

    $out = $mydxfhead;

    $j   = 0;
    $pre = '';
    foreach $rec (@d) {
        $poly       = '';
        $pre        = '';
        $pointcount = 0;
        $j++;
        if ( $j > 1 ) {
            ( $head, $rec ) = split( /VERTEX/, $rec, 2 );
            @r    = split( /VERTEX/, $rec );
            $poly = 'POLYLINE' . $head;
            foreach $apu (@r) {
                ( $apu, $pois ) = split( /SEQEND/, $apu, 2 );
                @val = split( /\n/, $apu );
                $i   = 0;
                foreach $v (@val) {
                    chomp($v);
                    if ( $v eq ' 10' ) {
                        $xline = $i + 1;
                    }
                    if ( $v eq ' 20' ) {
                        $yline = $i + 1;
                    }
                    $i++;
                }
                if (   $val[$xline] >= $minx
                    && $val[$xline] <= $maxx
                    && $val[$yline] >= $miny
                    && $val[$yline] <= $maxy )
                {
                    if (   $pre ne ''
                        && $pointcount == 0
                        && ( $prex < $minx || $prey < $miny ) )
                    {
                        $poly .= 'VERTEX' . $pre;
                        $pointcount++;

                    }

                    $poly .= 'VERTEX' . $apu;
                    $pointcount++;
                }
                else {
                    if ( $pointcount > 1 ) {
                        if ( $val[$xline] < $minx || $val[$yline] < $miny ) {
                            $poly .= 'VERTEX' . $apu;
                        }
                        if ( $poly =~ /SEQEND/ ) {
                        }
                        else {
                            $poly .= "SEQEND
  0\n";
                        }
                        $out .= $poly;
                        $poly       = 'POLYLINE' . $head;
                        $pointcount = 0;

                    }
                }
                $pre  = $apu;
                $prex = $val[$xline];
                $prey = $val[$yline];

            }
            if ( $poly =~ /SEQEND/ ) {
            }
            else {
                $poly .= "SEQEND
  0\n";
            }

            if ( $pointcount > 1 ) {
                $out .= $poly;
            }
        }

    }

    if ( $out =~ /EOF/ ) {

    }
    else {
        $out .= 'ENDSEC
  0
EOF
';
    }
}
sub median { $_[0]->[ @{ $_[0] } / 2 ] }

sub trim {
    ( my $s = $_[0] ) =~ s/^\s+|\s+$//g;
    return $s;
}
