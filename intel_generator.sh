#!/usr/bin/env bash

# Bro Intel Framework headers and types
bro_header="#fields\tindicator\tindicator_type\tmeta.source\tmeta.desc\tmeta.url"
bro_domain="Intel::DOMAIN"
bro_addr="Intel::ADDR"
bro_hash="Intel::FILE_HASH"

function die {
  echo "$*"
  exit 1
}

function check_stuff () {
  # We make use of certain utilities so we make sure they are present here
  if [ ! -f "$(which html2text)" ]; then
    die "[-] Can't find html2text package. Install it with aptitude install html2text"
  elif [ ! -f "$(which pdftotext)" ]; then
    die "[-] Can't find pdftotext package. Install it with aptitute install poppler-utils"
  fi
}

function pdf_input () {
  # Convert pdf to text and save it in temp file
  pdftotext "$1" "/tmp/bro_generator_pdf$$.txt" || die "[-] pdftotext failed. Aborting..."
  txt_file="/tmp/bro_generator_pdf$$.txt"
}

function html_input () {
  # Convert html page to text and save it in temp file
  html2text -o "/tmp/bro_generator_html$$.txt" "$1" || die "[-] html2text failed. Aborting..."
  txt_file="/tmp/bro_generator_html$$.txt"
}

function ip_generation () {
  # This regexp will match ipv4 address
  # Assuming reports post them separately
  ipaddr="^([0-9]{1,3}[\.]){3}[0-9]{1,3}$"
  data=`cat "$1"|egrep "$ipaddr"|sort|uniq`
  if [ -z "$data" ]
        then return 1
  fi
  echo -e "$bro_header" > "${1%.*}"_ips.dat
  for ip in $data
  do
    echo -e "$ip\t$bro_addr\t$meta_source\t$meta_description\t$meta_url" >> "${1%.*}"_ips.dat
  done
}

function hash_generation () { # pass filename
  # This regexp will match MD5\SHA1\SHA256 hashes
  # Assuming reports post them separately
  md5_hash="^[a-f0-9]{32}$"
  sha1_hash="^[a-f0-9]{40}$"
  sha256_hash="^[a-f0-9]{64}$"
  data=`cat "$1"|egrep "($md5_hash|$sha1_hash|$sha256_hash)"|sort|uniq`
  if [ -z "$data" ]
	then return 1
  fi
  echo -e "$bro_header" > "${1%.*}"_hashes.dat
  for hash in $data
  do
    echo -e "$hash\t$bro_hash\t$meta_source\t$meta_description\t$meta_url" >> "${1%.*}"_hashes.dat
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
  domain_exclude="(*.exe|*.gif|*.jpg|*.jpeg|*.swf|*.jar|*.dll|*.ps1|*.png|*.bin|*.sys|*.vbs|*.php|*.html|*.htm|*.js|*.dat|*.pdb|*.sh|*.bat|*.dmp|*.doc|*.xls|*.ppt|*.pdf|*.txt)$"
  #Strip [.] from domain name
  strip_domain="s/\[//g -e s/\]//g"
  data=`cat "$1"|egrep -o "$domain_regexp"|egrep -v "$domain_exclude"|sort|uniq`
  if [ -z "$data" ]
        then return 1
  fi 
  echo -e "$bro_header" > "${1%.*}"_domains.dat
  for domain in $data
  do
    domain=`echo "$domain"|sed -e $strip_domain`
    echo -e "$domain\t$bro_domain\t$meta_source\t$meta_description\t$meta_url" >> "${1%.*}"_domains.dat
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

usage: "$0" options

This script will generate Bro Intel files from saved html or pdf reports

Script will automatically get IOCs from reports such as hashes, domains and IPs

Please note you need to use quotes in optional parameters.

OPTIONS:
  -h  Show this helpful message
  -f  REQUIRED Report file.
  -t  REQUIRED Indicate that report file is in html format
  -p  REQUIRED Indicate that report file is in pdf format
  -s  OPTIONAL meta.source in bro intel file. Default is report name. For example "fireeye report". Also used as subdirectory name for intel files.
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
    f="$OPTARG"
    ;;
    t)
    html=1
    ;;
    p)
    pdf=1
    ;;
    s)
    s_set=1
    meta_source="$OPTARG"
    ;;
    d)
    meta_description="$OPTARG"
    ;;
    u)
    meta_url="$OPTARG"
    ;;
    h)
    usage
    exit 1
    ;;
    ?)
    echo "Invalid option: - $OPTARG" >&2
    die "Use -h for usage info"
    ;;
  esac
done

[ "$meta_description" ]         || meta_description="-"
[ "$meta_url" ]                 || meta_url="-"
[ "$f_required" -eq 1 ]         || die "[-] -f is required parameter"
[ "$s_set" -eq 1 ]              || meta_source="${f%.*}"
[ "$html" -eq 1 -a "$pdf" -eq 1 ] && die "[-] Both html and pdf options can't be set. Choose only one."
}

# Main code
# check that arguments present in input
[ "$1" ] || { usage; exit 1; }

check_stuff
main "$@"
if [ "$html" -eq 1 ]
  then html_input "$f"
elif [ "$pdf" -eq 1 ]
  then pdf_input "$f"
else
  die "[-] html or pdf input options required"
fi
echo "Working on $f report"
domain_generation "$txt_file"
hash_generation "$txt_file"
ip_generation "$txt_file"

# Move our temp file back into current folder with initial name.dat
if [ -f "${txt_file%.*}_domains.dat" ]
	then mv "${txt_file%.*}_domains.dat" "${f%.*}_domains.dat"
fi
if [ -f "${txt_file%.*}_hashes.dat" ]
	then mv "${txt_file%.*}_hashes.dat" "${f%.*}_hashes.dat"
fi
if [ -f "${txt_file%.*}_ips.dat" ]
	then mv "${txt_file%.*}_ips.dat" "${f%.*}_ips.dat"
fi
# prepare intel folder
if [ ! -d intel ]
	then mkdir intel
fi
# create subfolder for report
if [ ! -d intel/"$meta_source" ] 
	then mkdir intel/"$meta_source"
fi
if [ -f "${f%.*}"_domains.dat ]
	then mv "${f%.*}"_domains.dat intel/"$meta_source"/
fi
if [ -f "${f%.*}"_hashes.dat ]
	then mv "${f%.*}"_hashes.dat intel/"$meta_source"/
fi
if [ -f "${f%.*}"_ips.dat ]
	then mv "${f%.*}"_ips.dat intel/"$meta_source"/
fi

cat > intel/"$meta_source"/__load__.bro << EOF

redef Intel::read_files += {
        @DIR + "/${f%.*}_domains.dat",
	@DIR + "/${f%.*}_hashes.dat",
	@DIR + "/${f%.*}_ips.dat"
};
EOF
if [ -f intel/__load__.bro ]
then
echo @load ./"$meta_source" >> intel/__load__.bro
else
cat > intel/__load__.bro << EOF
@load base/frameworks/intel
@load frameworks/intel/seen
@load ./$meta_source
EOF
fi
cat <<EOF
[+] All Done!
[+] Now simply copy intel folder located in current directory
[+] into bro policy folder and simply add @load intel to local.bro script
[+] and you all set!
[+] Or if you wish you can continue generate bro intel files and
[+] they will be added to intel directory then you can copy everything at once.
EOF

