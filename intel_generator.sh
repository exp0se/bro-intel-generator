#!/bin/bash

# Bro Intel Framework headers and types
bro_header="#fields\tindicator\tindicator_type\tmeta.source\tmeta.desc\tmeta.url"
bro_domain="Intel::DOMAIN"
bro_addr="Intel::ADDR"
bro_hash="Intel::FILE_HASH"


function check_stuff () {

	# We make use of certain utilities so we make sure they are present here
	if [ ! -f /usr/bin/html2text ]
		then echo "Can't find html2text package. Install it with aptitude install html2text"
		exit 1
	elif [ ! -f /usr/bin/pdftotext ]
		then echo "Can't find pdftotext package. Install it with aptitute install poppler-utils"
		exit 1
	fi

}

function pdf_input () {
	# Convert pdf to text and save it in temp file
	pdftotext $1 /tmp/bro_generator_pdf$$.txt
	if [ $? -ne 0 ]
		then echo "pdftotext failed. Aborting..."
		exit 1
	fi
	txt_file="/tmp/bro_generator_pdf$$.txt"
}

function html_input () {

	# Convert html page to text and save it in temp file 
	html2text -o /tmp/bro_generator_html$$.txt $1
	if [ $? -ne 0 ]
                then echo "html2text failed. Aborting..."
                exit 1
        fi
	txt_file="/tmp/bro_generator_html$$.txt"
}

function ip_generation () {
	# This regexp will match ipv4 address
	# Assuming reports post them separately
	ipaddr="^([0-9]{1,3}[\.]){3}[0-9]{1,3}$"
	data=`cat $1|egrep $ipaddr|sort|uniq`
        echo -e $bro_header > ${1%.*}_ips.dat
        for ip in $data
        do
                echo -e "$ip\t$bro_addr\t$meta_source\t$meta_description\t$meta_url" >> ${1%.*}_ips.dat
        done

}

function hash_generation () { # pass filename
	# This regexp will match MD5 hashes
	# Assuming reports post them separately
	md5_hash="^[a-f0-9]{32}$"
        data=`cat $1|egrep $md5_hash|sort|uniq`
        echo -e $bro_header > ${1%.*}_hashes.dat
        for hash in $data
        do
                echo -e "$hash\t$bro_hash\t$meta_source\t$meta_description\t$meta_url" >> ${1%.*}_hashes.dat
       	done
}


function domain_generation () { # pass filename
	# This regexp will match domains and infinite number of subdomains
	# Like example.com, i.dont.care.example.com, example[.]com
	# We match [.] domain, because some vendors too cool to write in ordinary fashion
	# Assuming reports will contain separate list of domains
	# we match only separate domain names, not those as part of url
	domain_regexp="^([a-z0-9\-]+\.)*[a-z0-9\-]+(\.|\[\.\])[a-z]+$"
	# Reports often include filenames with extension that will also be matched by our domain
	# regexp. Use this to exclude them from matching by extenstion
	domain_exclude="(*.exe|*.gif|*.jpg|*.jpeg|*.swf|*.jar)$"
	#Strip [.] from domain name  
	strip_domain="s/\[//g -e s/\]//g"
	data=`cat $1|egrep $domain_regexp|egrep -v $domain_exclude|sort|uniq`
	echo -e $bro_header > ${1%.*}_domains.dat
	for domain in $data
	do
		domain=`echo $domain|sed -e $strip_domain` 
		echo -e "$domain\t$bro_domain\t$meta_source\t$meta_description\t$meta_url" >> ${1%.*}_domains.dat
	done
}

