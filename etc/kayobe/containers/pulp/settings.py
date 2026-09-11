CONTENT_ORIGIN='{{ pulp_url }}'
ANALYTICS=False
ANSIBLE_API_HOSTNAME='{{ pulp_url }}'
ANSIBLE_CONTENT_HOSTNAME='{{ pulp_url }}/pulp/content'
TOKEN_AUTH_DISABLED=True
ALLOWED_CONTENT_CHECKSUMS = ["sha1", "sha224", "sha256", "sha384", "sha512"]
