#!/usr/bin/env python

import argparse
import os
import sys
import pwd
import grp
import IPy
import tarfile
import michwu as common
from michwu import prints
import shutil
from datetime import datetime


def cleanup(param):
    prints("Cleaning up ...", end=False)
    try:
        d = param['APP_HOME'] + '/Middleware'
        if os.path.exists(d):
            shutil.rmtree(d)
        # TODO: repo file
    except Exception as e:
        prints(e)
    prints('Done')


def set_parameter_interactive():
    """User to input mandatory setting for JBoss installation.
    Required settings are:
    application home, mso account, run account, and group
    """
    s = "good"
    while s:
        apphome = raw_input('Application Home: ').strip()
        mso = raw_input('MSO Account: ').strip()
        run = raw_input("RUN Account: ").strip()
        group = raw_input("Group: ").strip()
        s = ""
        if not apphome:
            s = s + "Application home must be inputed.\n"
        if not mso:
            s = s + "MSO account must be inputed.\n"
        if not run:
            s = s + "RUN account must be inputed.\n"
        if not group:
            s = s + "Group must be inputed.\n"
        if s:
            prints(s)
            yn = raw_input("Press Q/q to quit, other to re-enter ...")
            if yn.strip().lower() in ("q", "quit"):
                sys.exit(1)
    # save settings to a temporary parameter file
    import tempfile
    with tempfile.NamedTemporaryFile(delete=False) as f:
        s = "[main]\n"
        s = s + "APP_HOME={0}\n".format(apphome)
        s = s + "MSO_USER={0}\n".format(mso)
        s = s + "RUN_USER={0}\n".format(run)
        s = s + "GRP_USER={0}\n".format(group)
        f.write(s)
        return f.name