function usage () {
cat << EOF

    .%%%%%...%%%%%....%%%%...........%%%%%%..%%..%%..%%%%%%..%%%%%%..%%.....
    .%%..%%..%%..%%..%%..%%............%%....%%%.%%....%%....%%......%%.....
    .%%%%%...%%%%%...%%..%%............%%....%%.%%%....%%....%%%%....%%.....
    .%%..%%..%%..%%..%%..%%............%%....%%..%%....%%....%%......%%.....
    .%%%%%...%%..%%...%%%%...........%%%%%%..%%..%%....%%....%%%%%%..%%%%%%.
    ........................................................................
    ..%%%%...%%%%%%..%%..%%..%%%%%%..%%%%%....%%%%...%%%%%%...%%%%...%%%%%..
    .%%......%%......%%%.%%..%%......%%..%%..%%..%%....%%....%%..%%..%%..%%.
    .%%.%%%..%%%%....%%.%%%..%%%%....%%%%%...%%%%%%....%%....%%..%%..%%%%%..
    .%%..%%..%%......%%..%%..%%......%%..%%..%%..%%....%%....%%..%%..%%..%%.
    ..%%%%...%%%%%%..%%..%%..%%%%%%..%%..%%..%%..%%....%%.....%%%%...%%..%%.
    .......................... https://github.com/exp0se/bro-intel-generator

usage: $0 options

This script will generate Bro Intel files from saved html or pdf reports

Script will automatically get IOCs from reports such as hashes, domains and IPs

Please note you need to use quotes in optional parameters.

OPTIONS:
  -h  Show this helpful message
  -f  REQUIRED Report file.
  -t  REQUIRED Indicate that report file is in html format
  -p  REQUIRED Indicate that report file is in pdf format
  -s  OPTIONAL meta.source in bro intel file. Default is report name. For example "fireeye report".
  -d  OPTIONAL meta.desc in bro intel file. Default is none. For example "CnC Host"
  -u  OPTIONAL meta.url in bro intel file. Default is none. Refernce url for intel, like "http://doc.emergingthreats.net/2002494"

EOF
}
  
function main () {
f_required=0
s_set=0
html=0
pdf=0
while getopts ":f:s:d:u:htp" opt; do
        case "$opt" in
	        f)
		f_required=1
		f=$OPTARG
                ;;
		t)
		html=1
		;;
		p)
		pdf=1
		;;
		s)
		s_set=1
		meta_source=$OPTARG
		;;
		d)
		meta_description=$OPTARG
		;;
		u)
		meta_url=$OPTARG
		;;
		h)
		usage
		exit 1
		;;
		?)
		echo "Invalid option: - $OPTARG" >&2
		echo "Use -h for usage info" 
               	exit 1
		;;
        esac
done
if [ -z $meta_description ]
	then meta_description="-"
fi
if [ -z $meta_url ]
	then meta_url="-"
fi
if [ $f_required -eq 0 ]
	then echo "-f is required parameter"
	exit 1
fi
if [ $s_set -eq 0 ]
	then meta_source=${f%.*}
fi
if [ $html -eq 1 -a $pdf -eq 1 ]
	then echo "Both html and pdf options can't be set. Choose only one."
	exit 1
fi
}

# Main code
# check that arguments present in input
if [ -z "$1" ]
	then usage
	exit 1
fi
check_stuff
main "$@"
if [ $html -eq 1 ]
	then html_input $f
elif [ $pdf -eq 1 ]
	then pdf_input $f
else
	echo "html or pdf input options required"
	exit 1
fi
domain_generation $txt_file
hash_generation $txt_file
ip_generation $txt_file
# Move our temp file back into current folder with initial name.dat
mv ${txt_file%.*}_domains.dat ${f%.*}_domains.dat
mv ${txt_file%.*}_hashes.dat ${f%.*}_hashes.dat
mv ${txt_file%.*}_ips.dat ${f%.*}_ips.dat
cat << EOF
Following intel files was created:
${f%.*}_domains.dat
${f%.*}_hashes.dat
${f%.*}_ips.dat
Please note that some extracted indicators might be incorrect so check resulting files before 
using them in production.
Now upload them into some folder(e.g. /opt/bro/share/bro/intel/)
And change local.bro script to include your new files with indicators
redef Intel::read_files += {
        "/opt/bro/share/bro/intel/my_new_file.dat"
};
EOF

