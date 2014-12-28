bro-intel-generator
===================

Script for generating Bro intel files from pdf or html reports


# Dependecies

We make use of some additional packages that you have to install
On debian based distros you can use
```
aptitude install poppler-utils
aptitude install html2text
```

# Usage

Download some reports in html or pdf format 

Then feed them to tool like this
```
./intel_generator.sh -f apt_report.pdf -p
```

This basic example will generate intel files with IOCs such as Domains, IPs and hashes
inside current directory

At the moment only domains, ips and hash indicators are supported
If some indicators is not found generated files would be blank.

Then you install them in bro and you good to go

For installing them in Bro you need to do the following:

1. Create Intel directrory inside policy dir
```
mkdir /usr/local/bro/share/bro/policy/intel
```
2. Create __load__.bro file with following content:
```
@load frameworks/intel/seen
@load frameworks/intel/do_notice


redef Intel::read_files += {
        @DIR + "/apt_report_domains.dat",
};
``` 
3. Put newly generated files into Intel dir you create in step 1
4. install and restart new bro policy with broctl install && broctl restart
