# sdl_core_ci
Repository for housing continuous integration related scripts and files for SDL Core.

https://opensdl-jenkins.prjdmz.luxoft.com/

# Introduction:
Currently, we are using Jenkins server for the Continuous Integration process of our project.
It is mainly used for the following functionality: 

    - building SDL_CORE / SDL_ATF
    - running ATF test scripts to check implemented functionality
    - checking coding style and cppcheck

Here is a matrix of build jobs:

| Job's name mask | Description |
| --- | --- |
| _P / _E / _H | build on Proprietary / External Proprietary / HTTP flows |
| BWSS_OFF | builds with disabled option: -DBUILD_WEBSOCKET_SERVER_SUPPORT=OFF |
| _noUT / _UT | build without UnitTests / with UnitTest |
| _EL_OFF | build with disabled logging: -DENABLE_LOG=OFF |
| _ES_OFF | build with disabled security: -DENABLE_SECURITY=OFF |
| _UC_OFF | build with UnitTests with disabled cotire option: -DUSE_COTIRE=OFF |
| _BCAF | builds with disabled option: -DBUILD_CLOUD_APP_SUPPORT=OFF |
| _ATF_BUILD | a job which builds ATF for reuse in all the ATF test jobs |
| _TCP | ATF scripts jobs with TCP transport type |
| _WS | ATF scripts jobs with WebSocket transport type |
| _WSS | ATF scripts jobs with WebSocketSecured transport type |
| _OFF |  jobs view that are running on sdl_core built in *_BWSS_OFF jobs previously described |

Main view builds shows ATF build, UnitTests coverage, and a lot of sdl_core build jobs with different flags.

There are several regression views that run all our ATF tests from develop on each Policy flow (Proprietary, External Proprietary, HTTP) and transport type (TCP, WebSocket, WebSocketSecured), on TCP using Remote ATF, and a view with ATF test jobs which use sdl_core built without WebSocket support. 
