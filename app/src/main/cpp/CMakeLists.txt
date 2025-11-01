
cmake_minimum_required(VERSION 3.18.1)

project("signatureextractor")

add_library(nativelib SHARED native-lib.cpp)

find_library(log-lib log)
find_library(jnigraphics-lib jnigraphics)

target_link_libraries(nativelib ${log-lib} ${jnigraphics-lib})
