#!/bin/bash

#
# this file is designed to be sourced into your current shell like this:
#
# source ./func.sh
#
# and then used like this:
#
# $ arduincmd G1 X100
# $ arduinocmd M250
#
# {X:4200,Y:0,Z:0,E:0,F:300,c:19334400}
# {X:4200,Y:0,Z:0,E:0,F:300,c:0}
# Q1/1E
# $ readsym_uint8 mb_head
# 1
# $ readsym_target startpoint
# X: 2100
# Y: 0
# Z: 0
# E: 0
# F: 300
# $ readsym_mb
# [0] {
#         eX: 0   eY: 0   eZ: 0   eE: 0   eF: 0
#         flags: 0
#         dX: 0   dY: 0   dZ: 0   dE: 0
#         cX: 0   cY: 0   cZ: 0   cE: 0
#         ts: 0
#         c: 0    ec: 0   n: 0
# }
# [HEAD,TAIL:1] {
#         eX: 4200        eY: 0   eZ: 0   eE: 0   eF: 300
#         flags: 120
#         dX: 4200        dY: 0   dZ: 0   dE: 0
#         cX: -2100       cY: -2100       cZ: -2100       cE: -2100
#         ts: 4200
#         c: 19334400     ec: 0   n: 0
# }
# [2] {
#         eX: 0   eY: 0   eZ: 0   eE: 0   eF: 0
#         flags: 0
#         dX: 0   dY: 0   dZ: 0   dE: 0
#         cX: 0   cY: 0   cZ: 0   cE: 0
#         ts: 0
#         c: 0    ec: 0   n: 0
# }
# [3] {
#         eX: 0   eY: 0   eZ: 0   eE: 0   eF: 0
#         flags: 0
#         dX: 0   dY: 0   dZ: 0   dE: 0
#         cX: 0   cY: 0   cZ: 0   cE: 0
#         ts: 0
#         c: 0    ec: 0   n: 0
# }
# [4] {
#         eX: 0   eY: 0   eZ: 0   eE: 0   eF: 0
#         flags: 0
#         dX: 0   dY: 0   dZ: 0   dE: 0
#         cX: 0   cY: 0   cZ: 0   cE: 0
#         ts: 0
#         c: 0    ec: 0   n: 0
# }
# [5] {
#         eX: 0   eY: 0   eZ: 0   eE: 0   eF: 0
#         flags: 0
#         dX: 0   dY: 0   dZ: 0   dE: 0
#         cX: 0   cY: 0   cZ: 0   cE: 0
#         ts: 0
#         c: 0    ec: 0   n: 0
# }
# [6] {
#         eX: 0   eY: 0   eZ: 0   eE: 0   eF: 0
#         flags: 0
#         dX: 0   dY: 0   dZ: 0   dE: 0
#         cX: 0   cY: 0   cZ: 0   cE: 0
#         ts: 0
#         c: 0    ec: 0   n: 0
# }
# [7] {
#         eX: 0   eY: 0   eZ: 0   eE: 0   eF: 0
#         flags: 0
#         dX: 0   dY: 0   dZ: 0   dE: 0
#         cX: 0   cY: 0   cZ: 0   cE: 0
#         ts: 0
#         c: 0    ec: 0   n: 0
# }


mendel_setup() {
	stty 115200 raw ignbrk -hup -echo ixon ixoff < /dev/arduino
}

mendel_cmd() {
	(
		IFS=$' \t\n'
		LN=0
		cmd="$*"
		echo "$cmd" >&3;
		while [ "$REPLY" != "OK" ]
		do
			read -u 3
# 			if [ "$LN" -ne 0 ]
# 			then
				if [ "$REPLY" != "OK" ]
				then
					echo "$REPLY"
				fi
# 			fi
			LN=$(( $LN + 1 ))
		done
	) 3<>/dev/arduino;
}

mendel_cmd_hr() {
	(
		IFS=$' \t\n'
		LN=0
		cmd="$*"
		echo "$cmd" >&3;
		echo "> $cmd"
		while [ "$REPLY" != "OK" ]
		do
			read -u 3
# 			if [ "$LN" -ne 0 ]
# 			then
				echo "< $REPLY"
# 			fi
			LN=$(( $LN + 1 ))
		done
	) 3<>/dev/arduino;
}