def validate_parameter(pf):
    import ConfigParser as configparser

    prints("Validating parameters ...", end=False)

    if not (os.path.isfile(pf) and os.access(pf, os.R_OK)):
        prints(
            "File {!s} does not appear to exist or isn't readable.".format(pf))
        return None

    config = configparser.ConfigParser()
    try:
        config.read(pf)
    except Exception as e:
        prints(e)
        prints(
            "Please make sure parameters are set properly in {0}.".format(pf))
        return None

    section = "main"
    if not config.has_section(section):
        prints("Don't find 'main' section in config file {0}.".format(pf))
        return None

    # Mandatory fields
    params = {}  # returning dictionary if all good
    hasError = False
    # App_home
    if config.has_option(section, 'app_home'):
        option = os.path.normpath(config.get(section, 'app_home'))
        if os.path.exists(option + "/Middleware"):
            prints("Middleware directory {0} is already exist, please pick up another application home.".format(option + "/Middleware"))
            hasError = True
        else:
            # APP_HOME, JBOSS_HOME, JAVA_HOME, JBOSS_SCRIPT_DIR, JBOSS_BASE_DIR
            params['APP_HOME'] = option
            params['JBOSS_HOME'] = option + '/Middleware/MiddlewareApp'
            params['JAVA_HOME'] = option + '/Middleware/JAVA'
            params['JBOSS_CUSTOM_SCRIPT_DIR'] = option + '/Middleware/scripts'
            params['JBOSS_SERVER_BASE_DIR'] = option + '/Middleware/MiddlewareApp/standalone'
    else:
        prints("Application home is not defined under section 'main'")
        hasError = True

    ug, um, ur = None, None, None
    # grp_user
    if config.has_option(section, 'grp_user'):
        option = config.get(section, 'grp_user')
        try:
            ug = grp.getgrnam(option)
            params['GRP_USER'] = ug.gr_name
            params['grpid'] = ug.gr_gid
        except KeyError:
            prints("Group '{0}'' does not exist in local group database.".format(option))
            hasError = True
    else:
        prints("Group 'GRP_USER' is not defined under section 'main'")
        hasError = True

    # mso_user
    if config.has_option(section, 'mso_user'):
        option = config.get(section, 'mso_user')
        try:
            um = pwd.getpwnam(option)
            params['MSO_USER'] = um.pw_name
            params['msouid'] = um.pw_uid
        except KeyError:
            prints("User '{0}' does not exist in local account database.".format(option))
            hasError = True
    else:
        prints("Account 'MSO_USER' is not defined under section 'main'")
        hasError = True
    # run_user
    if config.has_option(section, 'run_user'):
        option = config.get(section, 'run_user')
        try:
            ur = pwd.getpwnam(option)
            params['RUN_USER'] = ur.pw_name
            params['runuid'] = ur.pw_uid
            params['runhomedir'] = ur.pw_dir
        except KeyError:
            prints("User '{0}' does not exist in local account database.".format(option))
            hasError = True
    else:
        prints("Account 'RUN_USER' is not defined under section 'main'")
        hasError = True

    # Account must be a member of specified group
    if ug:
        if um:
            if um.pw_gid != ug.gr_gid and um.pw_name not in ug.gr_mem:
                prints("User '{0}' is NOT part of group '{1}'.".format(um.pw_name, ug.gr_name))
                hasError = True
        if ur:
            if ur.pw_gid != ug.gr_gid and ur.pw_name not in ug.gr_mem:
                prints("User '{0}' is NOT part of group '{1}'.".format(ur.pw_name, ug.gr_name))
                hasError = True
    if um and ur and um.pw_name == ur.pw_name:
        prints("Warning: MSO and RUN is set to same.")

    # return if there is error
    if hasError:
        return None

    # Optional
    # jboss_ip_management
    if config.has_option(section, 'JBOSS_IP_MANAGEMENT'):
        try:
            option = config.get(section, 'JBOSS_IP_MANAGEMENT')
            if option != '0':
                IPy.parseAddress(option)
        except Exception as e:
            prints("Warning: JBOSS_IP_MANAGEMENT has invalid IP '{0}', will be set to default 0.".format(option))
            option = '0'
        params['JBOSS_IP_MANAGEMENT'] = option
    else:
        params['JBOSS_IP_MANAGEMENT'] = '0'
    # jboss_ip_public
    if config.has_option(section, 'JBOSS_IP_PUBLIC'):
        try:
            option = config.get(section, 'JBOSS_IP_PUBLIC')
            if option != '0':
                IPy.parseAddress(option)
        except Exception as e:
            prints("Warning: JBOSS_IP_PUBLIC has invalid IP '{0}', will be set to default 0.".format(option))
            option = '0'
        params['JBOSS_IP_PUBLIC'] = option
    else:
        params['JBOSS_IP_PUBLIC'] = '0'
    # jboss_port_offset
    if config.has_option(section, 'JBOSS_PORT_OFFSET'):
        try:
            option = config.getint(section, 'JBOSS_PORT_OFFSET')
            if option < 0 or option > 55545:  # 65535-9990
                raise ValueError("Invalid port offset!")
        except Exception as e:
            prints("Warning: JBOSS_PORT_OFFSET has invalid value '{0}' will be set to default 0.".format(option))
            option = '0'
        params['JBOSS_PORT_OFFSET'] = option
    else:
        params['JBOSS_PORT_OFFSET'] = '0'

    # JBOSS Addtional
    params['JBOSS_USER'] = params['RUN_USER']
    params['JBOSS_MODE'] = 'standalone'

    # JVM
    # jvm xms
    if config.has_option(section, 'JVM_XMS'):
        try:
            option = str(config.get(section, 'JVM_XMS'))
            if option.isdigit():
                if int(option) <= 0:
                    raise ValueError("Invalid memory size!")
            else:
                if option[-1:] not in 'kKmMgG':
                    raise ValueError("Invalid Unit!")
                if not option[:-1].isdigit():
                    raise ValueError("Invalid memory size!")
                if int(option[:-1]) <= 0:
                    raise ValueError("Invalid memory size")
        except Exception as e:
            prints("Warning: Invalid JVM_XMS value '{0}', will be set to default 1300m.".format(option))
            option = '1300m'
        params['JVM_XMS'] = option
    else:
        params['JVM_XMS'] = '1300m'
    # jvm xmx
    if config.has_option(section, 'JVM_XMX'):
        try:
            option = str(config.get(section, 'JVM_XMX'))
            if option.isdigit():
                if int(option) <= 0:
                    raise ValueError("Invalid memory size!")
            else:
                if option[-1:] not in 'kKmMgG':
                    raise ValueError("Invalid Unit!")
                if not option[:-1].isdigit():
                    raise ValueError("Invalid memory size!")
                if int(option[:-1]) <= 0:
                    raise ValueError("Invalid memory size")
        except Exception as e:
            prints("Warning: Invalid JVM_XMX value'{0}', will be set to default 1300m.".format(option))
            option = '1300m'
        params['JVM_XMX'] = option
    else:
        params['JVM_XMX'] = '1300m'
    # TODO
    # xmx >= xms
    # xmx < physical memory
    params['JVM_METASPACESIZE'] = '96m'
    params['JVM_MAXMETASPACESIZE'] = '256m'

    prints("Done")
    return params


