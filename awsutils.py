import logging
import boto3
def wait_for_instances(instances):
    """
    Wait until the given boto3 instance objects are running
    """
    logging.info("Waiting for instances: {}".format([i.id for i in instances]))
    for i in instances:
        logging.info("Waiting for instance {}".format(i.id))
        i.wait_until_running()
        logging.info("Instance {} running".format(i.id))

    client = boto3.client('ec2')
    waiter = client.get_waiter('instance_status_ok')
    logging.info("Waiting for instances to initialize (status ok): {}".format([i.id for i in instances]))
    waiter.wait(InstanceIds=[i.id for i in instances])
    logging.info("EC2 instances are ready to roll")
    for i in instances:
        i.reload()

def wait_port_open(server, port, timeout=None):
    """ Wait for network service to appear
        @param server: host to connect to (str)
        @param port: port (int)
        @param timeout: in seconds, if None or 0 wait forever
        @return: True of False, if timeout is None may return only True or
                 throw unhandled network exception
    """
    import socket
    import errno
    import time
    sleep_s = 0
    if timeout:
        from time import time as now
        # time module is needed to calc timeout shared between two exceptions
        end = now() + timeout

    while True:
        logging.debug("Sleeping for %s second(s)", sleep_s)
        time.sleep(sleep_s)
        s = socket.socket()
        try:
            if timeout:
                next_timeout = end - now()
                if next_timeout < 0:
                    return False
                else:
                    s.settimeout(next_timeout)

            logging.info("connect %s %d", server, port)
            s.connect((server, port))

        except ConnectionError as err:
            logging.debug("ConnectionError %s", err)
            if sleep_s == 0:
                sleep_s = 1

        except socket.gaierror as err:
            logging.debug("gaierror %s",err)
            return False

        except socket.timeout as err:
            # this exception occurs only if timeout is set
            if timeout:
                return False

        except TimeoutError as err:
            # catch timeout exception from underlying network library
            # this one is different from socket.timeout
            raise

        else:
            s.close()
            logging.info("wait_port_open: port %s:%s is open", server, port)
            return True


