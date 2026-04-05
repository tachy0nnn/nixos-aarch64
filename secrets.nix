let
  userPC = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHdRZp8XNCQwXOSiSpMLEuy7HLGeU1HXk3jck8zi0gtp";
  opi3b = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKe/UcN2tuwafoNq6nwesCXUjvpzwgf1mAkd1XFzu6Pe";
in
{
  "wifi-conn.age".publicKeys = [ userPC opi3b ];
}
