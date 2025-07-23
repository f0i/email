import Text "mo:new-base/Text";
import Iter "mo:new-base/Iter";
import Debug "mo:new-base/Debug";
import Runtime "mo:new-base/Runtime";
module {

  let escapeable = "\"'()";
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
    let iter = Iter.enumerate(input.chars());
    for ((i, c) in iter) {
      // TODO: check for invalid chars
    };
    return true;
  };

  func validateLabel(lbl : Text, isTld : Bool) : Bool {
    if (lbl.size() < 1 or lbl.size() > 63) { return false };
    // TLDs must have at least 2 characters
    if (isTld and lbl.size() < 2) { return false };

    // must not start or end with a hyphen
    if (Text.startsWith(lbl, #char('-')) or Text.endsWith(lbl, #char('-'))) {
      return false;
    };
    //Debug.print(debug_show ("domain label", lbl));

    var isFirst = true;
    var isLetter = false;
    var isDigit = false;

    for (c in lbl.chars()) {
      isLetter := (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z');
      isDigit := (c >= '0' and c <= '9');
      let isHyphen = (c == '-');

      if (isTld) {
        // TLDs can only contain letters
        if (not isLetter) { return false };
      } else if (isFirst) {
        if (not (isLetter or isDigit)) return false;
        isFirst := false;
      } else {
        // other labels can contain letters, digits and hyphens
        if (not (isLetter or isDigit or isHyphen)) {
          return false;
        };
      };
    };
    // last must be digit or letter
    if (not (isLetter or isDigit)) return false;
    return true;
  };

  public func validateDomain(input : Text) : Bool {
    // domain length check
    if (input.size() > 253 or input.size() == 0) { return false };
    //Debug.print(debug_show ("domain", input));

    let labels = Text.split(input, #char('.'));

    // must have at least a TLD and one other label

    let ?first = labels.next() else Runtime.unreachable();
    var last = first;
    var numLabels = 1;
    if (not validateLabel(first, false)) { return false };

    label labelLoop while (true) {
      switch (labels.next()) {
        case (null) { break labelLoop };
        case (?lbl) {
          if (not validateLabel(lbl, false)) { return false };
          numLabels += 1;
          last := lbl;
        };
      };
    };
    // validate TLD
    if (not validateLabel(last, true)) { return false };

    if (numLabels < 2) { return false };

    return true;
  };

};
