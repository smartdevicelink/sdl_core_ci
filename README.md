# SDL continuous integration strategy

SDL continuously checks code:
 - check style
 - static code analysis
 - build and unit tests
 - smoke automated tests
 - regression automated tests

Job artifacts contain build results, ATF reports, SDL logs,  etc ...

CI strategy described in details in [proposal](https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0277-Continuous-Integration-And-Testing.md)

## Develop nightly and push checks

Only TCP transport is checked on 3 policy flows. 

[Develop](https://github.com/smartdevicelink/sdl_core/tree/develop) push and nightly builds are available in [view](https://opensdl-jenkins.prjdmz.luxoft.com/view/Develop_push_and_nightly_status/) :

 - [Code style check](https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_SDL_Checkstyle/) : Use [check_style.sh](https://github.com/smartdevicelink/sdl_core/blob/master/tools/infrastructure/check_style.sh) to check sdl_core code for compliance to Google coding style. ![bage][check style bage] 
 - Develop builds without unit tests in 3 policy flows: 
   - [![bage][develop PROPRIETARY no ut bage]][develop PROPRIETARY no ut] 
   - [![bage][develop EXTERNAL PROPRIETARY no ut bage]][develop EXTERNAL PROPRIETARY no ut] 
   - [![bage][develop HTTP no ut bage]][develop HTTP no ut] 
 - Develop builds and unit unit tests run: 
   - [ ![bage][develop PROPRIETARY ut bage]][develop PROPRIETARY ut]
   - [![bage][develop EXTERNAL PROPRIETARY ut bage]][develop EXTERNAL PROPRIETARY ut] 
   - [![bage][develop HTTP ut bage]][develop HTTP ut] 
 - [Develop_=RUN_PUSH_AND_NIGHTLY=](
https://opensdl-jenkins.prjdmz.luxoft.com/view/Develop%20push%20and%20nightly/job/Develop_=RUN_PUSH_AND_NIGHTLY=/) job is trigger for listed develop build jobs


Develop branch push and nightly automated scripts checks available in [view](https://opensdl-jenkins.prjdmz.luxoft.com/view/all/) :

### Automated scripts 

Automated scripts checks triggered by no unit tests SDL build jobs. 
Each job contains a description of ATF test sets that it includes. 

### Automated smoke tests 

Contains basic checks from [smoke_tests.txt](https://github.com/smartdevicelink/sdl_atf_test_scripts/blob/master/test_sets/smoke_tests.txt)

A test set executed for SDL build in 3 policy flows: 

 - [![bage][develop automated smoke PROPRIETARY bage]][develop automated smoke PROPRIETARY]
 - [![bage][develop automated smoke EXTERNAL PROPRIETARY bage]][develop automated smoke EXTERNAL PROPRIETARY]
 - [![bage][develop automated smoke HTTP bage]][develop automated smoke HTTP]
 

### Automated regression

#### Automated policy regression 

Check pull regression specific for each policy flow.

A test set executed for SDL build in 3 policy flows: 
 - [![bage][PROPRIETARY atf policy bage]][PROPRIETARY atf policy ]
 - [![bage][EXTERNAL PROPRIETARY atf policy bage]][EXTERNAL PROPRIETARY atf policy ]
 - [![bage][HTTP atf policy bage]][HTTP atf policy]

#### Automated RC regression 

#### Various features regression
Contains all ATF scripts for all featured available in the development.
For parallel execution, checks are split to multiple jobs with make name template **Develop_TCP_ATF_VF{X}_{P,H,E}**. **X** is the number.

Full list of regression ATF jobs available on : https://opensdl-jenkins.prjdmz.luxoft.com/view/ATF_Regression_on_TCP/ 

## PR to develop checks

Pull request jobs are available in view: https://opensdl-jenkins.prjdmz.luxoft.com/view/PR_checks/ 

PR checks : 
 - code style
 - build with unit tests
 - [smoke_tests.txt](https://github.com/smartdevicelink/sdl_atf_test_scripts/blob/master/test_sets/smoke_tests.txt) trigger by build with unit tests.

## Weekly checks 

List of develop jobs executed [weekly](https://opensdl-jenkins.prjdmz.luxoft.com/view/Develop_weekly/)

### Unit tests coverage 

Unit tests coverage check weekly in the job: [![bage][unit test coverage bage]][unit test coverage]

### Full ATF regression

On Saturday, SDL CI performs a full regression check on these following transports: TCP, WebSockets, SecureWebSockets, and all 3 policy flow. 
Weekly builds are available on the view https://opensdl-jenkins.prjdmz.luxoft.com/view/Develop_weekly/ 

Each SDL build without unit tests triggers full ATF regression. 
List of triggered jobs available in each build job as Downstream projects, example:
https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_SDL_NoUT_E_BWSS_OFF/ 

Full weekly status is available on https://opensdl-jenkins.prjdmz.luxoft.com/view/Develop_weekly_status/ 

## Feature checks:

For each feature before merging to develop should be created a list of jobs similar to develop to check that feature will no introduce a regression. 
There is a special job in CI [Feature job create]() that will create a list of jobs and a separate view for the feature.

Required input values for feature job: 
 - Feature name (will be used for view title)
 - sdl_core feature branch and repository (master by default) 
 - sdl_atf feature branch and repository (master by default)
 - sdl_atf_test_scripts feature branch and repository. (master by default)
 - Feature test set (optional)
 - Additional info : evolution proposal, links to issues, etc ...
 
After job execution will be created a view with the following checks:
 1. SDL build with unit tests on 3 policy flows (triggers: push, nightly)
 2. SDL build without unit tests on 3 policy flows (triggers: push, nightly)
 3. Smoke tests on 3 policy flows (triggers: build jobs without unit tests)
 4. Feature tests on 3 policy flows (triggers: build jobs without unit tests)
 5. Regression tests on 3 policy flows (triggers: build jobs without unit tests)

## Special requests

In case of special request (not ordinary builds for special feature, restart certain jobs, etc, ...) please contact any of following persons:
 - [Yarik Mamykin](https://github.com/YarikMamykin) : YMamykin@luxoft.com
 - [Alexander Kutsan](https://github.com/LuxoftAKutsan) : akutsan@luxoft.com

[check style bage]: https://img.shields.io/jenkins/build?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_SDL_Checkstyle%2F&label=check%20style

[develop PROPRIETARY no ut]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_SDL_NoUT_P/
[develop PROPRIETARY no ut bage]:
https://img.shields.io/jenkins/build?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_SDL_NoUT_P%2F&label=PROPRIETARY%20build%20%20no%20UT

[develop EXTERNAL PROPRIETARY no ut]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_SDL_NoUT_E/
[develop EXTERNAL PROPRIETARY no ut bage]:
https://img.shields.io/jenkins/build?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_SDL_NoUT_E%2F&label=external%20PROPRIETARY%20build%20%20no%20UT

[develop HTTP no ut]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_SDL_NoUT_H
[develop HTTP no ut bage]:
https://img.shields.io/jenkins/build?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_SDL_NoUT_H&label=HTTP%20build%20%20no%20UT


[develop PROPRIETARY ut]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_SDL_UT_P/
[develop PROPRIETARY ut bage]:
https://img.shields.io/jenkins/build?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_SDL_UT_P%2F&label=PROPRIETARY%20unit%20tests

[develop EXTERNAL PROPRIETARY ut]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_SDL_UT_E/
[develop EXTERNAL PROPRIETARY ut bage]:
https://img.shields.io/jenkins/build?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_SDL_UT_E%2F&label=external%20PROPRIETARY%20unit%20tests

[develop HTTP ut]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_SDL_UT_H
[develop HTTP ut bage]:
https://img.shields.io/jenkins/build?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_SDL_UT_H&label=http%20unit%20tests&style=plastic

[develop automated smoke PROPRIETARY]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_TCP_ATF_Smoke_P
[develop automated smoke PROPRIETARY bage]:
https://img.shields.io/jenkins/tests?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_TCP_ATF_Smoke_P&label=automated%20smoke%20PROPRIETARY

[develop automated smoke EXTERNAL PROPRIETARY]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_TCP_ATF_Smoke_E
[develop automated smoke EXTERNAL PROPRIETARY bage]:
https://img.shields.io/jenkins/tests?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_TCP_ATF_Smoke_E&label=automated%20smoke%20external%20PROPRIETARY

[develop automated smoke HTTP]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_TCP_ATF_Smoke_H
[develop automated smoke HTTP bage]:
https://img.shields.io/jenkins/tests?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_TCP_ATF_Smoke_E&label=automated%20smoke%20http

[PROPRIETARY atf policy]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_TCP_ATF_Policies_P/
[PROPRIETARY atf policy bage]:https://img.shields.io/jenkins/tests?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_TCP_ATF_Policies_P%2F&label=PROPRIETARY%20policy%20tests

[EXTERNAL PROPRIETARY atf policy]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_TCP_ATF_Policies_E/
[EXTERNAL PROPRIETARY atf policy bage]:https://img.shields.io/jenkins/tests?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_TCP_ATF_Policies_E%2F&label=external%20PROPRIETARY%20policy%20tests


[HTTP atf policy]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/Develop_TCP_ATF_Policies_H/
[HTTP atf policy bage]:https://img.shields.io/jenkins/tests?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2FDevelop_TCP_ATF_Policies_H%2F&label=http%20policy%20tests

[unit test coverage]: https://opensdl-jenkins.prjdmz.luxoft.com/view/all/job/develop_weekly_coverage/
[unit test coverage bage]: https://img.shields.io/jenkins/tests?jobUrl=https%3A%2F%2Fopensdl-jenkins.prjdmz.luxoft.com%2Fview%2Fall%2Fjob%2Fdevelop_weekly_coverage%2F&label=unit%20test%20coverage
