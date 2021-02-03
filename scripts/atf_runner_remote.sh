#!/bin/bash

_atf_folder=build_atf
_report_folder=TestingReports

echo "=== Prepare Remote environment"
remote_hash=$(docker run -d --rm remote_atf:u18 tail -f)
remote_ip=$(docker inspect $remote_hash | grep '\"IPAddress\": "172.17.0' | tail -n1 | awk '{print $2}' | sed 's/[",]//g')
local_ip=$(ip add | grep 172.17 | awk '{print $2}' | sed 's|/16||g')
echo $remote_hash $remote_ip $local_ip

echo "=== Prepare CORE"
docker exec $remote_hash bash -c "mkdir -p remote/core"
docker exec $remote_hash bash -c "wget -q $UPSTREAM_BUILD_URL/artifact/build/OpenSDL.tar.gz"
docker exec $remote_hash bash -c "tar xzf OpenSDL.tar.gz -C remote/core && rm -rf OpenSDL.tar.gz"
SDL_GIT_COMMIT=$(docker exec $remote_hash bash -c "sed s'/=/ /g' /remote/core/bin/smartDeviceLink.ini | grep 'SDLVersion'" | awk '{print $2}')
docker exec $remote_hash bash -c "wget -q $ATF_BUILD_URL/artifact/remote_atf.tar.gz"
docker exec $remote_hash bash -c "tar xzf remote_atf.tar.gz --strip-components 1 -C remote && rm -rf remote_atf.tar.gz"
docker exec $remote_hash bash -c "cd /remote/RemoteTestingAdapterServer && export LD_LIBRARY_PATH=.:/remote/core/bin && ./RemoteTestingAdapterServer" &
sleep 1

echo "=== Prepare SCRIPTS"
git clone --single-branch --branch $SCRIPT_BRANCH $SCRIPT_REPOSITORY
_scripts_folder=$(basename ${SCRIPT_REPOSITORY%.git})
SCRIPT_GIT_COMMIT=$(cd $_scripts_folder && git rev-parse --short HEAD)

echo "=== Prepare ATF"
mkdir $_atf_folder
wget -q $ATF_BUILD_URL/artifact/remote_atf.tar.gz
tar -xzf remote_atf.tar.gz -C $_atf_folder --strip-components 1 && rm -rf remote_atf.tar.gz

cd $_atf_folder
ln -s ../$_scripts_folder/files
ln -s ../$_scripts_folder/test_scripts
ln -s ../$_scripts_folder/test_sets
ln -s ../$_scripts_folder/user_modules
sed -i 's|/home/developer/sdl/b/dev/p/bin|/remote/core/bin|g' modules/configuration/remote_linux/base_config.lua
sed -i "s|\"172.17.0.2\"|\"$remote_ip\"|g" modules/configuration/remote_linux/connection_config.lua
sed -i "s|\"172.17.0.1\"|\"$local_ip\"|g" modules/configuration/remote_linux/connection_config.lua
docker cp $remote_hash:/remote/core/bin/api/MOBILE_API.xml ./data/
docker cp $remote_hash:/remote/core/bin/api/HMI_API.xml ./data/

echo "=== Prepare Test Target"
if [[ ${TEST_TARGET} = *" "* ]]; then
  cat ${TEST_TARGET} > combined_test_set.txt
  TEST_TARGET=combined_test_set.txt
else
  if [[ $TEST_TARGET = http* ]]; then
    wget -q $TEST_TARGET
    TEST_TARGET=$(basename $TEST_TARGET)
  fi
fi
echo "TEST_TARGET:" $TEST_TARGET

echo "=== Start ATF in remote mode"
./start.sh $TEST_TARGET --config=remote_linux --sdl-log=fail --sdl-core-dump=fail

docker kill $remote_hash

