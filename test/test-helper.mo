import Utils "../src/utils";
import Email "../src/";
import { print } "mo:new-base/Debug";
import { trap } "mo:new-base/Runtime";
import Text "mo:new-base/Text";

module {

  public func parseOk(input : Text, expectedEmail : Text) {
    let parsed = Email.parseOne(input);
    switch (parsed) {
      case (#err(e)) {
        trap("Expected email " # input # " to parse but got " # e);
      };
      case (#ok(e)) {
        let email = e.local # "@" # e.domain;
        if (email != expectedEmail) {
          trap("Expected " # expectedEmail # " but parsed " # email);
        };
      };
    };
  };

  public func parseErr(input : Text, expectedErr : Text) {
    let parsed = Email.parseOne(input);
    switch (parsed) {
      case (#ok(e)) {
        trap("Expected email " # input # " to fail parsing with " # expectedErr # " but it passed: " # debug_show e);
      };
      case (#err(e)) {
        if (not Text.startsWith(e, #text expectedErr)) {
          trap("Expected error " # expectedErr # " but got " # e # " for " # input);
        };
      };
    };
  };

};