mendel_print() {
	( IFS=$'\n'
		for F in "$@"
		do
			for L in $(< $F)
			do
				mendel_cmd_hr "$L"
			done
		done
	)
}

mendel_readsym() {
	(
		IFS=$' \t\n'
		sym=$1
		if [ -n "$sym" ]
		then
			make mendel.sym &>/dev/null
			if egrep -q '\b'$sym'\b' mendel.sym
			then
				ADDR=$(( $(egrep '\b'$sym'\b' mendel.sym | cut -d\  -f1) ))
				SIZE=$(egrep '\b'$sym'\b' mendel.sym | cut -d+ -f2)
				mendel_cmd "M253 S$ADDR P$SIZE"
			else
				echo "unknown symbol: $sym"
			fi
		else
			echo "what symbol?" > /dev/fd/2
		fi
	)
}

mendel_readsym_uint8() {
	sym=$1
	val=$(mendel_readsym $sym)
	perl -e 'printf "%u\n", eval "0x".$ARGV[0]' $val
}

mendel_readsym_int8() {
	sym=$1
	val=$(mendel_readsym $sym)
	perl -e 'printf "%d\n", ((eval "0x".$ARGV[0]) & 0x7F) - (((eval "0x".$ARGV[0]) & 0x80)?0x80:0)' $val
}

mendel_readsym_uint16() {
	sym=$1
	val=$(mendel_readsym $sym)
	perl -e '$ARGV[0] =~ m#(..)(..)# && printf "%u\n", eval "0x$2$1"' $val
}

mendel_readsym_int16() {
	sym=$1
	val=$(mendel_readsym $sym)
	perl -e '$ARGV[0] =~ m#(..)(..)# && printf "%d\n", ((eval "0x$2$1") & 0x7FFF) - (((eval "0x$2$1") & 0x8000)?0x8000:0)' $val
}

mendel_readsym_uint32() {
	sym=$1
	val=$(mendel_readsym $sym)
	perl -e '$ARGV[0] =~ m#(..)(..)(..)(..)# && printf "%u\n", eval "0x$4$3$2$1"' $val
}

mendel_readsym_int32() {
	sym=$1
	val=$(mendel_readsym $sym)
	perl -e '$ARGV[0] =~ m#(..)(..)(..)(..)# && printf "%d\n", eval "0x$4$3$2$1"' $val
}

mendel_readsym_target() {
	sym=$1
	val=$(mendel_readsym "$sym")
	if [ -n "$val" ]
	then
		perl -e '@a = qw/X Y Z E F/; $c = 0; while (length $ARGV[0]) { $ARGV[0] =~ s#^(..)(..)(..)(..)##; printf "%s: %d\n", $a[$c], eval "0x$4$3$2$1"; $c++; }' "$val"
	fi
}

mendel_readsym_mb() {
	val=$(mendel_readsym movebuffer)
	mbhead=$(mendel_readsym mb_head)
	mbtail=$(mendel_readsym mb_tail)
	perl - <<'ENDPERL' -- $val $mbhead $mbtail
		$i = -1;
		@a = qw/eX 4 eY 4 eZ 4 eE 4 eF 4 flags 9 dX 12 dY 4 dZ 4 dE 4 cX 12 cY 4 cZ 4 cE 4 ts 12 c 12 ec 4 n 4/;
		$c = 0;
		$c = 1234567;
		while (length $ARGV[1]) {
			if ($c > ($#a / 2)) {
				$i++;
				$c = 0;
				printf "\n}\n"
					if ($i > 0);
				printf "[%s%d] {\n", (($i == $ARGV[2])?"HEAD":"").(($ARGV[2] == $ARGV[3] && $ARGV[2] == $i)?",":"").(($i == $ARGV[3])?"TAIL":"").(($i == $ARGV[2] || $i == $ARGV[3])?":":""), $i
			}
			if ($a[$c * 2 + 1] & 8) {
				printf "\n";
			}
			if (($a[$c * 2 + 1] & 7) == 4) {
				$ARGV[1] =~ s#^(..)(..)(..)(..)##;
				printf "\t%s: %d", $a[$c * 2], eval "0x$4$3$2$1";
			}
			elsif (($a[$c * 2 + 1] & 7) == 1) {
				$ARGV[1] =~ s#^(..)##;
				printf "\t%s: %d", $a[$c * 2], eval "0x$1";
			}
			$c++;
		}
		printf "\n}\n";
ENDPERL
}