echo "=== Prepare REPORT"
if [ -d "$_report_folder" ]; then
  cd $_report_folder
  dir=$(basename $(find . -maxdepth 1 -mindepth 1 -type d))
  echo "dir:" $dir
  tar -I "pigz -p 16" -cf $dir.tar.gz $dir
  mv ./*/* .
  rm -rf $dir
  find . -mindepth 2 -name "*.*" -type f ! -name "Console.txt" | xargs rm -f
  cd ..
  mv $_report_folder ../
  cd ..
fi

_atf_report_file=$_report_folder/Report.txt
_html_report_file=$_report_folder/atf_report.html

function log {
  echo -e "$@" >> $_html_report_file
}

function create_html_report {
  log "<!DOCTYPE html>"
  log "<html><head>"
  log "<title>Test Result Report</title>"
  log "<style>"
  log "table,p{font-size:13px;font-family:'Courier New', Courier, monospace;}"
  log "table{border-collapse:collapse;}"
  log "table,td,th{border:1px solid black;}"
  log "th{background-color:SlateBlue;color:white;}"
  log "</style>"
  log "</head>"

  log "<table><thead><tr><th>ID</th><th>Test Result</th><th>Test Name</th></tr></thead>"

  local num_of_rows=$(wc -l $_atf_report_file | awk '{print $1}')
  let num_of_rows=$num_of_rows-9
  local rows=$(sed -n "4,${num_of_rows}p" < $_atf_report_file)
  local total=0
  local total_passed=0
  local total_failed=0
  local total_skipped=0
  local total_aborted=0
  local total_missing=0
  local total_unknown=0
  while read -r row; do
    local script_num=$(echo $row | awk '{print $1}' | sed 's/://')
    local script_status=$(echo $row | awk '{print $2}')
    local script_name=$(echo $row | awk '{print $3}')
    local color
    let "total+=1"
    case $script_status in
      PASSED)
        color="YellowGreen"
        let "total_passed+=1"
      ;;
      FAILED)
        color="red"
        let "total_failed+=1"
      ;;
      SKIPPED)
        color="yellow"
        let "total_skipped+=1"
      ;;
      ABORTED)
        color="orange"
        let "total_aborted+=1"
      ;;
      MISSING)
        color="LightSteelBlue"
        let "total_missing+=1"
      ;;
      *)
        color="PaleVioletRed"
        let "total_unknown+=1"
      ;;
    esac
    log "<tr> <td><a href='$script_num/Console.txt'>$script_num</a></td> <td bgcolor='$color'>$script_status</td> <td>$script_name</td> </tr>"
  done <<< "$rows"

  log "</table><br>"

  log "<table>"
  log "<tr> <th>Status</th> <th>Count</th> </tr>"
  log "<tr> <td bgcolor='YellowGreen'>PASSED</td> <td>$total_passed</td> </tr>"
  log "<tr> <td bgcolor='red'>FAILED</td> <td>$total_failed</td> </tr>"
  log "<tr> <td bgcolor='orange'>ABORTED</td> <td>$total_aborted</td> </tr>"
  log "<tr> <td bgcolor='yellow'>SKIPPED</td> <td>$total_skipped</td> </tr>"
  log "<tr> <td bgcolor='LightSteelBlue'>MISSING</td> <td>$total_missing</td> </tr>"
  log "<tr> <td bgcolor='PaleVioletRed'>UNKNOWN</td> <td>$total_unknown</td> </tr>"
  log "<tr style='font-weight:bold'> <td>TOTAL</td> <td>$total</td> </tr>"
  log "</table><br>"

  log "<p>Complete report: <a href='$dir.tar.gz'>$dir.tar.gz</a></p>"

  log "<p>"$(grep "Exec" $_atf_report_file)"</p>"

  log "</html>"

}

create_html_report

SDL_BRANCH=$(wget -qO - $UPSTREAM_BUILD_URL/api/json | grep -Po 'SDL_BRANCH","value":.*?[^\\]"' | cut -d':' -f2 | sed 's/\"//g')

echo Desc: "SDL: ${SDL_BRANCH:0:29} (${SDL_GIT_COMMIT:0:8})<br>SCR: ${SCRIPT_BRANCH:0:29} (${SCRIPT_GIT_COMMIT:0:8})"

status=$([ "$(grep -cP "\tABORTED|\tFAILED" $_atf_report_file)" -eq 0 ] && echo 0 || echo 1)

echo "Status:" $status

exit $status
