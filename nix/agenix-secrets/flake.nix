{
  description = ''
    A separate store path for agenix-secrets, so that secrets
    consumers need not depend on the entire flake.
  '';
  outputs = { self }: { };
}
