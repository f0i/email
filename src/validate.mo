import Text "mo:new-base/Text";
import Iter "mo:new-base/Iter";
import Debug "mo:new-base/Debug";
import Runtime "mo:new-base/Runtime";
import { slice } "utils";

module {

  let specialLocal = ".!#$%&'*+-/=?^_`{|}~";

  // text allowed in unquoted string of local part
  public func isValidLocal(c : Char) : Bool {
    if (c >= 'a' and c <= 'z') return true;
    if (c >= 'A' and c <= 'Z') return true;
    if (c >= '0' and c <= '9') return true;
    if (Text.contains(specialLocal, #char(c))) return true;
    return false;
  };

  // text allowed in quoted string of local part
  public func isValidLocalQuoted(c : Char) : Bool {
    if (c == '\"') return false;
    if (c >= ' ' and c <= '~') return true;
    // Debug.print(debug_show ("invalid local quoted", c));
    return false;
  };

  // text that is allowed after \
  public func isEscapeable(c : Char) : Bool {
    if (c == '\t') return true;
    if (c >= ' ' and c <= '~') return true;
    // Debug.print(debug_show ("invalid escaped char", c));
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
        if (not quoted) return false;
        escaped := true;
      } else if (escaped) {
        // check if the character can be escaped
        if (not isEscapeable(c)) return false;
        escaped := false;
      } else if (c == '\"') {
        // only allowed at the end of quoted string
        return quoted and i == lastIndex;
      } else {
        if (quoted) {
          if (not isValidLocalQuoted(c)) return false;
        } else {
          if (not isValidLocal(c)) return false;
        };
      };
    };

    // Chack if quoted string is completed and last one was not an escape char
    if (quoted or escaped) return false;

    return true;
  };

  public func validateDisplay(input : Text) : Bool {
    if (input == "") return true;
    var escaped = false;
    let lastIndex = input.size() - 1 : Nat;

    if (Text.startsWith(input, #char('\"')) and Text.endsWith(input, #char('\"'))) {
      // quoted string
      for ((i, c) in Iter.enumerate(input.chars())) {
        if (escaped) {
          escaped := false;
        } else if (c == '\\') {
          escaped := true;
        } else if (c == '\"' and i != 0 and i != lastIndex) {
          // unescaped quote
          return false;
        };
      };

    } else {
      // atom
      label charLoop for (c in input.chars()) {
        if (c >= 'a' and c <= 'z') continue charLoop;
        if (c >= 'A' and c <= 'Z') continue charLoop;
        if (c >= '0' and c <= '9') continue charLoop;
        if (Text.contains("!#$%&'*+-/=?^_`{|}~ ", #char(c))) continue charLoop;
        return false;
      };
    };

    return (not escaped);
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

  /// Validate a domain name
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
    if (numLabels < 2) {
      // not a FQDN -> no TLD
      return true;
    };

    // validate TLD
    if (not validateLabel(last, true)) { return false };

    return true;
  };

};
