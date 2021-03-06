#!/usr/bin/perl -w
use strict;
use base "y2logsstep";
use testapi;

# add a new primary partition
#   $type == 3 => 0xFD Linux RAID
sub addpart($$) {
    my ( $size, $type ) = @_;
    send_key $cmd{addpart};
    wait_idle 5;
    send_key $cmd{"next"};
    wait_idle 5;

    # the input point at the head of the lineedit, move it to the end
    if ( get_var("GNOME") ) { send_key "end" }
    for ( 1 .. 10 ) {
        send_key "backspace";
    }
    type_string $size . "mb";
    wait_idle 5;
    send_key $cmd{"next"};
    assert_screen 'partition-role', 6;
    send_key "alt-a";    # Raw Volume
    send_key $cmd{"next"};
    wait_idle 5;
    send_key $cmd{"donotformat"};
    wait_idle 5;
    send_key "tab";
    wait_idle 5;

    for ( 1 .. $type ) {
        wait_idle 5;
        send_key "down";
    }
    wait_idle 5;
    send_key $cmd{finish};
}

sub addraid($;$) {
    my ( $step, $chunksize ) = @_;
    send_key "spc";
    for ( 1 .. 3 ) {
        for ( 1 .. $step ) {
            send_key "ctrl-down";
        }

        # in GNOME Live case, press space will direct added this item
        if ( get_var("GNOME") ) {
            send_key "ctrl-spc";
        }
        else {
            send_key "spc";
        }
    }

    # add
    send_key $cmd{"add"};
    wait_idle 3;
    send_key $cmd{"next"};
    wait_idle 3;

    # chunk size selection
    if ($chunksize) {

        # workaround for gnomelive with chunksize 64kb
        if ( get_var("GNOME") ) {
            send_key "alt-c";
            send_key "home";
            for ( 1 .. 4 ) {
                send_key "down";
            }
        }
        else {
            type_string "\t$chunksize";
        }
    }
    send_key $cmd{"next"};
    assert_screen 'partition-role', 6;
    send_key "alt-o";    # Operating System
    send_key $cmd{"next"};
    wait_idle 3;
}

sub setraidlevel($) {
    my $level = shift;
    my %entry = ( 0 => 0, 1 => 1, 5 => 5, 6 => 6, 10 => 'g' );
    send_key "alt-$entry{$level}";

    send_key "alt-i";    # move to RAID name input field
    send_key "tab";      # skip RAID name input field
}

sub run() {

    # create partitioning
    send_key $cmd{createpartsetup};
    assert_screen 'createpartsetup', 3;

    # user defined
    send_key $cmd{custompart};
    send_key $cmd{"next"}, 1;
    assert_screen 'custompart', 9;

    send_key "tab";
    send_key "down";    # select disks
    # seems GNOME tree list didn't eat right arrow key
    if ( get_var("GNOME") ) {
        send_key "spc";    # unfold disks
    }
    else {
        send_key "right";    # unfold disks
    }
    send_key "down";         # select first disk
    wait_idle 5;

    for ( 1 .. 4 ) {
        wait_idle 5;
        addpart( 300, 2 );    # boot
        wait_idle 5;
        addpart( 5300, 2 );    # root
        wait_idle 5;
        addpart( 100, 2 );     # swap
        assert_screen 'raid-partition', 5;

        # select next disk
        send_key "shift-tab";
        send_key "shift-tab";

        # walk through sub-tree
        if ( get_var("GNOME") ) {
            for ( 1 .. 3 ) { send_key "down" }
        }
        send_key "down";
    }

    # select RAID add
    send_key $cmd{addraid};
    wait_idle 4;

    setraidlevel( get_var("RAIDLEVEL") );
    send_key "down";    # start at second partition (i.e. sda2)
    # in this case, press down key doesn't move to next one but itself
    if ( get_var("GNOME") ) { send_key "down" }
    addraid( 3, 6 );

    # workaround for gnomelive, double alt-f available in same page
    if ( get_var("GNOME") ) {
        send_key "spc";
    }
    else {
        send_key $cmd{"finish"};
    }
    wait_idle 3;

    # select RAID add
    send_key $cmd{addraid};
    wait_idle 4;
    setraidlevel(1);    # RAID 1 for /boot
    addraid(2);

    send_key "alt-s";    # change filesystem to FAT for /boot
    for ( 1 .. 3 ) {
        send_key "down";    # select Ext4
    }

    send_key $cmd{"mountpoint"};
    for ( 1 .. 3 ) {
        send_key "down";
    }
    send_key $cmd{"finish"};

    # workaround for gnomelive, double alt-f available in same page
    if ( get_var("GNOME") ) {
        send_key $cmd{"finish"};
        send_key "spc";
    }
    wait_idle 3;

    # select RAID add
    send_key $cmd{addraid};
    wait_idle 4;
    setraidlevel(0);    # RAID 0 for swap
    addraid(1);

    # select file-system
    send_key $cmd{filesystem};
    send_key "end";     # swap at end of list
    send_key $cmd{"finish"};
    wait_idle 3;

    # done
    send_key $cmd{"accept"};

    # skip subvolumes shadowed warning
    if ( check_screen 'subvolumes-shadowed', 5 ) {
        send_key 'alt-y';
    }
    assert_screen 'acceptedpartitioning', 6;
}


1;
# vim: set sw=4 et:
