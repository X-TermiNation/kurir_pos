#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "Realm::Storage" for configuration "Release"
set_property(TARGET Realm::Storage APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(Realm::Storage PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C;CXX"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/librealm.a"
  )

list(APPEND _cmake_import_check_targets Realm::Storage )
list(APPEND _cmake_import_check_files_for_Realm::Storage "${_IMPORT_PREFIX}/lib/librealm.a" )

# Import target "Realm::QueryParser" for configuration "Release"
set_property(TARGET Realm::QueryParser APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(Realm::QueryParser PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/librealm-parser.a"
  )

list(APPEND _cmake_import_check_targets Realm::QueryParser )
list(APPEND _cmake_import_check_files_for_Realm::QueryParser "${_IMPORT_PREFIX}/lib/librealm-parser.a" )

# Import target "Realm::ObjectStore" for configuration "Release"
set_property(TARGET Realm::ObjectStore APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(Realm::ObjectStore PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/librealm-object-store.a"
  )

list(APPEND _cmake_import_check_targets Realm::ObjectStore )
list(APPEND _cmake_import_check_files_for_Realm::ObjectStore "${_IMPORT_PREFIX}/lib/librealm-object-store.a" )

# Import target "Realm::Sync" for configuration "Release"
set_property(TARGET Realm::Sync APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(Realm::Sync PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/librealm-sync.a"
  )

list(APPEND _cmake_import_check_targets Realm::Sync )
list(APPEND _cmake_import_check_files_for_Realm::Sync "${_IMPORT_PREFIX}/lib/librealm-sync.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
