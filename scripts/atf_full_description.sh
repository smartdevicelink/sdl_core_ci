#!/bin/bash -x
echo "Script started"

####################################################
#  Helpers
####################################################

seconds2time ()
{
   T=$1
   D=$((T/60/60/24))
   H=$((T/60/60%24))
   M=$((T/60%60))
   S=$((T%60))

   if [[ ${D} != 0 ]]
   then
      printf '%d days %02d:%02d:%02d' $D $H $M $S
   else
      printf '%02d:%02d:%02d' $H $M $S
   fi
}

####################################################
#  Set up
####################################################

export ATF_BRANCH=`curl -kfs ${ATF_BUILD_URL}api/json | jq .actions[" "].lastBuiltRevision.branch[0].name | grep -v null | cut -c9-15`
export ATF_COMMIT=`curl -kfs ${ATF_BUILD_URL}lastBuild/api/json | jq .actions[" "].lastBuiltRevision.SHA1 | grep -v null | cut -c2-9`

ulimit -c unlimited;

rm -rf /tmp/corefiles
mkdir /tmp/corefiles
echo '/tmp/corefiles/core.%e.%p.%t' | sudo tee /proc/sys/kernel/core_pattern

ISSUE_BASE_URL="https://github.com/smartdevicelink/sdl_core/issues/"

TEST_SET=${TEST_SET}

mkdir core

wget --no-check-certificate -q ${UPSTREAM_BUILD_URL}/artifact/build/OpenSDL.tar.gz
tar -xzf OpenSDL.tar.gz -C core && rm -rf OpenSDL.tar.gz
export LD_LIBRARY_PATH=$(pwd)/core/bin

echo ${SCRIPT_REPOSITORY}
echo "SCRIPT_BRANCH = "${SCRIPT_BRANCH}
git clone ${SCRIPT_REPOSITORY}
ATF_SCRIPTS_DIR=$(basename ${SCRIPT_REPOSITORY%.git})
cd $ATF_SCRIPTS_DIR; git checkout $SCRIPT_BRANCH
export SCRIPT_BRANCH=$SCRIPT_BRANCH
export SCRIPT_GIT_COMMIT=`git rev-parse --short HEAD`
cd ..

cp -r ${WORKSPACE}/$ATF_SCRIPTS_DIR/. ${WORKSPACE}/
cp -rf ${WORKSPACE}/core/bin/api/. ${WORKSPACE}/data/

echo "Backup SDL"
#Backup
./SDL_environment_setup.sh -b ${WORKSPACE}/core/bin

echo "<html><head><title>ATF ${SCRIPT_BRANCH} ${POLICY} Report - Build#${BUILD_NUMBER}</title></head>
<script src='https://code.jquery.com/jquery-3.1.1.min.js' integrity='sha256-hVVnYaiADRTO2PzUGmuLJr8BLUSjGIZsDYGmIJLv2b8=' crossorigin='anonymous'></script>
<script src='https://code.jquery.com/ui/1.12.0/jquery-ui.min.js' integrity='sha256-eGE6blurk5sHj+rmkfsGYeKyZx3M4bG+ZlFyA7Kns7E=' crossorigin='anonymous'></script>
<link href='https://cdn.datatables.net/1.10.13/css/jquery.dataTables.min.css' rel='stylesheet'>
<link href='https://cdn.datatables.net/buttons/1.2.4/css/buttons.dataTables.min.css' rel='stylesheet'>
<link href='https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.0.0-alpha.5/css/bootstrap.css' rel='stylesheet'>
<script src='https://cdn.datatables.net/1.10.13/js/jquery.dataTables.min.js'></script>
<script src='https://cdn.datatables.net/buttons/1.2.4/js/dataTables.buttons.min.js'></script>
<script src='https://cdnjs.cloudflare.com/ajax/libs/jszip/2.5.0/jszip.min.js'></script>
<script src='https://cdn.rawgit.com/bpampuch/pdfmake/0.1.18/build/pdfmake.min.js'></script>
<script src='https://cdn.rawgit.com/bpampuch/pdfmake/0.1.18/build/vfs_fonts.js'></script>
<script src='https://cdn.datatables.net/buttons/1.2.4/js/buttons.html5.min.js'></script>
<script src='https://cdn.datatables.net/1.10.13/js/dataTables.bootstrap4.min.js'></script>
<script> \$(document).ready(function() {\$('#example').DataTable({paging: false, bSortClasses : false, dom: 'Bfrtip', buttons: ['copyHtml5', 'excelHtml5', 'csvHtml5', 'pdfHtml5']});} );</script>" >> atf_report.html

