svc_systemd = {
    'atlassian-bitbucket': {},
}

files = {
    '/etc/systemd/system/atlassian-bitbucket.service.d/environment.conf': {
        'content_type': 'mako',
        'mode': '0644',
        'source': 'systemd-environment.conf',
        'triggers': ['svc_systemd:atlassian-bitbucket:restart', 'action:systemd-daemon-reload'],
    },
    '/opt/bitbucket/bin/_start-webapp.sh': {
        'content_type': 'mako',
        'mode': '0755',
        'source': '_start-webapp.sh',
        'triggers': ['svc_systemd:atlassian-bitbucket:restart'],
    },
    '/opt/bitbucket/bin/set-jmx-opts.sh': {
        'content_type': 'mako',
        'mode': '0755',
        'source': 'set-jmx-opts.sh',
        'triggers': ['svc_systemd:atlassian-bitbucket:restart'],
    },
    '/opt/bitbucket/jolokia-jvm-agent.jar': {
        'content_type': 'binary',
        'mode': '0644',
        'triggers': ['svc_systemd:atlassian-bitbucket:restart'],
    },
}
