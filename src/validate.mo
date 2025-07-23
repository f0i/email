import Text "mo:new-base/Text";
import Iter "mo:new-base/Iter";
import Debug "mo:new-base/Debug";
module {

  let escapeable = "\"\'()";
  let specialLocal = "!#$%&'*+-/=?^_`{|}~";

  public func isValidLocal(c : Char) : Bool {
    if (c >= 'a' and c <= 'z') return true;
    if (c >= 'A' and c <= 'Z') return true;
    if (c >= '0' and c <= '9') return true;
    if (Text.contains(specialLocal, #char(c))) return true;
    return false;
  };

  // check a string
  public func validateLocal(input : Text) : Bool {
    // special cases
    if (input == "") return false;
    if (input == "\"") return false;

    let iter = Iter.enumerate(input.chars());
    let size = input.size();
    let lastIndex = size - 1 : Nat;
    var quoted = false;
    var escaped = false;

    // must not start or end with a dot
    if (Text.startsWith(input, #char('.'))) return false;
    if (Text.endsWith(input, #char('.'))) return false;
    // must not contain multiple dots unless quoted
    if (not Text.startsWith(input, #char('\"'))) {
      if (Text.contains(input, #text(".."))) return false;
    };

    for ((i, c) in iter) {
      if (i == 0 and c == '\"') {
        quoted := true;
      } else if (c == '\\') {
        return false;
        if (not quoted) return false;
        escaped := true;
      } else if (escaped) {
        // check if the character can be escaped
        if (not Text.contains(escapeable, #char c)) return false;
        escaped := false;
      } else if (c == '\"') {
        // only allowed at the end of quoted string
        return quoted and i == lastIndex;
      } else {
        if (not isValidLocal(c)) return false;
      };
    };

    return not quoted and not escaped;
  };

  public func validateDisplay(input : Text) : Bool {
    Debug.print(debug_show ("validating", input));
    let iter = Iter.enumerate(input.chars());
    for ((i, c) in iter) {
      // TODO: check for invalid chars
    };
    return true;
  };

  public func validateDomain(input : Text) : Bool {
    Debug.print(debug_show ("validating", input));
    let iter = Iter.enumerate(input.chars());
    for ((i, c) in iter) {
      // TODO: check for invalid chars
    };
    return true;
  };

};