echo "<h3><a href='${BUILD_URL}'>${JOB_NAME}</a></h3><br>
Detailed regression report - <a href='${BUILD_URL}/testReport/(root)/lua/'>Tests Run Details</a><br><br>
<table border='1' id="example" class='table table-striped table-bordered display compact stripe hover' cellspacing="0" width="100%">
<thead><tr><th>Test name</th><th>Test Result</th><th>Execution time.</th><th>GitHub Issue</th></tr></thead>" >> atf_report.html

echo "<testsuites>
<testsuite name='ALL TESTS_${POLICY}'>" >> junit.xml

####################################################
#  Run tests
####################################################

total_time=0;
pased_tests=0;
failed_tests=0;
skipped_tests=0;
aborted_tests=0;
unknown_tests=0;

for SUB_SET in $TEST_SET; do
   echo "$(cat ./test_sets/$SUB_SET)"
   while read -r i
   do
      test_script=$(echo $i | awk '{print $1}')
      issue_id=$(echo $i | awk '{print $2}')
      if [ -n "$issue_id" ] && [ -n "$ISSUE_BASE_URL" ]; then
         issue_url=$ISSUE_BASE_URL$issue_id
      else
         issue_url=""
      fi

      if [[ $i != ";"* ]]; then
         echo "Script = "$test_script
         ps -aux | grep smartDeviceLinkCore | awk '{print $2}' | xargs kill -9;
         echo "./start.sh --sdl-core=${WORKSPACE}/core/bin $test_script"
         start=$SECONDS;
         ./start.sh --sdl-core=${WORKSPACE}/core/bin $test_script 2>ErrorLog.txt | tee console.log ; result=${PIPESTATUS[0]};
         stop=$SECONDS;
         (( runtime=stop-start ));
         (( total_time=total_time+runtime ));
         if [ $result -eq 0 ]; then
            (( pased_tests=pased_tests+1 ))
            echo "Test passed";
            echo "<tr> <td>$test_script</td><td bgcolor='green'>Passed</td><td>$runtime</td><td><a href='$issue_url'>$issue_id</a></td></tr>" >> atf_report.html;
            echo "<testcase name='$(basename $test_script)' classname='lua' time='$runtime' />" >> junit.xml;
            echo "$(basename $test_script)" >> success_tests.txt;
         elif [ $result -eq 1 ]; then
            (( aborted_tests=aborted_tests+1 ))
            echo "Test aborted - $test_script"
            echo "<tr><td>$test_script</td><td bgcolor='DarkOrange'>Aborted</td><td>0</td><td><a href='$issue_url'>$issue_id</a></td></tr>" >> atf_report.html;
            echo "<testcase name='$(basename $test_script)' classname='lua' time='0'>" >> junit.xml;
            echo "<aborted /></testcase>" >> junit.xml
            echo "$(basename $test_script)" >> aborted_tests.txt;
         elif [ $result -eq 2 ]; then
            (( failed_tests=failed_tests+1 ))
            echo "<tr> <td>$test_script</td><td bgcolor='red'>Failed</td><td>$runtime</td><td><a href='$issue_url'>$issue_id</a></td></tr>" >> atf_report.html;
            echo "<testcase name='$(basename $test_script)' classname='lua' time='$runtime'>" >> junit.xml;
            echo "<failure message='Something goes wrong'>$ERROR</failure>" >> junit.xml;
            echo "</testcase>" >> junit.xml
            echo "Test failed with exit code = $result!";
            echo "$(basename $test_script)" >> failed_tests.txt;
         elif [ $result -eq 3 ]; then
            (( unknown_tests=unknown_tests+1 ))
            echo "<tr><td>$test_script</td><td bgcolor='blue'>Unknown</td><td>$runtime</td><td><a href='$issue_url'>$issue_id</a></td></tr>" >> atf_report.html;
            echo "<testcase name='$(basename $test_script)' classname='lua' time='$runtime'>" >> junit.xml;
            echo "<failure message='Something goes wrong'>$ERROR</failure>" >> junit.xml;
            echo "</testcase>" >> junit.xml
            echo "Test aborted with exit code = $result!";
         elif [ $result -eq 4 ]; then
            (( skipped_tests=skipped_tests+1 ))
            echo "Test skipped - $test_script"
            echo "<tr><td>$test_script</td><td bgcolor='yellow'>Skipped</td><td>0</td><td><a href='$issue_url'>$issue_id</a></td></tr>" >> atf_report.html;
            echo "<testcase name='$(basename $test_script)' classname='lua' time='0'>" >> junit.xml;
            echo "<skipped /></testcase>" >> junit.xml
            echo "$(basename $test_script)" >> skipped_tests.txt;
         fi
         echo "Test finished!";
         ps -aux | grep smartDeviceLinkCore | awk '{print $2}' | xargs kill -9;
         echo "Clean SDL"
         #Clean
         ./SDL_environment_setup.sh -c ${WORKSPACE}/core/bin
         echo "Restore SDL"
         #Restore
         ./SDL_environment_setup.sh -r ${WORKSPACE}/core/bin
      else
         echo "Test skipped - $test_script"
         echo "<tr> <td>$test_script</td><td bgcolor='yellow'>Skipped</td><td>0</td><td><a href='$issue_url'>$issue_id</a></td></tr>" >> atf_report.html;
         echo "<testcase name='$(basename $test_script)' classname='lua' time='0'>" >> junit.xml;
         echo "<skipped /></testcase>" >> junit.xml
         echo "$(basename $test_script)" >> skipped_tests.txt;
      fi
   done < ./test_sets/$SUB_SET
