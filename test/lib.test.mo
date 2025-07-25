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
  let #ok(_) = Email.parseOne("a@a.b.c.de");
  let #ok(_) = Email.parseOne("a@a-b.de");
  let #err(_) = Email.parseOne("a@-a.de");
  let #err(_) = Email.parseOne("a@a-.de");
  let #err(_) = Email.parseOne("a@a.b");
  let #err(_) = Email.parseOne("a@a.b-");
  let #err(_) = Email.parseOne("a@a..de");
  let #err(_) = Email.parseOne("a@a.b.c.d");
  let #err(_) = Email.parseOne("a@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.de");
  let #ok(_) = Email.parseOne("a@de"); // not FQDN allowed
  let #err(_) = Email.parseOne("a@.de");
  let #err(_) = Email.parseOne("a@de.");
  let #err(e) = Email.parseOne("a@a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z.a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z.a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z.a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z.a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z.de");

  print(debug_show e);
  assert (Text.startsWith(e, #text "Invalid domain"));
};

print("full example");
do {
  let #ok(e) = Email.parseOne("(c 1)Display(c 2) Name (c 3)<(c 4)a@(c 5)a.b.c.de(c 6)>(c 7)");
  print(debug_show e);
};

print("display name");
do {
  let #ok(_) = Email.parseOne("\"John Q. Public\" <john.q.public@example.com>");
  let #err(_) = Email.parseOne("John\\ Doe <john.doe@example.com>");
  let #err(e) = Email.parseOne("John \"Doe\" <john.doe@example.com>");
  assert (e == "Invalid display name: John \"Doe\"");
};
