include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(mega_cmake_template_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(mega_cmake_template_setup_options)
  option(mega_cmake_template_ENABLE_HARDENING "Enable hardening" ON)
  option(mega_cmake_template_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    mega_cmake_template_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    mega_cmake_template_ENABLE_HARDENING
    OFF)

  mega_cmake_template_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR mega_cmake_template_PACKAGING_MAINTAINER_MODE)
    option(mega_cmake_template_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(mega_cmake_template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(mega_cmake_template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(mega_cmake_template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(mega_cmake_template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(mega_cmake_template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(mega_cmake_template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(mega_cmake_template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(mega_cmake_template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(mega_cmake_template_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(mega_cmake_template_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(mega_cmake_template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(mega_cmake_template_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(mega_cmake_template_ENABLE_IPO "Enable IPO/LTO" ON)
    option(mega_cmake_template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(mega_cmake_template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(mega_cmake_template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(mega_cmake_template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(mega_cmake_template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(mega_cmake_template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(mega_cmake_template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(mega_cmake_template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(mega_cmake_template_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(mega_cmake_template_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(mega_cmake_template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(mega_cmake_template_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      mega_cmake_template_ENABLE_IPO
      mega_cmake_template_WARNINGS_AS_ERRORS
      mega_cmake_template_ENABLE_USER_LINKER
      mega_cmake_template_ENABLE_SANITIZER_ADDRESS
      mega_cmake_template_ENABLE_SANITIZER_LEAK
      mega_cmake_template_ENABLE_SANITIZER_UNDEFINED
      mega_cmake_template_ENABLE_SANITIZER_THREAD
      mega_cmake_template_ENABLE_SANITIZER_MEMORY
      mega_cmake_template_ENABLE_UNITY_BUILD
      mega_cmake_template_ENABLE_CLANG_TIDY
      mega_cmake_template_ENABLE_CPPCHECK
      mega_cmake_template_ENABLE_COVERAGE
      mega_cmake_template_ENABLE_PCH
      mega_cmake_template_ENABLE_CACHE)
  endif()

  mega_cmake_template_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (mega_cmake_template_ENABLE_SANITIZER_ADDRESS OR mega_cmake_template_ENABLE_SANITIZER_THREAD OR mega_cmake_template_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(mega_cmake_template_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(mega_cmake_template_global_options)
  if(mega_cmake_template_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    mega_cmake_template_enable_ipo()
  endif()

  mega_cmake_template_supports_sanitizers()

  if(mega_cmake_template_ENABLE_HARDENING AND mega_cmake_template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR mega_cmake_template_ENABLE_SANITIZER_UNDEFINED
       OR mega_cmake_template_ENABLE_SANITIZER_ADDRESS
       OR mega_cmake_template_ENABLE_SANITIZER_THREAD
       OR mega_cmake_template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${mega_cmake_template_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${mega_cmake_template_ENABLE_SANITIZER_UNDEFINED}")
    mega_cmake_template_enable_hardening(mega_cmake_template_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(mega_cmake_template_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(mega_cmake_template_warnings INTERFACE)
  add_library(mega_cmake_template_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  mega_cmake_template_set_project_warnings(
    mega_cmake_template_warnings
    ${mega_cmake_template_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(mega_cmake_template_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    mega_cmake_template_configure_linker(mega_cmake_template_options)
  endif()

  include(cmake/Sanitizers.cmake)
  mega_cmake_template_enable_sanitizers(
    mega_cmake_template_options
    ${mega_cmake_template_ENABLE_SANITIZER_ADDRESS}
    ${mega_cmake_template_ENABLE_SANITIZER_LEAK}
    ${mega_cmake_template_ENABLE_SANITIZER_UNDEFINED}
    ${mega_cmake_template_ENABLE_SANITIZER_THREAD}
    ${mega_cmake_template_ENABLE_SANITIZER_MEMORY})

  set_target_properties(mega_cmake_template_options PROPERTIES UNITY_BUILD ${mega_cmake_template_ENABLE_UNITY_BUILD})

  if(mega_cmake_template_ENABLE_PCH)
    target_precompile_headers(
      mega_cmake_template_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(mega_cmake_template_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    mega_cmake_template_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(mega_cmake_template_ENABLE_CLANG_TIDY)
    mega_cmake_template_enable_clang_tidy(mega_cmake_template_options ${mega_cmake_template_WARNINGS_AS_ERRORS})
  endif()

  if(mega_cmake_template_ENABLE_CPPCHECK)
    mega_cmake_template_enable_cppcheck(${mega_cmake_template_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(mega_cmake_template_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    mega_cmake_template_enable_coverage(mega_cmake_template_options)
  endif()

  if(mega_cmake_template_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(mega_cmake_template_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(mega_cmake_template_ENABLE_HARDENING AND NOT mega_cmake_template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR mega_cmake_template_ENABLE_SANITIZER_UNDEFINED
       OR mega_cmake_template_ENABLE_SANITIZER_ADDRESS
       OR mega_cmake_template_ENABLE_SANITIZER_THREAD
       OR mega_cmake_template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    mega_cmake_template_enable_hardening(mega_cmake_template_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
