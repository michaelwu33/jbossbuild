def prints(s, end=True):
    if end:
        print s
    else:
        print s,


def rchown(basedir, uid, gid):
    '''
    Recursive Chown.
    Skip uid or gid if they have value of -1 but can not skip both
    '''

    import os.path
    if (uid == -1 and gid == -1) or not os.path.exists(basedir):
        return
    import subprocess
    if gid == -1:
        cmd = "/usr/bin/chown -Rh {0} {1}".format(uid, basedir)
    elif uid == -1:
        cmd = "/usr/bin/chown -Rh :{0} {1}".format(gid, basedir)
    else:
        cmd = "/usr/bin/chown -Rh {0}:{1} {2}".format(uid, gid, basedir)
    subprocess.call(cmd.split())
    '''
    if os.path.exists(basedir):
        os.chown(basedir, uid, gid)
    for root, dirs, files in os.walk(basedir):
        os.chown(root, uid, gid)
        for d in dirs:
            os.chown(os.path.join(root, d), uid, gid)
        for f in files:
            os.chown(os.path.join(root, f), uid, gid)
    '''


def rchmod(basedir, mode):
    '''
    Recursive Chmod
    '''
    import os.path
    if os.path.exists(basedir):
        import subprocess
        cmd = "/usr/bin/chmod -R {0} {1}".format(mode, basedir)
        subprocess.call(cmd.split())
    '''
    import os
    if os.path.exists(basedir):
        os.chmod(basedir, mode)
    for root, dirs, files in os.walk(basedir):
        for d in dirs:
            os.chmod(os.path.join(root, d), mode)
        for f in files:
            os.chmod(os.path.join(root, f), mode)
    '''