done

echo "</table><br>Total time: $(seconds2time $total_time)
</br>Passed=${pased_tests}, Aborted=${aborted_tests}, Failed=${failed_tests}, Skipped=${skipped_tests}</html>" >> atf_report.html

echo "</testsuite>
</testsuites>" >> junit.xml

tar -zcf TestingReports.tar.gz TestingReports
if ls ErrorLog-* 1>/dev/null 2>&1; then
   tar -zcf ErrorLogs.tar.gz ErrorLog-*.txt
fi

if [ $(ls -A /tmp/corefiles | wc -l) -ne 0 ]; then
   tar -zcf corefiles.tar.gz -C /tmp/corefiles .
fi

echo "Script ended"
echo "{ATF_PASSED:${pased_tests} }"
echo "{ATF_ABORTED:${aborted_tests} }"
echo "{ATF_FAILED:${failed_tests} }"
echo "{ATF_SKIPPED:${skipped_tests} }"
echo "{ATF_UNKNOWN:${unknown_tests} }"
echo "{ATF_TOTAL:$(( pased_tests+failed_tests+skipped_tests+aborted_tests+unknown_tests )) }"

echo Desc: "SDL:    " ${SDL_GIT_BRANCH:7:29} " " ${SDL_GIT_COMMIT:0:8}  "<br>"\
           "Scripts:" ${SCRIPT_BRANCH:0:29}  " " ${SCRIPT_GIT_COMMIT}   "<br>"\
           "ATF:    " $ATF_BRANCH          " " $ATF_COMMIT

if [ $failed_tests -ne 0 ]; then
   echo "At least one failed test exists"
   exit 1
fi

if [ $aborted_tests -ne 0 ]; then
   echo "At least one aborted test exists"
   exit 1
fi

if [ $pased_tests = 0 ]; then
   echo "We have no passed tests"
   exit 1
fi
