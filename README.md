# atlassian-bitbucket

Atlassian Bitbucket, an enterprise git server and UI, can be managed by bundlewrap with this bundle.
As the software is proprietary and repositories are not available the setup is a bit tricky. You've been warned!

A JMX Port is open on port 5003 by default.
The Jolokia Agent is running by default on port 5005.

## Requirements

* [Oracle JDK](https://gist.github.com/rullmann/e909ec68b66ac711bf441188dbea93c0) installed under `/opt/java/current`
* Atlassian Bitbucket installed under `/opt/bitbucket` with a systemd unit called `atlassian-bitbucket.service`
  * This can be achived by building rpm files: https://github.com/rullmann/atlassian-rpm-specs
* Bundles
  * [systemd](https://github.com/rullmann/bundlewrap-systemd)

## Setup notes

* Install Oracle JDK
* Install Atlassian Bitbucket by using an rpm file
* Assign this bundle to a node and add the required metadata

## Integrations

* Bundles:
  * [telegraf](https://github.com/rullmann/bundlewrap-telegraf)

## Metadata

    'metadata': {
        'atlassian-bitbucket': {
            'proxyname': 'bitbucket.example.org', # required
            'jvm_args': '-XX:+UseG1GC', # optional, add additional JVM parameter
            'jvm_min_mamory': '1024m', # optional
            'jvm_max_mamory': '1024m', # optional
        },
    }
