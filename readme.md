
# JBoss auto build (python version)

Download jbossbuild.py and michwu.py to a temporary folder, then run below command as super user 'root' to build jboss.

**# python jbossbuild.py [-p parameterfile] jbossPackage**

note: 
* If you don not have an existing parameterfile, you can build everything up in interactive mode, just simply please omit the parameterfile option.
* parameter file is an ini format file, all setting is under section 'main'
* jbossPackage is a supported archive file, like .tar.gz, .zip

