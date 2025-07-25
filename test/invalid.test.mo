import { print } "mo:core/Debug";
import { parseErr } "test-helper"

print("valid");
do {
  parseErr("nice\\ name <nice@example.com>", "Invalid display name");
  parseErr("invalid@@email", "Multiple @ symbols");
  parseErr("john..doe@example.com", "Invalid local");
  parseErr(".john@example.com", "Invalid local");
  parseErr("john.@example.com", "Invalid local");
  parseErr("john.doe@example..com", "Invalid domain");
  parseErr("john.doe@.example.com", "Invalid domain");
  parseErr("john.doe@example.com.", "Invalid domain");
  parseErr("john.doe@example_com", "Invalid domain");
  parseErr("john.doe@example..com", "Invalid domain");
  parseErr("john.doe@-example.com", "Invalid domain");
  parseErr("john.doe@example-.com", "Invalid domain");
  parseErr("john.doe@example.com-", "Invalid domain");
  parseErr("john.doe@exa mple.com", "Text after email");
  parseErr("john.doe@exam!ple.com", "Invalid domain");
  parseErr("john.doe@exam#ple.com", "Invalid domain");
  parseErr("john.doe@exa(mple).com", "Invalid domain");
  parseErr("john.doe@", "Invalid domain");
  parseErr("@example.com", "Invalid local");
  parseErr("john.doe", "Missing @");
  parseErr("john.doe@.co # inputm", "Text after email");
  parseErr("john.doe@com.", "Invalid domain");
  parseErr("john.doe@.com.", "Invalid domain");
  parseErr("john.doe@example..com", "Invalid domain");
  parseErr("\"john\"doe@example.com", "Invalid local");
  parseErr("john.doe@exa\\mple.com", "Invalid domain");
  parseErr("john.doe@exam\nple.com", "Text after email");
  parseErr("john.doe@example.c_m", "Invalid domain");
  parseErr("john.doe@example..com", "Invalid domain");
  parseErr("john..doe@example.com", "Invalid local");
  parseErr("\"john\\doe@example.com", "Missing @");
  parseErr("john.doe@-example.com", "Invalid domain");
  parseErr("john.doe@example-.com", "Invalid domain");
};
