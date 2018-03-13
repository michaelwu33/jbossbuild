#!/bin/env python

import IPy
import socket
import sys


def checkIPs(ip_array):
    result = []
    for ip in ip_array:
        try:
            dummy, version = IPy.parseAddress(ip)
            result.append("IPV" + str(version))
        except Exception:
            result.append("Neither")
    print result


def isIPV4(ip):
    try:
        IPy.parseAddress(ip)
        return True
    except Exception:
        return False


def isIPV6(ip):
    try:
        socket.inet_pton(socket.AF_INET6, ip)
        return True
    except Exception:
        return False


if __name__ == "__main__":
    checkIPs(list(sys.argv[1:]))

    