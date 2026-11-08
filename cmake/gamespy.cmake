set(GS_OPENSSL FALSE)
# FKK Edition: all online services run on one private server.
set(GAMESPY_SERVER_NAME "generals.kewekordes.com")
# Resolve every GameSpy service host (peerchat., gpcm., natneg1., ...) to the
# server name itself, so the server needs only one DNS record.
set(GAMESPY_SINGLE_HOST TRUE)

find_package(Git REQUIRED)

FetchContent_Declare(
    gamespy
    GIT_REPOSITORY https://github.com/TheSuperHackers/GamespySDK.git
    GIT_TAG        07e3d15c500415abc281efb74322ab6d9c857eb8
    PATCH_COMMAND  ${GIT_EXECUTABLE} apply --whitespace=nowarn ${CMAKE_CURRENT_LIST_DIR}/patches/gamespy-sdk-single-host.patch
    UPDATE_DISCONNECTED TRUE
)

FetchContent_MakeAvailable(gamespy)
