#!/bin/bash
# Copyright (C) 2009-2014:
#     Gabes Jean, naparuba@gmail.com
#     Gerhard Lausser, Gerhard.Lausser@consol.de
#
# This file is part of Shinken.
#
# Shinken is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Shinken is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Shinken.  If not, see <http://www.gnu.org/licenses/>.


DIR=$(cd $(dirname "$0"); pwd)
cd $DIR
echo "$PWD"

# delete the result of nosetest, for coverage
rm -f nosetests.xml
rm -f coverage.xml
rm -f .coverage*


# Get test in place if send from dev tools
chmod a+x *sh *py libexec/* ../libexec/* ../bin/*
dos2unix libexec/* ../libexec/* ../bin/*
rm -f var/lib/shinken/modules
ln -sf ../../../../modules var/lib/shinken/modules
ln -sf ./shinken-arbiter ../bin/shinken-arbiter.py
ln -sf ./shinken-scheduler ../bin/shinken-scheduler.py

# specific test that must have symlink
rm -f etc/conf_in_symlinks/links/link
ln -s ../dest etc/conf_in_symlinks/links/link

function launch_and_assert {
    SCRIPT=$1
    printf " - %-60s" $SCRIPT
    output=$(python ./$SCRIPT > /tmp/test.running 2>&1)
    if [ $? != 0 ] ; then
        printf "\033[31m[ FAILED ]\033[0m\n"
	    echo "Error: the test $SCRIPT failed:"
	    cat /tmp/test.running
	    exit 2
    fi
    printf "\033[92m[ OK ]\033[0m\n"
}

echo "Launching tests:"
for ii in `ls -1 test_*py`; do
   launch_and_assert $ii;
done

# And create the coverage file
coverage combine

# Send to coveralls (if present, so if launch in TRAVIS)
coveralls

echo "Launchng pep8 now"
cd ..
pep8 --max-line-length=140 --ignore=E303,E302,E301,E241,W293,W291,E221,E126,E203,E129 --exclude='*.pyc,*~' shinken/*
if [ $? != 0 ] ; then
   printf "PEP8 compliant: \033[31m[ FAILED ]\033[0m\n"
   exit 1
fi



echo "All unit tests did pass"

exit 0

