import { print } "mo:new-base/Debug";
import { parseOk } "test-helper"

print("valid");
do {
  parseOk("test@asdf.com", "test@asdf.com");
  parseOk("John Doe <john.doe@example.com>", "john.doe@example.com");
  parseOk("\"John Q. Public\" <john@example.com>", "john@example.com");
  parseOk("john+label@example.co.uk", "john+label@example.co.uk");
  //parseOk("user@[192.168.2.1]", "user@[192.168.2.1]");
  parseOk("\"user@host\"@example.com", "\"user@host\"@example.com");
  parseOk("  (comment) jane.doe@example.com  ", "jane.doe@example.com");
  parseOk("John Doe <john.doe(comment)@example.com>", "john.doe@example.com");
  parseOk("\"John \\\"The Man\\\" Doe\" <john@example.com>", "john@example.com");
  parseOk("=?utf-8?Q?J=c3=b6rg?= <joerg@example.com>", "joerg@example.com");
  parseOk("very.common@example.com", "very.common@example.com");
  parseOk("disposable.style.email.with+symbol@example.com", "disposable.style.email.with+symbol@example.com");
  parseOk("user.name+tag+sorting@example.com", "user.name+tag+sorting@example.com");
  parseOk("\"user@domain\"@example.com", "\"user@domain\"@example.com");
  parseOk("x@example.com", "x@example.com");
  parseOk("\"much.more unusual\"@example.com", "\"much.more unusual\"@example.com");
  parseOk("\"very.unusual.@.unusual.com\"@example.com", "\"very.unusual.@.unusual.com\"@example.com");
  parseOk("\"very.(),:;<>[]\\\".VERY.\\\"very@\\ \\\"very\\\".unusual\"@strange.example.com", "\"very.(),:;<>[]\\\".VERY.\\\"very@\\ \\\"very\\\".unusual\"@strange.example.com");
  parseOk("admin@mailserver1", "admin@mailserver1");
  parseOk("\"escaped\\\"quote\" <escape@example.com>", "escape@example.com");
  parseOk("\"back\\\\slash\" <backslash@example.com>", "backslash@example.com");
  parseOk("nested(comment (inside)) <foo@bar.com>", "foo@bar.com");
  //parseOk("name <name@[IPv6:2001:db8::1]>", "name@[IPv6:2001:db8::1]");
};
