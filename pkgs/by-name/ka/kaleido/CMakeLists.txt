cmake_minimum_required(VERSION 3.10)
project(kaleido)

include_directories(@chromium_src@/src)
include_directories(@chromium_src@/src/headless/public)
include_directories(@chromium_src@/src/ui/gfx)

add_executable(kaleido kaleido.cc)

target_link_libraries(kaleido
    base
    headless
    gfx
)
