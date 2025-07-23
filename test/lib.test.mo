import Utils "../src/utils";
import Email "../src/";
import { print } "mo:new-base/Debug";
import { trap } "mo:new-base/Runtime";
import Text "mo:new-base/Text";

type Email = Email.Email;

print("blank");
do {
  let iter = Utils.splitOnUnquotedChar("", ',');
  assert iter.next() == ?"";
  assert iter.next() == null;
};

print("single");
do {
  let iter = Utils.splitOnUnquotedChar("a", ',');
  assert iter.next() == ?"a";
  assert iter.next() == null;
};

print("pair");
do {
  let iter = Utils.splitOnUnquotedChar("a,b", ',');
  assert iter.next() == ?"a";
  assert iter.next() == ?"b";
  assert iter.next() == null;
};

print("empty parts");
do {
  let iter = Utils.splitOnUnquotedChar("a,,", ',');
  assert iter.next() == ?"a";
  assert iter.next() == ?"";
  assert iter.next() == ?"";
  assert iter.next() == null;
};

print("email");
do {
  let #ok(e) = Email.parseOne("test@f0i.de");
};

print("comments in local");
do {
  let #ok(e) = Email.parseOne("(some(other))test@f0i.de");
};

do {
  let #ok(e) = Email.parseOne("(some(other with spaces))test@f0i.de");
};

do {
  let #ok(e) = Email.parseOne("asdf (c) (some(other with spaces))<test@f0i.de>");
};

print("invalid local");
do {
  let #err(_) = Email.parseOne("te\\st@f0i.de");
  let #err(_) = Email.parseOne("test\\@f0i.de");
  let #err(_) = Email.parseOne("t]est@f0i.de");
  let #err(_) = Email.parseOne("te..st@f0i.de");
  let #err(_) = Email.parseOne("test.@f0i.de");
  let #err(e) = Email.parseOne(".test@f0i.de");
  assert Text.startsWith(e, #text "Invalid local part");
};

print("domain");
do {
  let #ok(e) = Email.parseOne("a@a.b.c.de");
};

print("full example");
do {
  let #ok(e) = Email.parseOne("(c 1)Display(c 2) Name (c 3)<(c 4)a@(c 5)a.b.c.de(c 6)>(c 7)");
  print(debug_show e);
};
