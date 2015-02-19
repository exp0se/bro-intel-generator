bro-intel-generator
===================

Script for generating Bro intel files from pdf or html reports


# Dependencies

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

Please note that sometimes indicators extracted would be incorrect and it is good idea to check files generated before using them in production

At the moment only domains, ips and hash indicators are supported

We assume reports contain separate section list of indicators posted like in Appendix

There is also a possibility that files with extensions will be matched by our domain matching regexp, so there is a variable to exclude them
see code below

```
domain_exclude="(*.exe|*.gif|*.jpg|*.jpeg|*.swf|*.jar)$"
```

If some indicators is not found generated files would be blank.

Then you install them in bro and you good to go

For installing them in Bro you need to do the following:

Create Intel directrory inside policy dir
```
mkdir /usr/local/bro/share/bro/policy/intel
```
Create \__load\__.bro file with following content:
```
@load frameworks/intel/seen
@load frameworks/intel/do_notice


redef Intel::read_files += {
        @DIR + "/apt_report_domains.dat",
};
``` 
Put newly generated files into Intel dir you created in early and
Install and restart new bro policy with
```
 broctl install && broctl restart
```
