set pluginFolder to do shell script "echo ~"
set pluginFolder to pluginFolder & "/Library/Application Support/SIMBL/Plugins"
do shell script "mkdir -p " & quoted form of pluginFolder
do shell script "cp -R /Volumes/MouseTerm/MouseTerm.bundle " & quoted form of pluginFolder

display dialog "Installed into " & pluginFolder buttons {"OK"}