def buildJBoss():

    if os.getuid() != 0:
        prints("Build script MUST be run by super user 'root'.")
        sys.exit(1)

    errflag = False

    # Parse arguments passed in
    parser = argparse.ArgumentParser(description="Auto JBoss Installation")
    # Parameter file is optional
    parser.add_argument("-p", "--pFile", help="/path/to/parameterFile")
    parser.add_argument("jFile", help="/path/to/JBossPackage")
    args = parser.parse_args()
    pfile = args.pFile
    jfile = args.jFile

    # Do a simple existence check for parameter file and package file
    if not (os.path.isfile(jfile) and os.access(jfile, os.R_OK)):
        prints("Package file {0} is not found!".format(jfile))
        errflag = True
    else:
        if not tarfile.is_tarfile(jfile):
            prints("{0} is not a supported archive file.".format(jfile))
            errflag = True
    if pfile and (not (os.path.isfile(pfile) and os.access(pfile, os.R_OK))):
        prints("Parameter file {0} is not found!".format(pfile))
        errflag = True
    if errflag:
        sys.exit(1)

    # interactive getting setting if parameter file is not specified
    if not pfile:
        pfile = set_parameter_interactive()
        if not pfile:
            sys.exit(1)

    # validate settings in parameter file, something is wrong
    # if validation returns 'None'
    # Dict 'p' keeps parsed settings
    p = validate_parameter(pfile)
    if p is None:
        sys.exit(1)

    prints("Extracting archive file {0} to application folder {1} ...".format(
        jfile, p['APP_HOME']), end=False)
    try:
        tar = tarfile.open(jfile)
        tar.extractall(p['APP_HOME'])
    except Exception as e:
        prints("\n{!s}\nProgram terminated!!!".format(e))
        cleanup(p)
        sys.exit(1)
    finally:
        tar.close()
    prints("Done.")

    prints("Write settings to environment file ...", end=False)
    try:
        with open(p['JBOSS_CUSTOM_SCRIPT_DIR'] + '/env-jboss.conf', 'w') as f:
            s = 'APP_HOME=' + p['APP_HOME'] + '\n'
            s = s + 'MSO_USER=' + p['MSO_USER'] + '\n'
            s = s + 'RUN_USER=' + p['RUN_USER'] + '\n'
            s = s + 'GRP_USER=' + p['GRP_USER'] + '\n'
            s = s + 'JBOSS_HOME=' + p['JBOSS_HOME'] + '\n'
            s = s + 'JBOSS_USER=' + p['JBOSS_USER'] + '\n'
            s = s + 'JBOSS_MODE=' + p['JBOSS_MODE'] + '\n'
            s = s + 'JBOSS_IP_MANAGEMENT=' + p['JBOSS_IP_MANAGEMENT'] + '\n'
            s = s + 'JBOSS_IP_PUBLIC=' + p['JBOSS_IP_PUBLIC'] + '\n'
            s = s + 'JBOSS_PORT_OFFSET=' + p['JBOSS_PORT_OFFSET'] + '\n'
            s = s + 'JBOSS_CUSTOM_SCRIPT_DIR=' + p['JBOSS_CUSTOM_SCRIPT_DIR'] + '\n'
            s = s + 'JBOSS_SERVER_BASE_DIR=' + p['JBOSS_SERVER_BASE_DIR'] + '\n'
            s = s + 'JAVA_HOME=' + p['JAVA_HOME'] + '\n'
            s = s + 'JVM_XMS=' + p['JVM_XMS'] + '\n'
            s = s + 'JVM_XMX=' + p['JVM_XMX'] + '\n'
            s = s + 'JVM_METASPACESIZE=' + p['JVM_METASPACESIZE'] + '\n'
            s = s + 'JVM_MAXMETASPACESIZE=' + p['JVM_MAXMETASPACESIZE'] + '\n'
            f.write(s)
    except Exception as e:
        prints("\n{!s}\nProgram terminated with above reason!".format(e))
        cleanup(p)
        sys.exit(1)
    prints('Done.')

    prints("Setting ownership and permissions ...", end=False)
    common.rchown(p['APP_HOME'] + '/Middleware', p['msouid'], p['grpid'])
    common.rchown(p['JBOSS_CUSTOM_SCRIPT_DIR'], p['runuid'], -1)
    common.rchown(p['JBOSS_SERVER_BASE_DIR'], p['runuid'], -1)
    common.rchmod(p['JBOSS_CUSTOM_SCRIPT_DIR'], '700')
    prints('Done.')

    prints("Updating user's login profile ... ", end=False)
    bashfile = p['runhomedir'] + '/.bashrc'
    if (os.path.isfile(bashfile) and os.access(bashfile, os.W_OK)) or (
            not os.path.exists(bashfile)):
        try:
            with open(bashfile, 'a') as f:
                s = "\n"
                s = s + "# Added by JBoss installation on " + datetime.now().strftime('%B %d %Y @%H:%M') + "\n"
                s = s + "# Directory which keeps customize JBoss operation scripts\n"
                s = s + "#\n"
                s = s + "export JBOSS_CUSTOM_SCRIPT_DIR=" + p['JBOSS_CUSTOM_SCRIPT_DIR'] + "\n"
                s = s + "export PATH=$JBOSS_CUSTOM_SCRIPT_DIR:$PATH" + "\n"
                f.write(s)
        except Exception as e:
            prints("\n    Warning: {!s}".format(e))
    else:
        prints("\n    Warning: there is something wrong with {0}.".format(bashfile))
    prints("Done.")

    prints("Coping tarfile to repository folder ... ", end=False)
    d = p['APP_HOME'] + '/Repositories'
    try:
        if not os.path.isdir(d):
            # an OSError exception will be raised if there is an
            # existing regular file with same name
            os.mkdir(d)
            os.chown(d, p['msouid'], p['grpid'])
        dstfile = d + '/' + os.path.basename(jfile) + '.' + datetime.now().strftime('%Y%m%d%H%M')
        shutil.copy2(jfile, dstfile)
        # copied repo file to be cleaned up in case failure?
        os.chown(dstfile, p['msouid'], p['grpid'])
        os.chmod(dstfile, 0640)
    except Exception as e:
        prints(e)
    else:
        prints("Done.")

    s = "\n\nCongratulations! JBoss has been installed successfully!\n\n"
    s = s + "Next step please login as user '{0}',".format(p['RUN_USER'])
    s = s + "then run below command to have JBoss instance setup.\n"
    s = s + "\t{0}/jboss-setup.bash\n\n".format(p['JBOSS_CUSTOM_SCRIPT_DIR'])
    s = s + "Once setup is done, you can start or stop JBoss instance by "
    s = s + "running below commands as user '{0}':\n".format(p['RUN_USER'])
    s = s + "\t{0}/start-jboss.sh\n".format(p['JBOSS_CUSTOM_SCRIPT_DIR'])
    s = s + "\t{0}/stop-jboss.sh\n".format(p['JBOSS_CUSTOM_SCRIPT_DIR'])
    prints(s)


if __name__ == "__main__":
    buildJBoss()
